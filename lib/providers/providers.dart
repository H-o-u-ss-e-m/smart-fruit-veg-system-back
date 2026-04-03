import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'cart_provider.dart';

// ── Services providers ───────────────────────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final stockServiceProvider = Provider<StockService>((ref) => StockService());
final sensorServiceProvider = Provider<SensorService>((ref) => SensorService());
final alertServiceProvider = Provider<AlertService>((ref) => AlertService());

// ── Auth State ───────────────────────────────────────────────────────
class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    // Restaurer l'utilisateur sauvegardé au démarrage
    final service = ref.read(authServiceProvider);
    final isLogged = await service.isLoggedIn();
    if (!isLogged) return null;
    return await service.getSavedUser();
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
          () => ref.read(authServiceProvider).login(
        email: email,
        password: password,
      ),
    );
  }

  Future<void> register(
      String name,
      String email,
      String password,
      UserRole role,
      ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
          () => ref.read(authServiceProvider).register(
        name: name,
        email: email,
        password: password,
        role: role,
      ),
    );
  }

  Future<void> logout() async {
    await ref.read(authServiceProvider).logout();
    state = const AsyncData(null);
  }
}

final authProvider =
AsyncNotifierProvider<AuthNotifier, UserModel?>(AuthNotifier.new);

// ── Products State ───────────────────────────────────────────────────
class ProductsNotifier extends AsyncNotifier<List<ProductModel>> {
  @override
  Future<List<ProductModel>> build() => _fetchProducts();

  Future<List<ProductModel>> _fetchProducts({
    String? category,
    String? quality,
  }) =>
      ref.read(stockServiceProvider).getProducts(
        category: category,
        quality: quality,
      );

  Future<void> refresh({String? category, String? quality}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
          () => _fetchProducts(category: category, quality: quality),
    );
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await ref.read(stockServiceProvider).updateProduct(id, data);
    await refresh();
  }
}

final productsProvider =
AsyncNotifierProvider<ProductsNotifier, List<ProductModel>>(
  ProductsNotifier.new,
);

// ── Stock Summary ────────────────────────────────────────────────────
final stockSummaryProvider = FutureProvider<StockSummary>((ref) async {
  final products = await ref.watch(productsProvider.future);
  return StockSummary.fromProducts(products);
});

// ── Sensor Data ──────────────────────────────────────────────────────
final latestSensorProvider = FutureProvider.autoDispose<SensorData>((ref) {
  return ref.read(sensorServiceProvider).getLatestReading();
});

final sensorHistoryProvider =
FutureProvider.autoDispose<List<SensorData>>((ref) {
  return ref.read(sensorServiceProvider).getHistory(hours: 24);
});

// ── Auto-refresh capteurs toutes les 5 minutes ───────────────────────
final sensorRefreshProvider =
StreamProvider.autoDispose<SensorData>((ref) async* {
  while (true) {
    try {
      final data =
      await ref.read(sensorServiceProvider).getLatestReading();
      yield data;
    } catch (_) {}
    await Future.delayed(const Duration(minutes: 5));
  }
});

// ── Alerts ───────────────────────────────────────────────────────────
final alertsProvider =
FutureProvider.autoDispose<List<AlertModel>>((ref) {
  return ref.read(alertServiceProvider).getAlerts();
});

final unreadAlertsCountProvider =
FutureProvider.autoDispose<int>((ref) async {
  final alerts = await ref.watch(alertsProvider.future);
  return alerts.where((a) => !a.isRead).length;
});

// ── Filtres produits ─────────────────────────────────────────────────
final selectedCategoryProvider = StateProvider<String?>((ref) => null);
final selectedQualityProvider = StateProvider<String?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredProductsProvider =
Provider<AsyncValue<List<ProductModel>>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final category = ref.watch(selectedCategoryProvider);
  final quality = ref.watch(selectedQualityProvider);
  final cartItems = ref.watch(cartProvider); // ✅ écoute le panier

  return productsAsync.whenData((products) {
    return products
        .map((p) {
      // Soustraire la quantité dans le panier
      final qtyInCart = cartItems
          .where((i) => i.product.id == p.id)
          .fold(0, (sum, i) => sum + i.quantity);

      // Retourner le produit avec stock ajusté
      return ProductModel(
        id: p.id,
        name: p.name,
        category: p.category,
        quantity: (p.quantity - qtyInCart).clamp(0, p.quantity),
        quality: p.quality,
        price: p.price,
        addedAt: p.addedAt,
        maxStorageDays: p.maxStorageDays,
        imageUrl: p.imageUrl,
      );
    })
        .where((p) {
      final matchQuery = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query);
      final matchCategory =
          category == null || p.category == category;
      final matchQuality =
          quality == null || p.quality.name == quality;
      return matchQuery && matchCategory && matchQuality;
    })
        .toList();
  });
});

// ── Catégories disponibles ───────────────────────────────────────────
final categoriesProvider = Provider<AsyncValue<List<String>>>((ref) {
  return ref.watch(productsProvider).whenData(
        (products) =>
    products.map((p) => p.category).toSet().toList()..sort(),
  );
});