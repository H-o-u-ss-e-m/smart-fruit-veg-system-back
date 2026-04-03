import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/cart_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/router.dart';

// ═══════════════════════════════════════════════════════════════════
// SERVICE COMMANDE
// ═══════════════════════════════════════════════════════════════════
class OrderService {
  final _client = ApiClient();

  Future<void> sendOrder(List<CartItem> items, double total) async {
    final payload = {
      'items': items
          .map((i) => {
        'name': i.product.name,
        'quantity': i.quantity,
        'price': i.product.price,
      })
          .toList(),
      'total': total,
    };
    try {
      await _client.dio.post('/order', data: payload);
    } on DioException catch (e) {
      throw e.error as String? ?? 'Erreur envoi commande';
    }
  }
}

final orderServiceProvider = Provider<OrderService>((ref) => OrderService());

// ═══════════════════════════════════════════════════════════════════
// ÉCRAN CONFIRMATION
// ═══════════════════════════════════════════════════════════════════
class CartConfirmationScreen extends ConsumerStatefulWidget {
  const CartConfirmationScreen({super.key});

  @override
  ConsumerState<CartConfirmationScreen> createState() =>
      _CartConfirmationScreenState();
}

class _CartConfirmationScreenState
    extends ConsumerState<CartConfirmationScreen> {
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(cartProvider);   // ✅ List directe
    final total = ref.watch(cartTotalProvider);
    final itemCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0x0F2D6A4F),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x1A2D6A4F)),
              ),
              child: Column(
                children: [
                  const Text('🛒', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text('Récapitulatif de commande',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text('$itemCount article(s)',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text('Articles commandés',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            // Liste articles
            ...items.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.product.name,
                            style: Theme.of(context).textTheme.titleMedium),
                        Text('Quantité : ${item.quantity}',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  if (item.product.price != null)
                    Text(
                      '${item.total.toStringAsFixed(2)} DT',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            )),

            const SizedBox(height: 16),

            // Total
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  Text(
                    '${total.toStringAsFixed(2)} DT',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),

            // Message erreur
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x0DE63946),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x33E63946)),
                ),
                child: Row(
                  children: [
                    const Text('❌', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              color: AppTheme.qualityBad, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Bouton confirmer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _confirm(items, total),
                child: _isLoading
                    ? const SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
                    : const Text('Confirmer la commande'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => context.pop(),
                child: const Text('Modifier le panier'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm(List<CartItem> items, double total) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // ✅ Envoyer à Flask
      await ref.read(orderServiceProvider).sendOrder(items, total);

      // ✅ Vider le panier
      ref.read(cartProvider.notifier).clear();  // synchrone maintenant

      if (!mounted) return;
      _showSuccess();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text('Commande confirmée !',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Votre commande a été envoyée avec succès.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go(AppRoutes.clientMain);
              },
              child: const Text("Retour à l'accueil"),
            ),
          ],
        ),
      ),
    );
  }
}