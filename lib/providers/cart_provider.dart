import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

// ═══════════════════════════════════════════════════════════════════
// MODÈLE PANIER
// ═══════════════════════════════════════════════════════════════════
class CartItem {
  final ProductModel product;
  final int quantity;

  const CartItem({required this.product, required this.quantity});

  CartItem copyWith({int? quantity}) =>
      CartItem(product: product, quantity: quantity ?? this.quantity);

  double get total => (product.price ?? 0) * quantity;

  Map<String, dynamic> toJson() => {
    'product_id': product.id,
    'product_name': product.name,
    'product_category': product.category,
    'product_price': product.price,
    'product_quality': product.quality.name,
    'product_added_at': product.addedAt.toIso8601String(),
    'product_max_storage_days': product.maxStorageDays,
    'quantity': quantity,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      quantity: json['quantity'] as int,
      product: ProductModel(
        id: json['product_id'] as String,
        name: json['product_name'] as String,
        category: json['product_category'] as String,
        quantity: 0,
        quality: QualityStatus.values.firstWhere(
              (q) => q.name == json['product_quality'],
          orElse: () => QualityStatus.bon,
        ),
        price: (json['product_price'] as num?)?.toDouble(),
        addedAt: DateTime.parse(json['product_added_at'] as String),
        maxStorageDays: json['product_max_storage_days'] as int,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// PERSISTANCE LOCALE
// ═══════════════════════════════════════════════════════════════════
class CartStorage {
  static const _key = 'cart_items';

  static Future<void> save(List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(items.map((i) => i.toJson()).toList());
    await prefs.setString(_key, json);
  }

  static Future<List<CartItem>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_key);
      if (json == null) return [];
      final list = jsonDecode(json) as List;
      return list
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

// ═══════════════════════════════════════════════════════════════════
// CART NOTIFIER — utilise Notifier (pas AsyncNotifier) pour simplicité
// ═══════════════════════════════════════════════════════════════════
class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    // Charger en arrière-plan sans bloquer
    _loadFromStorage();
    return [];
  }

  Future<void> _loadFromStorage() async {
    final items = await CartStorage.load();
    state = items;
  }

  void addItem(ProductModel product, {int quantity = 1}) {
    final index = state.indexWhere((i) => i.product.id == product.id);
    List<CartItem> updated;

    if (index >= 0) {
      updated = List<CartItem>.from(state);
      updated[index] = updated[index].copyWith(
        quantity: updated[index].quantity + quantity,
      );
    } else {
      updated = [...state, CartItem(product: product, quantity: quantity)];
    }

    state = updated;
    CartStorage.save(updated);
  }

  void removeItem(String productId, {int quantity = 1}) {
    final index = state.indexWhere((i) => i.product.id == productId);
    if (index < 0) return;

    List<CartItem> updated;
    final currentQty = state[index].quantity;
    if (currentQty <= quantity) {
      updated = state.where((i) => i.product.id != productId).toList();
    } else {
      updated = List<CartItem>.from(state);
      updated[index] = updated[index].copyWith(quantity: currentQty - quantity);
    }

    state = updated;
    CartStorage.save(updated);
  }

  void deleteItem(String productId) {
    final updated = state.where((i) => i.product.id != productId).toList();
    state = updated;
    CartStorage.save(updated);
  }

  void clear() {
    state = [];
    CartStorage.clear();
  }

  int quantityOf(String productId) {
    try {
      return state.firstWhere((i) => i.product.id == productId).quantity;
    } catch (_) {
      return 0;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════
final cartProvider =
NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);

final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).fold(0, (sum, i) => sum + i.quantity);
});

final cartTotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).fold(0.0, (sum, i) => sum + i.total);
});

final cartIsEmptyProvider = Provider<bool>((ref) {
  return ref.watch(cartProvider).isEmpty;
});