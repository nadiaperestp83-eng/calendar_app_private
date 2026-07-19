import 'package:isar/isar.dart';

part 'evento.g.dart';

/// Modelo de dados local do Evento.
/// 100% offline — nenhum campo aqui é sincronizado com rede.
@collection
class Evento {
  Id id = Isar.autoIncrement;

  late String titulo;

  String? descricao;

  late DateTime dataHoraInicio;

  DateTime? dataHoraFim;

  /// Guardamos só a data (sem hora) normalizada, indexada,
  /// para permitir buscas rápidas "todos os eventos do dia X".
  @Index()
  late DateTime diaReferencia;

  String? local;

  /// Cor do card em glassmorphism (opcional, armazenada como valor ARGB int)
  int? corTint;

  bool notificar = true;

  Evento();

  Evento.novo({
    required this.titulo,
    required this.dataHoraInicio,
    this.descricao,
    this.dataHoraFim,
    this.local,
    this.corTint,
    this.notificar = true,
  }) {
    diaReferencia = _normalizarData(dataHoraInicio);
  }

  static DateTime _normalizarData(DateTime data) {
    return DateTime(data.year, data.month, data.day);
  }
}
