import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/router.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);  // ✅ List directe, pas async
    final total = ref.watch(cartTotalProvider);
    final isEmpty = ref.watch(cartIsEmptyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon panier'),
        actions: [
          if (!isEmpty)
            TextButton(
              onPressed: () => _confirmClear(context, ref),
              child: const Text('Vider',
                  style: TextStyle(color: AppTheme.qualityBad)),
            ),
        ],
      ),
      body: isEmpty
          ? _EmptyCart()
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (ctx, i) => _CartItemCard(item: items[i]),
            ),
          ),
          _CartSummary(total: total),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Vider le panier'),
        content: const Text('Supprimer tous les articles ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clear();
              Navigator.pop(ctx);
            },
            child: const Text('Vider',
                style: TextStyle(color: AppTheme.qualityBad)),
          ),
        ],
      ),
    );
  }
}

// ── Carte article ──────────────────────────────────────────────────────
class _CartItemCard extends ConsumerWidget {
  final CartItem item;
  const _CartItemCard({required this.item});

  String _emoji(String cat) {
    const map = {
      'pommes': '🍎', 'tomates': '🍅', 'bananes': '🍌',
      'oranges': '🍊', 'citrons': '🍋', 'carottes': '🥕',
      'raisin': '🍇', 'fraises': '🍓', 'laitue': '🥬',
    };
    return map[cat.toLowerCase()] ?? '🫐';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.read(cartProvider.notifier);
    final product = item.product;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: const Color(0x0F2D6A4F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(_emoji(product.category),
                  style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                if (product.price != null)
                  Text('${product.price!.toStringAsFixed(2)} DT/kg',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.accent)),
                const SizedBox(height: 3),
                Text(
                  'Total : ${item.total.toStringAsFixed(2)} DT',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _QtyButton(
                icon: Icons.remove,
                onTap: () => cart.removeItem(product.id),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('${item.quantity}',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              _QtyButton(
                icon: Icons.add,
                onTap: () => cart.addItem(product),
                isAdd: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isAdd;

  const _QtyButton(
      {required this.icon, required this.onTap, this.isAdd = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: isAdd ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isAdd ? AppTheme.primary : AppTheme.divider),
        ),
        child: Icon(icon,
            size: 16,
            color: isAdd ? Colors.white : AppTheme.textPrimary),
      ),
    );
  }
}

// ── Résumé ─────────────────────────────────────────────────────────────
class _CartSummary extends ConsumerWidget {
  final double total;
  const _CartSummary({required this.total});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemCount = ref.watch(cartItemCountProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        border: Border(top: BorderSide(color: AppTheme.divider)),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$itemCount article(s)',
                  style: Theme.of(context).textTheme.bodyMedium),
              Text(
                '${total.toStringAsFixed(2)} DT',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push(AppRoutes.cartConfirmation),
              child: const Text('Valider la commande'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Panier vide ────────────────────────────────────────────────────────
class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🛒', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('Votre panier est vide',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Ajoutez des produits depuis le catalogue',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.catalogue),
            child: const Text('Voir le catalogue'),
          ),
        ],
      ),
    );
  }
}