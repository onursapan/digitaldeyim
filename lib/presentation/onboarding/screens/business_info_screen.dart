import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_router.dart';
import '../../../domain/entities/user_profile.dart';
import '../providers/onboarding_provider.dart';

class BusinessInfoScreen extends ConsumerStatefulWidget {
  const BusinessInfoScreen({super.key});

  @override
  ConsumerState<BusinessInfoScreen> createState() => _BusinessInfoScreenState();
}

class _BusinessInfoScreenState extends ConsumerState<BusinessInfoScreen> {
  final _nameController = TextEditingController();
  final _productController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // A6 FIX: Back-navigation'da TextField'ı provider state'iyle senkronize et.
    // Controller write-only bağlantısı (onChanged) state'i günceller ama
    // geri gelindiğinde controller'ı seed etmez; postFrameCallback ile düzeltiyoruz.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final saved = ref.read(onboardingProvider).businessName;
      if (saved != null && saved.isNotEmpty && _nameController.text != saved) {
        _nameController.text = saved;
        _nameController.selection = TextSelection.fromPosition(
          TextPosition(offset: saved.length),
        );
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _productController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('İşletmeni Tanı'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepIndicator(
              labels: const ['Sektör', 'Bilgiler', 'Ses', 'Hazır'],
              currentIndex: 1,
            ),
            const SizedBox(height: 32),

            // İşletme adı
            Text('İşletme Adın', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              onChanged: notifier.setBusinessName,
              decoration: const InputDecoration(
                hintText: 'Örn: Ayşe Gelinlik Evi',
              ),
            ),
            const SizedBox(height: 28),

            // En çok satan ürünler
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('En Çok Satan 3 Ürün', style: theme.textTheme.titleLarge),
                Text(
                  '${state.topProducts.length}/3',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFC9A96E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _productController,
                    decoration: const InputDecoration(
                      hintText: 'Ürün adı yaz',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  onPressed: state.topProducts.length < 3
                      ? () {
                          if (_productController.text.isNotEmpty) {
                            notifier.addProduct(_productController.text);
                            _productController.clear();
                          }
                        }
                      : null,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFC9A96E),
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.topProducts
                  .map((product) => Chip(
                        label: Text(product),
                        onDeleted: () => notifier.removeProduct(product),
                        deleteIconColor: Colors.white54,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 28),

            // Mağaza karakteri
            Text('Dükkanın Karakteri', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            ...BusinessVibe.values.map((vibe) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SelectableOption(
                    label: vibe.label,
                    isSelected: state.vibe == vibe,
                    onTap: () => notifier.setVibe(vibe),
                  ),
                )),
            const SizedBox(height: 28),

            // Hedef kitle
            Text('Müşterilerin Kimler?', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            ...TargetAudience.values.map((audience) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SelectableOption(
                    label: audience.label,
                    isSelected: state.audience == audience,
                    onTap: () => notifier.setAudience(audience),
                  ),
                )),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: state.vibe != null &&
                      state.audience != null &&
                      state.businessName != null &&
                      state.topProducts.isNotEmpty
                  ? () => context.push(AppRoutes.voiceRecording)
                  : null,
              child: const Text('Sonraki Adım'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final List<String> labels;
  final int currentIndex;

  const _StepIndicator({required this.labels, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: labels.asMap().entries.map((entry) {
        final i = entry.key;
        final label = entry.value;
        final isDone = i < currentIndex;
        final isCurrent = i == currentIndex;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (i > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isDone
                            ? const Color(0xFFC9A96E)
                            : const Color(0xFF2A2A2A),
                      ),
                    ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCurrent || isDone
                          ? const Color(0xFFC9A96E)
                          : const Color(0xFF2A2A2A),
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check, size: 14, color: Colors.black)
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color:
                                    isCurrent ? Colors.black : Colors.white38,
                              ),
                            ),
                    ),
                  ),
                  if (i < labels.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isDone
                            ? const Color(0xFFC9A96E)
                            : const Color(0xFF2A2A2A),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isCurrent
                      ? const Color(0xFFC9A96E)
                      : Colors.white38,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SelectableOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectableOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFC9A96E)
                : const Color(0xFF2A2A2A),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFFC9A96E) : Colors.white70,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: Color(0xFFC9A96E), size: 18),
          ],
        ),
      ),
    );
  }
}
