import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'mock_data.dart';

class ApiConfig {
  static const String baseUrl = 'http://192.168.1.100:8000/api';
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
}

class _AppStorage {
  static Future<void> write(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }
  static Future<String?> read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }
  static Future<void> deleteAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;
  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ));
  }
  factory ApiClient() => _instance ??= ApiClient._();
  Dio get dio => _dio;
}

class AuthService {
  Future<UserModel> login({required String email, required String password}) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 800));
      UserModel user;
      if (email == 'vendeur@test.com' && password == 'password123') {
        user = mockVendeur;
      } else if (email == 'client@test.com' && password == 'password123') {
        user = mockClient;
      } else {
        throw 'Email ou mot de passe incorrect';
      }
      await _AppStorage.write('auth_token', user.token ?? '');
      await _AppStorage.write('user_role', user.role.name);
      await _AppStorage.write('user_id', user.id);
      await _AppStorage.write('user_name', user.name);
      await _AppStorage.write('user_email', user.email);
      return user;
    }
    try {
      final response = await ApiClient().dio.post('/auth/login', data: {'email': email, 'password': password});
      final user = UserModel.fromJson(response.data);
      if (user.token != null) {
        await _AppStorage.write('auth_token', user.token!);
        await _AppStorage.write('user_role', user.role.name);
        await _AppStorage.write('user_id', user.id);
      }
      return user;
    } on DioException catch (e) {
      throw e.message ?? 'Erreur de connexion';
    }
  }

  Future<UserModel> register({required String name, required String email, required String password, required UserRole role}) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 800));
      return UserModel(id: '3', name: name, email: email, role: role, token: 'fake-token-new');
    }
    try {
      final response = await ApiClient().dio.post('/auth/register', data: {'name': name, 'email': email, 'password': password, 'role': role.name});
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw e.message ?? 'Erreur inscription';
    }
  }

  Future<void> logout() async => await _AppStorage.deleteAll();

  Future<bool> isLoggedIn() async {
    final token = await _AppStorage.read('auth_token');
    return token != null && token.isNotEmpty;
  }

  Future<UserRole?> getSavedRole() async {
    final role = await _AppStorage.read('user_role');
    if (role == null) return null;
    try { return UserRole.values.firstWhere((r) => r.name == role); } catch (_) { return null; }
  }

  Future<UserModel?> getSavedUser() async {
    try {
      final id = await _AppStorage.read('user_id');
      final name = await _AppStorage.read('user_name');
      final email = await _AppStorage.read('user_email');
      final role = await getSavedRole();
      final token = await _AppStorage.read('auth_token');
      if (id == null || name == null || email == null || role == null) return null;
      return UserModel(id: id, name: name, email: email, role: role, token: token);
    } catch (_) { return null; }
  }
}

class StockService {
  Future<List<ProductModel>> getProducts({String? category, String? quality}) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      var products = List<ProductModel>.from(mockProducts);
      if (category != null) products = products.where((p) => p.category == category).toList();
      if (quality != null) products = products.where((p) => p.quality.name == quality).toList();
      return products;
    }
    final queryParams = <String, dynamic>{};
    if (category != null) queryParams['category'] = category;
    if (quality != null) queryParams['quality'] = quality;
    final response = await ApiClient().dio.get('/products', queryParameters: queryParams);
    return (response.data as List).map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ProductModel> updateProduct(String id, Map<String, dynamic> data) async {
    if (useMockData) { await Future.delayed(const Duration(milliseconds: 300)); return mockProducts.firstWhere((p) => p.id == id); }
    final response = await ApiClient().dio.patch('/products/$id', data: data);
    return ProductModel.fromJson(response.data);
  }

  Future<StockSummary> getSummary() async { final products = await getProducts(); return StockSummary.fromProducts(products); }
}

class SensorService {
  Future<SensorData> getLatestReading() async {
    if (useMockData) { await Future.delayed(const Duration(milliseconds: 300)); return mockSensorData; }
    final response = await ApiClient().dio.get('/sensors/latest');
    return SensorData.fromJson(response.data);
  }
  Future<List<SensorData>> getHistory({int hours = 24}) async {
    if (useMockData) { await Future.delayed(const Duration(milliseconds: 300)); return mockSensorHistory; }
    final response = await ApiClient().dio.get('/sensors/history', queryParameters: {'hours': hours});
    return (response.data as List).map((e) => SensorData.fromJson(e as Map<String, dynamic>)).toList();
  }
}

class AlertService {
  Future<List<AlertModel>> getAlerts({bool unreadOnly = false}) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      return unreadOnly ? mockAlerts.where((a) => !a.isRead).toList() : List<AlertModel>.from(mockAlerts);
    }
    final response = await ApiClient().dio.get('/alerts', queryParameters: {'unread_only': unreadOnly});
    return (response.data as List).map((e) => AlertModel.fromJson(e as Map<String, dynamic>)).toList();
  }
  Future<void> markAsRead(String alertId) async { if (useMockData) return; await ApiClient().dio.patch('/alerts/$alertId/read'); }
  Future<void> markAllAsRead() async { if (useMockData) return; await ApiClient().dio.patch('/alerts/read-all'); }
}