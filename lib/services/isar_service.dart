import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/evento.dart';
import '../utils/services/notification_service.dart';

/// Quantos minutos antes do evento a notificação dispara, quando o
/// evento não tem um horário de lembrete próprio configurado. 30 min é
/// o padrão mais comum em apps de calendário (Google Calendar, etc).
const int _kLembreteMinutosPadrao = 30;

/// Serviço responsável por todo o acesso ao banco Isar local.
///
/// Regra de privacidade do projeto: NENHUM método aqui deve fazer
/// chamadas de rede, Firebase, analytics ou telemetria. Tudo fica
/// no dispositivo, dentro do diretório de documentos do app.
class IsarService {
  IsarService._internal();
  static final IsarService instance = IsarService._internal();

  Isar? _isar;

  /// Abre (ou reaproveita) a instância do Isar.
  Future<Isar> get db async {
    if (_isar != null && _isar!.isOpen) {
      return _isar!;
    }
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [EventoSchema],
      directory: dir.path,
      // inspector desligado em produção evita exposição local dos dados
      inspector: false,
    );
    return _isar!;
  }

  // ---------------------------------------------------------------------
  // CREATE / UPDATE
  // ---------------------------------------------------------------------

  /// Adiciona (ou atualiza, se já tiver id) um evento.
  /// Retorna o id gerado/atualizado.
  Future<int> add(Evento evento) async {
    final isar = await db;
    late int id;
    await isar.writeTxn(() async {
      id = await isar.eventos.put(evento);
    });

    // Agenda (ou reagenda, se for edição — o plugin substitui qualquer
    // notificação pendente com o mesmo id) o lembrete via alarme nativo
    // do Android. Se o usuário desligou "notificar" neste evento (ou
    // editou um evento que tinha notificação ligada e desligou),
    // cancela qualquer lembrete que já estivesse marcado pra ele.
    if (evento.notificar) {
      await NotificationService.i.scheduleNotification(
        eventId: id.toString(),
        eventName: evento.titulo,
        startsAt: evento.dataHoraInicio,
        remindAt: _kLembreteMinutosPadrao,
      );
    } else {
      await NotificationService.i.cancelNotification(eventId: id.toString());
    }

    return id;
  }

  /// Alias semântico de [add], usado pelas telas de formulário
  /// (ex.: NovaConsultaScreen) para deixar explícito que a ação
  /// é "salvar o evento que o usuário acabou de preencher".
  Future<int> salvarEvento(Evento evento) => add(evento);

  // ---------------------------------------------------------------------
  // DELETE
  // ---------------------------------------------------------------------

  /// Remove um evento pelo id. Retorna true se algo foi deletado.
  Future<bool> delete(int id) async {
    final isar = await db;
    late bool removido;
    await isar.writeTxn(() async {
      removido = await isar.eventos.delete(id);
    });

    if (removido) {
      await NotificationService.i.cancelNotification(eventId: id.toString());
    }

    return removido;
  }

  // ---------------------------------------------------------------------
  // READ
  // ---------------------------------------------------------------------

  /// Retorna todos os eventos de um dia específico, ordenados por horário.
  Future<List<Evento>> getByDate(DateTime data) async {
    final isar = await db;
    final diaNormalizado = DateTime(data.year, data.month, data.day);

    return isar.eventos
        .filter()
        .diaReferenciaEqualTo(diaNormalizado)
        .sortByDataHoraInicio()
        .findAll();
  }

  /// Stream reativo dos eventos do dia — útil para o ListView
  /// atualizar automaticamente quando algo muda no banco.
  Stream<List<Evento>> watchByDate(DateTime data) async* {
    final isar = await db;
    final diaNormalizado = DateTime(data.year, data.month, data.day);

    yield* isar.eventos
        .filter()
        .diaReferenciaEqualTo(diaNormalizado)
        .sortByDataHoraInicio()
        .watch(fireImmediately: true);
  }

  /// Retorna o conjunto de dias (normalizados) que possuem pelo menos
  /// um evento — útil para marcar pontinhos no seletor de mês.
  Future<Set<DateTime>> getDiasComEventos(DateTime mesReferencia) async {
    final isar = await db;
    final inicioMes = DateTime(mesReferencia.year, mesReferencia.month, 1);
    final inicioProxMes =
        DateTime(mesReferencia.year, mesReferencia.month + 1, 1);

    final eventos = await isar.eventos
        .filter()
        .diaReferenciaGreaterThan(
          inicioMes.subtract(const Duration(days: 1)),
        )
        .diaReferenciaLessThan(inicioProxMes)
        .findAll();

    return eventos.map((e) => e.diaReferencia).toSet();
  }

  Future<void> close() async {
    if (_isar != null && _isar!.isOpen) {
      await _isar!.close();
    }
  }
}
