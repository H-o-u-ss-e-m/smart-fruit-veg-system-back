import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/router.dart';
import '../../widgets/app_text_field.dart';

// ═══════════════════════════════════════════════════════════════════
// CLIENT MAIN SCREEN
// ═══════════════════════════════════════════════════════════════════
class ClientMainScreen extends ConsumerWidget {
  final Widget child;
  const ClientMainScreen({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith(AppRoutes.catalogue)) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int currentIndex = 0;
    try {
      final location = GoRouterState.of(context).matchedLocation;
      currentIndex = _locationToIndex(location);
    } catch (_) {}

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceCard,
          border: Border(top: BorderSide(color: AppTheme.divider)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (i) {
            switch (i) {
              case 0: context.go(AppRoutes.clientMain);
              case 1: context.go(AppRoutes.catalogue);
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront),
              label: 'Catalogue',
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// CLIENT DASHBOARD SCREEN
// ═══════════════════════════════════════════════════════════════════
class ClientDashboardScreen extends ConsumerWidget {
  const ClientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour, ${user?.name.split(' ').first ?? ''} 👋',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              'Produits frais disponibles',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _showLogoutDialog(context, ref),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0x1AFF6B35),
                child: Text(
                  user?.name.substring(0, 1).toUpperCase() ?? 'C',
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(productsProvider),
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FreshnessBanner(),
              const SizedBox(height: 20),
              const SectionHeader(title: 'Catégories'),
              const SizedBox(height: 12),
              productsAsync.when(
                data: (products) {
                  final cats =
                  products.map((p) => p.category).toSet().toList();
                  return SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: cats.length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(width: 10),
                      itemBuilder: (ctx, i) =>
                          _CategoryChip(category: cats[i]),
                    ),
                  );
                },
                loading: () => SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 4,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, __) => const LoadingCard(),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),
              SectionHeader(
                title: 'Disponible maintenant',
                actionLabel: 'Voir tout',
                onAction: () => context.go(AppRoutes.catalogue),
              ),
              const SizedBox(height: 12),
              productsAsync.when(
                data: (products) {
                  final available = products
                      .where((p) =>
                  p.quality != QualityStatus.mauvais &&
                      !p.isExpired)
                      .take(6)
                      .toList();
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: available.length,
                    itemBuilder: (ctx, i) =>
                        _ClientProductCard(product: available[i]),
                  );
                },
                loading: () => GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: List.generate(
                      4, (_) => const LoadingCard(height: 180)),
                ),
                error: (e, _) => ErrorCard(message: e.toString()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Déconnexion'),
        content:
        const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
            child: const Text('Déconnecter',
                style: TextStyle(color: AppTheme.qualityBad)),
          ),
        ],
      ),
    );
  }
}

// ── Bannière ──────────────────────────────────────────────────────────
class _FreshnessBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.accent, AppTheme.accentLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Produits frais',
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Qualité en temps réel',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13),
                ),
              ],
            ),
          ),
          const Text('🛒', style: TextStyle(fontSize: 44)),
        ],
      ),
    );
  }
}

// ── Chip catégorie ────────────────────────────────────────────────────
class _CategoryChip extends StatelessWidget {
  final String category;
  const _CategoryChip({required this.category});

  String _emoji(String cat) {
    const map = {
      'pommes': '🍎', 'tomates': '🍅', 'bananes': '🍌',
      'oranges': '🍊', 'citrons': '🍋', 'carottes': '🥕',
      'raisin': '🍇', 'fraises': '🍓', 'laitue': '🥬',
    };
    return map[cat.toLowerCase()] ?? '🫐';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_emoji(category), style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            category,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Carte produit client ──────────────────────────────────────────────
class _ClientProductCard extends StatelessWidget {
  final ProductModel product;
  const _ClientProductCard({required this.product});

  String _emoji(String cat) {
    const map = {
      'pommes': '🍎', 'tomates': '🍅', 'bananes': '🍌',
      'oranges': '🍊', 'citrons': '🍋', 'carottes': '🥕',
      'raisin': '🍇', 'fraises': '🍓', 'laitue': '🥬',
    };
    return map[cat.toLowerCase()] ?? '🫐';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0x0F2D6A4F),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                _emoji(product.category),
                style: const TextStyle(fontSize: 30),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${product.quantity} u.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              QualityBadge(quality: product.quality.label),
            ],
          ),
          const SizedBox(height: 6),
          FreshnessBar(percent: product.freshnessPercent),
          const SizedBox(height: 4),
          Text(
            product.isExpiringSoon
                ? '⚠️ Bientôt'
                : '✅ ${product.daysRemaining}j',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: product.isExpiringSoon
                  ? AppTheme.qualityMedium
                  : AppTheme.qualityGood,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
          if (product.price != null) ...[
            const SizedBox(height: 3),
            Text(
              '${product.price!.toStringAsFixed(2)} DT',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.accent,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// CATALOGUE SCREEN
// ═══════════════════════════════════════════════════════════════════
class CatalogueScreen extends ConsumerWidget {
  const CatalogueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredProductsProvider);
    final selectedCat = ref.watch(selectedCategoryProvider);
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Catalogue')),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _CatFilterPill(
                  label: 'Tous',
                  isSelected: selectedCat == null,
                  onTap: () => ref
                      .read(selectedCategoryProvider.notifier)
                      .state = null,
                ),
                ...categories.map((cat) => _CatFilterPill(
                  label: cat,
                  isSelected: selectedCat == cat,
                  onTap: () => ref
                      .read(selectedCategoryProvider.notifier)
                      .state = cat,
                )),
              ],
            ),
          ),
          Expanded(
            child: filteredAsync.when(
              data: (products) {
                final available =
                products.where((p) => !p.isExpired).toList();
                if (available.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('📦', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 12),
                        Text('Aucun produit disponible'),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: available.length,
                  itemBuilder: (ctx, i) =>
                      _ClientProductCard(product: available[i]),
                );
              },
              loading: () =>
              const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorCard(message: e.toString()),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filtre pill ───────────────────────────────────────────────────────
class _CatFilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CatFilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}