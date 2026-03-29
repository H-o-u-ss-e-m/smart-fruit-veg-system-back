// ── User Model ───────────────────────────────────────────────────────
class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? token;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    role: UserRole.values.firstWhere(
          (r) => r.name == json['role'],
      orElse: () => UserRole.client,
    ),
    token: json['token'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'email': email, 'role': role.name,
  };

  UserModel copyWith({String? token}) =>
      UserModel(id: id, name: name, email: email, role: role, token: token ?? this.token);
}

enum UserRole { vendeur, client }

// ── Product Model ────────────────────────────────────────────────────
class ProductModel {
  final String id;
  final String name;
  final String category;
  final int quantity;
  final QualityStatus quality;
  final double? price;
  final DateTime addedAt;
  final int maxStorageDays;
  final String? imageUrl;

  const ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.quality,
    this.price,
    required this.addedAt,
    required this.maxStorageDays,
    this.imageUrl,
  });

  int get daysInStorage => DateTime.now().difference(addedAt).inDays;
  int get daysRemaining => maxStorageDays - daysInStorage;
  bool get isExpiringSoon => daysRemaining <= 2 && daysRemaining >= 0;
  bool get isExpired => daysRemaining < 0;

  double get freshnessPercent =>
      ((maxStorageDays - daysInStorage) / maxStorageDays * 100).clamp(0, 100);

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
    id: json['id'] as String,
    name: json['name'] as String,
    category: json['category'] as String,
    quantity: json['quantity'] as int,
    quality: QualityStatus.values.firstWhere(
          (q) => q.name == json['quality'],
      orElse: () => QualityStatus.bon,
    ),
    price: (json['price'] as num?)?.toDouble(),
    addedAt: DateTime.parse(json['added_at'] as String),
    maxStorageDays: json['max_storage_days'] as int,
    imageUrl: json['image_url'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'category': category,
    'quantity': quantity, 'quality': quality.name,
    'price': price, 'added_at': addedAt.toIso8601String(),
    'max_storage_days': maxStorageDays,
  };
}

enum QualityStatus {
  bon,
  moyen,
  mauvais;

  String get label {
    switch (this) {
      case bon: return 'Bon';
      case moyen: return 'Moyen';
      case mauvais: return 'Mauvais';
    }
  }

  String get emoji {
    switch (this) {
      case bon: return '✅';
      case moyen: return '⚠️';
      case mauvais: return '❌';
    }
  }
}

// ── Sensor Data Model ────────────────────────────────────────────────
class SensorData {
  final double temperature;
  final double humidity;
  final DateTime timestamp;
  final bool isTemperatureAlert;
  final bool isHumidityAlert;

  const SensorData({
    required this.temperature,
    required this.humidity,
    required this.timestamp,
    this.isTemperatureAlert = false,
    this.isHumidityAlert = false,
  });

  bool get hasAlert => isTemperatureAlert || isHumidityAlert;

  factory SensorData.fromJson(Map<String, dynamic> json) => SensorData(
    temperature: (json['temperature'] as num).toDouble(),
    humidity: (json['humidity'] as num).toDouble(),
    timestamp: DateTime.parse(json['timestamp'] as String),
    isTemperatureAlert: json['temp_alert'] as bool? ?? false,
    isHumidityAlert: json['humidity_alert'] as bool? ?? false,
  );
}

// ── Stock Summary Model ──────────────────────────────────────────────
class StockSummary {
  final int totalProducts;
  final int totalItems;
  final int goodQualityCount;
  final int mediumQualityCount;
  final int badQualityCount;
  final int expiringSoonCount;
  final int expiredCount;

  const StockSummary({
    required this.totalProducts,
    required this.totalItems,
    required this.goodQualityCount,
    required this.mediumQualityCount,
    required this.badQualityCount,
    required this.expiringSoonCount,
    required this.expiredCount,
  });

  factory StockSummary.fromProducts(List<ProductModel> products) {
    return StockSummary(
      totalProducts: products.length,
      totalItems: products.fold(0, (sum, p) => sum + p.quantity),
      goodQualityCount: products.where((p) => p.quality == QualityStatus.bon).length,
      mediumQualityCount: products.where((p) => p.quality == QualityStatus.moyen).length,
      badQualityCount: products.where((p) => p.quality == QualityStatus.mauvais).length,
      expiringSoonCount: products.where((p) => p.isExpiringSoon).length,
      expiredCount: products.where((p) => p.isExpired).length,
    );
  }
}

// ── Alert Model ──────────────────────────────────────────────────────
class AlertModel {
  final String id;
  final AlertType type;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String? productId;

  const AlertModel({
    required this.id,
    required this.type,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.productId,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) => AlertModel(
    id: json['id'] as String,
    type: AlertType.values.firstWhere((t) => t.name == json['type']),
    message: json['message'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    isRead: json['is_read'] as bool? ?? false,
    productId: json['product_id'] as String?,
  );
}

enum AlertType {
  qualite,
  expiration,
  temperature,
  humidite,
  stock;

  String get label {
    switch (this) {
      case qualite: return 'Qualité';
      case expiration: return 'Expiration';
      case temperature: return 'Température';
      case humidite: return 'Humidité';
      case stock: return 'Stock';
    }
  }
}