import 'dart:async';
import '../utils/logger.dart';
import 'base_agent.dart';

/// Merkezi Koordinatör — tüm ajan event'lerini yönetir.
/// Bir ajanın output'unu diğerinin input'una bağlar.
class Orchestrator {
  final _eventBus = StreamController<OrchestratorEvent>.broadcast();
  final Map<String, BaseAgent> _agents = {};
  final List<StreamSubscription> _subscriptions = [];

  Stream<OrchestratorEvent> get events => _eventBus.stream;

  void registerAgent(BaseAgent agent) {
    _agents[agent.agentName] = agent;
    final sub = agent.stateStream.listen((state) {
      _eventBus.add(OrchestratorEvent(
        agentName: agent.agentName,
        state: state,
      ));
      appLogger.d('[Orchestrator] ${agent.agentName} -> ${state.type.name}');
    });
    _subscriptions.add(sub);
    appLogger.d('[Orchestrator] Registered agent: ${agent.agentName}');
  }

  void emit(OrchestratorEvent event) => _eventBus.add(event);

  /// İki ajanı sıralı zincirir: agentA output'u → agentB input'u.
  /// Her ajan tamamlandığında Orchestrator event bus'ına bildirim yayar.
  /// Faz 1'de StudioNotifier bunu kullanmaz; Faz 2 için plug-in noktası.
  Future<B> chain<A, B>(
    BaseAgent<dynamic, A> agentA,
    dynamic inputA,
    BaseAgent<A, B> agentB,
  ) async {
    final outputA = await agentA.process(inputA);
    emit(OrchestratorEvent(
      agentName: agentA.agentName,
      state: AgentState.success(outputA),
      payload: outputA,
    ));
    final outputB = await agentB.process(outputA);
    emit(OrchestratorEvent(
      agentName: agentB.agentName,
      state: AgentState.success(outputB),
      payload: outputB,
    ));
    return outputB;
  }

  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    for (final agent in _agents.values) {
      agent.dispose();
    }
    _eventBus.close();
  }
}

class OrchestratorEvent {
  final String agentName;
  final AgentState state;
  final dynamic payload;

  const OrchestratorEvent({
    required this.agentName,
    required this.state,
    this.payload,
  });
}
