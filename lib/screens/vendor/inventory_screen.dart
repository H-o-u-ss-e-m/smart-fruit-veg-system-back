// lib/screens/vendor/inventory_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_text_field.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(filteredProductsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCat = ref.watch(selectedCategoryProvider);
    final selectedQual = ref.watch(selectedQualityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventaire'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: 'Rechercher un produit...',
                prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textHint),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () {
                    _searchCtrl.clear();
                    ref.read(searchQueryProvider.notifier).state = '';
                  },
                )
                    : null,
              ),
            ),
          ),

          // Filtres actifs
          if (selectedCat != null || selectedQual != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  if (selectedCat != null)
                    _FilterChip(
                      label: selectedCat,
                      onRemove: () => ref.read(selectedCategoryProvider.notifier).state = null,
                    ),
                  if (selectedQual != null)
                    _FilterChip(
                      label: selectedQual,
                      onRemove: () => ref.read(selectedQualityProvider.notifier).state = null,
                    ),
                ],
              ),
            ),

          // Liste produits
          Expanded(
            child: filteredAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('📦', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 12),
                        Text('Aucun produit trouvé'),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (ctx, i) => _InventoryCard(product: products[i]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorCard(message: e.toString()),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filtres', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 20),
                Text('Catégorie', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Toutes'),
                      selected: ref.watch(selectedCategoryProvider) == null,
                      onSelected: (_) => ref.read(selectedCategoryProvider.notifier).state = null,
                    ),
                    ...categories.map((cat) => FilterChip(
                      label: Text(cat),
                      selected: ref.watch(selectedCategoryProvider) == cat,
                      onSelected: (_) => ref.read(selectedCategoryProvider.notifier).state = cat,
                    )),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Qualité', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Toutes'),
                      selected: ref.watch(selectedQualityProvider) == null,
                      onSelected: (_) => ref.read(selectedQualityProvider.notifier).state = null,
                    ),
                    ...QualityStatus.values.map((q) => FilterChip(
                      label: Text(q.label),
                      selected: ref.watch(selectedQualityProvider) == q.name,
                      onSelected: (_) => ref.read(selectedQualityProvider.notifier).state = q.name,
                    )),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14, color: AppTheme.primary),
          ),
        ],
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final ProductModel product;
  const _InventoryCard({required this.product});

  String _emoji(String cat) {
    const map = {
      'pommes': '🍎', 'tomates': '🍅', 'bananes': '🍌',
      'oranges': '🍊', 'citrons': '🍋', 'carottes': '🥕',
    };
    return map[cat.toLowerCase()] ?? '🫐';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: product.isExpired
              ? AppTheme.qualityBad.withOpacity(0.3)
              : product.isExpiringSoon
              ? AppTheme.qualityMedium.withOpacity(0.3)
              : AppTheme.divider,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(_emoji(product.category), style: const TextStyle(fontSize: 26))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(product.name, style: Theme.of(context).textTheme.titleLarge)),
                        QualityBadge(quality: product.quality.label),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.quantity} unités · ${product.category}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Fraîcheur', style: Theme.of(context).textTheme.bodySmall),
                        Text(
                          product.isExpired
                              ? 'Expiré'
                              : '${product.daysRemaining}j restants',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: product.isExpired
                                ? AppTheme.qualityBad
                                : product.isExpiringSoon
                                ? AppTheme.qualityMedium
                                : AppTheme.qualityGood,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    FreshnessBar(percent: product.freshnessPercent),
                  ],
                ),
              ),
              if (product.price != null) ...[
                const SizedBox(width: 16),
                Text(
                  '${product.price!.toStringAsFixed(2)} DT',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}