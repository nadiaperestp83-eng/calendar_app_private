import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Representa um único resultado retornado pela API pública do Pixabay.
///
/// Só expõe os campos que o `HeroCardImageFallback` realmente usa —
/// veja a documentação completa em https://pixabay.com/api/docs/ se
/// precisar de mais metadados (likes, views, tipo de licença etc).
class PixabayImage {
  const PixabayImage({
    required this.id,
    required this.previewUrl,
    required this.webformatUrl,
    required this.largeImageUrl,
    required this.tags,
    required this.user,
    required this.pageUrl,
  });

  final int id;

  /// Thumbnail pequeno (~150px) — útil para um placeholder rápido
  /// enquanto o `webformatUrl`/`largeImageUrl` ainda baixa.
  final String previewUrl;

  /// Versão web (até 640px de largura) — a que usamos por padrão no
  /// Hero Card, já que o card tem só 220px de altura e baixar a
  /// `largeImageUrl` (até 1920px) seria desperdício de banda.
  final String webformatUrl;

  /// Versão grande (até 1920px) — use se o card crescer ou em telas
  /// de detalhe/tablet.
  final String largeImageUrl;

  final String tags;

  /// Nome do autor no Pixabay — a licença do Pixabay não exige
  /// atribuição, mas é uma boa prática exibir/creditar quando possível.
  final String user;

  /// Link da página da imagem no Pixabay (para créditos, se você
  /// decidir exibi-los na UI).
  final String pageUrl;

  factory PixabayImage.fromJson(Map<String, dynamic> json) {
    return PixabayImage(
      id: json['id'] as int,
      previewUrl: json['previewURL'] as String,
      webformatUrl: json['webformatURL'] as String,
      largeImageUrl: json['largeImageURL'] as String,
      tags: json['tags'] as String? ?? '',
      user: json['user'] as String? ?? '',
      pageUrl: json['pageURL'] as String? ?? '',
    );
  }
}

/// Erros específicos do serviço, para o widget de UI decidir o que
/// fazer sem precisar inspecionar tipos de exceção do `http`/`dart:io`.
enum PixabayErrorType { semApiKey, semConexao, timeout, respostaInvalida, semResultados }

class PixabayException implements Exception {
  const PixabayException(this.type, [this.message]);
  final PixabayErrorType type;
  final String? message;

  @override
  String toString() => 'PixabayException(${type.name}${message != null ? ': $message' : ''})';
}

/// Cliente simples para a Pixabay Image Search API.
///
/// USO:
/// ```dart
/// final imagens = await PixabayService.search('mountain landscape minimalist');
/// ```
///
/// CONFIGURAÇÃO DA API KEY:
/// Crie uma conta gratuita em https://pixabay.com/api/docs/ e gere sua
/// chave. NÃO hardcode a chave no código-fonte (evite versionar sua
/// key no Git). Passe-a em tempo de build:
///
/// ```
/// flutter run --dart-define=PIXABAY_API_KEY=SEU_TOKEN_AQUI
/// ```
///
/// Se preferir, troque `_apiKey` por leitura de um `.env`/secure
/// storage — o importante é nunca commitar a chave real.
class PixabayService {
  PixabayService._();

  static const String _apiKey = String.fromEnvironment('PIXABAY_API_KEY');
  static const String _baseUrl = 'https://pixabay.com/api/';
  static const Duration _timeout = Duration(seconds: 8);

  /// Cache simples em memória por processo — evita repetir a mesma
  /// busca (ex: reabrir o app várias vezes no mesmo dia, já que a
  /// query é determinística por `LandscapeParams`). Não persiste em
  /// disco de propósito: isso reintroduziria uma camada de I/O extra
  /// num app que era, até então, 100% offline.
  static final Map<String, List<PixabayImage>> _cache = {};

  /// Busca imagens no Pixabay que combinem com [query].
  ///
  /// [safesearch] fica `true` por padrão (recomendado sempre).
  /// [orientation] em 'horizontal' por padrão — o Hero Card é bem
  /// mais largo que alto (220px de altura, largura da tela toda).
  /// [category] pode restringir a busca (ex: 'nature', 'places') para
  /// reduzir a chance de resultados fora do estilo minimalista
  /// desejado; deixe `null` para não filtrar.
  ///
  /// Lança [PixabayException] em qualquer falha — nunca retorna uma
  /// lista "quebrada" nem deixa uma exceção genérica escapar, para que
  /// o widget de fallback saiba exatamente por que falhou.
  static Future<List<PixabayImage>> search(
    String query, {
    int perPage = 20,
    String orientation = 'horizontal',
    String? category,
    bool safesearch = true,
    bool editorsChoice = false,
  }) async {
    if (_apiKey.isEmpty) {
      throw const PixabayException(
        PixabayErrorType.semApiKey,
        'Rode o app com --dart-define=PIXABAY_API_KEY=SEU_TOKEN',
      );
    }

    final cacheKey = '$query|$perPage|$orientation|$category|$safesearch';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final params = <String, String>{
      'key': _apiKey,
      'q': query,
      'image_type': 'photo',
      'orientation': orientation,
      'per_page': perPage.clamp(3, 200).toString(),
      'safesearch': safesearch.toString(),
      'editors_choice': editorsChoice.toString(),
      // Pixabay não licencia conteúdo com direitos autorais de
      // terceiros: tudo no catálogo é livre para uso comercial/pessoal
      // sem atribuição obrigatória (https://pixabay.com/service/license/).
      if (category != null) 'category': category,
    };

    final uri = Uri.parse(_baseUrl).replace(queryParameters: params);

    late final http.Response response;
    try {
      response = await http.get(uri).timeout(_timeout);
    } on TimeoutException {
      throw const PixabayException(PixabayErrorType.timeout);
    } catch (e) {
      // Cobre SocketException (sem internet/DNS), erro de TLS, etc.
      // sem depender de dart:io diretamente aqui.
      throw PixabayException(PixabayErrorType.semConexao, e.toString());
    }

    if (response.statusCode != 200) {
      throw PixabayException(
        PixabayErrorType.respostaInvalida,
        'HTTP ${response.statusCode}: ${response.body}',
      );
    }

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw PixabayException(PixabayErrorType.respostaInvalida, e.toString());
    }

    final hits = (decoded['hits'] as List<dynamic>? ?? [])
        .map((e) => PixabayImage.fromJson(e as Map<String, dynamic>))
        .toList();

    if (hits.isEmpty) {
      throw const PixabayException(PixabayErrorType.semResultados);
    }

    _cache[cacheKey] = hits;
    return hits;
  }

  /// Atalho: busca e devolve só a primeira imagem (a mais relevante
  /// segundo o ranking do Pixabay), já pensando no caso de uso do
  /// Hero Card, onde só precisamos de UMA imagem de fallback.
  static Future<PixabayImage> searchFirst(
    String query, {
    String orientation = 'horizontal',
    String? category,
  }) async {
    final results = await search(
      query,
      perPage: 3,
      orientation: orientation,
      category: category,
    );
    return results.first;
  }

  /// Limpa o cache em memória (útil em testes ou se quiser forçar uma
  /// nova busca, ex: botão de "trocar paisagem" na UI).
  static void clearCache() => _cache.clear();
}
