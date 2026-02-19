import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../agents/orchestrator.dart';
import '../agents/validator_agent.dart';
import '../agents/prompter_agent.dart';
import '../../data/datasources/sector_local_datasource.dart';
import '../../data/repositories/gemini_service.dart';
import '../../data/repositories/shotstack_service.dart';

// Services
final geminiServiceProvider = Provider<GeminiService>((_) => GeminiService());
final shotstackServiceProvider =
    Provider<ShotstackService>((_) => ShotstackService());
final sectorDatasourceProvider =
    Provider<SectorLocalDatasource>((_) => SectorLocalDatasource());

// Agents
final validatorAgentProvider = Provider<ValidatorAgent>((_) => ValidatorAgent());
final prompterAgentProvider = Provider<PrompterAgent>((_) => PrompterAgent());

// Orchestrator — tüm ajanları tek noktada yönetir
final orchestratorProvider = Provider<Orchestrator>((ref) {
  final orchestrator = Orchestrator();
  orchestrator.registerAgent(ref.read(validatorAgentProvider));
  orchestrator.registerAgent(ref.read(prompterAgentProvider));
  ref.onDispose(orchestrator.dispose);
  return orchestrator;
});
