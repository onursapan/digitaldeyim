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
