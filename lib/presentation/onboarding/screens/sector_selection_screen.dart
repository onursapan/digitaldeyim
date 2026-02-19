import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_router.dart';
import '../../../domain/entities/sector.dart';
import '../providers/onboarding_provider.dart';

class SectorSelectionScreen extends ConsumerWidget {
  const SectorSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'Merhaba! 👋',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFC9A96E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ne satıyorsun?',
                style: theme.textTheme.displayLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Sektörüne özel AI yönetmen seni bekliyor.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 40),
              if (state.isLoadingSectors)
                const Center(child: CircularProgressIndicator())
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: state.availableSectors.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final sector = state.availableSectors[index];
                      return _SectorCard(
                        sector: sector,
                        isSelected: state.selectedSectorId == sector.id,
                        onTap: () {
                          ref
                              .read(onboardingProvider.notifier)
                              .selectSector(sector.id);
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: state.selectedSectorId != null
                    ? () => context.push(AppRoutes.businessInfo)
                    : null,
                child: const Text('Devam Et'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectorCard extends StatelessWidget {
  final Sector sector;
  final bool isSelected;
  final VoidCallback onTap;

  const _SectorCard({
    required this.sector,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFC9A96E)
                : const Color(0xFF2A2A2A),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(sector.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                sector.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: isSelected
                          ? const Color(0xFFC9A96E)
                          : Colors.white,
                    ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFFC9A96E),
              ),
          ],
        ),
      ),
    );
  }
}
