import 'dart:async';
import '../utils/logger.dart';

/// Tüm ajanların temel sözleşmesi.
/// Her ajan bir input alır, işler ve output üretir.
abstract class BaseAgent<Input, Output> {
  String get agentName;

  /// Ajanın ana işlem metodu.
  Future<Output> process(Input input);

  /// Orchestrator'ın dinleyebileceği state stream'i.
  final StreamController<AgentState> _stateController =
      StreamController.broadcast();

  Stream<AgentState> get stateStream => _stateController.stream;

  void _emit(AgentState state) {
    appLogger.d('[$agentName] State: $state');
    _stateController.add(state);
  }

  void emitProcessing() => _emit(AgentState.processing);
  void emitSuccess() => _emit(AgentState.success);
  void emitFailure(String reason) => _emit(AgentState.failure(reason));
  void emitIdle() => _emit(AgentState.idle);

  void dispose() => _stateController.close();
}

class AgentState {
  final AgentStateType type;
  final String? message;

  const AgentState._(this.type, [this.message]);

  static const AgentState idle = AgentState._(AgentStateType.idle);
  static const AgentState processing = AgentState._(AgentStateType.processing);
  static const AgentState success = AgentState._(AgentStateType.success);
  static AgentState failure(String msg) =>
      AgentState._(AgentStateType.failure, msg);

  bool get isProcessing => type == AgentStateType.processing;
  bool get isSuccess => type == AgentStateType.success;
  bool get isFailure => type == AgentStateType.failure;
}

enum AgentStateType { idle, processing, success, failure }
