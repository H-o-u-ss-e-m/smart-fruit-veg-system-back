import '../models/models.dart';

// ═══════════════════════════════════════════════════════════════════
// DONNÉES FICTIVES — à utiliser tant que le backend Python n'est pas prêt
// Pour activer le vrai backend : changer useMockData = false
// ═══════════════════════════════════════════════════════════════════

const bool useMockData = true;

// ── Utilisateurs ─────────────────────────────────────────────────────
const mockVendeur = UserModel(
  id: '1',
  name: 'Ahmed Ben Ali',
  email: 'vendeur@test.com',
  role: UserRole.vendeur,
  token: 'fake-token-vendeur',
);

const mockClient = UserModel(
  id: '2',
  name: 'Sara Mejri',
  email: 'client@test.com',
  role: UserRole.client,
  token: 'fake-token-client',
);

// ── Produits ──────────────────────────────────────────────────────────
final List<ProductModel> mockProducts = [
  ProductModel(
    id: 'p1',
    name: 'Pommes Granny',
    category: 'Pommes',
    quantity: 120,
    quality: QualityStatus.bon,
    price: 3.50,
    addedAt: DateTime.now().subtract(const Duration(days: 2)),
    maxStorageDays: 14,
  ),
  ProductModel(
    id: 'p2',
    name: 'Tomates Rondes',
    category: 'Tomates',
    quantity: 85,
    quality: QualityStatus.bon,
    price: 2.20,
    addedAt: DateTime.now().subtract(const Duration(days: 4)),
    maxStorageDays: 7,
  ),
  ProductModel(
    id: 'p3',
    name: 'Bananes',
    category: 'Bananes',
    quantity: 60,
    quality: QualityStatus.moyen,
    price: 1.80,
    addedAt: DateTime.now().subtract(const Duration(days: 5)),
    maxStorageDays: 6,
  ),
  ProductModel(
    id: 'p4',
    name: 'Oranges Navel',
    category: 'Oranges',
    quantity: 200,
    quality: QualityStatus.bon,
    price: 2.80,
    addedAt: DateTime.now().subtract(const Duration(days: 1)),
    maxStorageDays: 21,
  ),
  ProductModel(
    id: 'p5',
    name: 'Carottes',
    category: 'Carottes',
    quantity: 45,
    quality: QualityStatus.moyen,
    price: 1.20,
    addedAt: DateTime.now().subtract(const Duration(days: 6)),
    maxStorageDays: 7,
  ),
  ProductModel(
    id: 'p6',
    name: 'Citrons',
    category: 'Citrons',
    quantity: 90,
    quality: QualityStatus.bon,
    price: 3.00,
    addedAt: DateTime.now().subtract(const Duration(days: 3)),
    maxStorageDays: 14,
  ),
  ProductModel(
    id: 'p7',
    name: 'Fraises',
    category: 'Fraises',
    quantity: 30,
    quality: QualityStatus.mauvais,
    price: 5.50,
    addedAt: DateTime.now().subtract(const Duration(days: 7)),
    maxStorageDays: 5,
  ),
  ProductModel(
    id: 'p8',
    name: 'Raisin Rouge',
    category: 'Raisin',
    quantity: 55,
    quality: QualityStatus.bon,
    price: 4.20,
    addedAt: DateTime.now().subtract(const Duration(days: 2)),
    maxStorageDays: 10,
  ),
  ProductModel(
    id: 'p9',
    name: 'Laitue',
    category: 'Laitue',
    quantity: 40,
    quality: QualityStatus.moyen,
    price: 1.50,
    addedAt: DateTime.now().subtract(const Duration(days: 5)),
    maxStorageDays: 6,
  ),
  ProductModel(
    id: 'p10',
    name: 'Tomates Cerises',
    category: 'Tomates',
    quantity: 25,
    quality: QualityStatus.mauvais,
    price: 3.80,
    addedAt: DateTime.now().subtract(const Duration(days: 8)),
    maxStorageDays: 7,
  ),
];

// ── Capteurs ──────────────────────────────────────────────────────────
final SensorData mockSensorData = SensorData(
  temperature: 18.5,
  humidity: 65.2,
  timestamp: DateTime.now(),
  isTemperatureAlert: false,
  isHumidityAlert: false,
);

final SensorData mockSensorAlert = SensorData(
  temperature: 28.5,
  humidity: 85.0,
  timestamp: DateTime.now(),
  isTemperatureAlert: true,
  isHumidityAlert: true,
);

final List<SensorData> mockSensorHistory = List.generate(24, (i) {
  return SensorData(
    temperature: 17.0 + (i % 5) * 1.2,
    humidity: 60.0 + (i % 7) * 2.0,
    timestamp: DateTime.now().subtract(Duration(hours: 24 - i)),
  );
});

// ── Alertes ───────────────────────────────────────────────────────────
final List<AlertModel> mockAlerts = [
  AlertModel(
    id: 'a1',
    type: AlertType.expiration,
    message: 'Les fraises (p7) expirent dans moins de 24h',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    isRead: false,
    productId: 'p7',
  ),
  AlertModel(
    id: 'a2',
    type: AlertType.qualite,
    message: 'Tomates Cerises détectées de mauvaise qualité par la caméra',
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    isRead: false,
    productId: 'p10',
  ),
  AlertModel(
    id: 'a3',
    type: AlertType.expiration,
    message: 'Les bananes approchent de leur limite de conservation',
    createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    isRead: true,
    productId: 'p3',
  ),
  AlertModel(
    id: 'a4',
    type: AlertType.temperature,
    message: 'Température de stockage élevée détectée : 28.5°C',
    createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    isRead: true,
  ),
  AlertModel(
    id: 'a5',
    type: AlertType.stock,
    message: 'Stock de fraises bas : 30 unités restantes',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    isRead: true,
    productId: 'p7',
  ),
];