import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/data_models.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  late final CookieJar _cookieJar;
  bool _isInitialized = false;

  static const String _baseUrl = 'https://archana-computers.onrender.com';
  static const String _sessionKey = 'user_session';

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    _dio.interceptors.add(LogInterceptor(responseBody: true));
  }

  Future<void> init() async {
    if (_isInitialized) return;

    final appDocDir = await getApplicationDocumentsDirectory();
    final String path = '${appDocDir.path}/.cookies/';
    _cookieJar = PersistCookieJar(storage: FileStorage(path));
    _dio.interceptors.add(CookieManager(_cookieJar));

    _isInitialized = true;
  }

  // ── Session Persistence ──────────────────────────────────────────────────

  Future<void> saveSession(UserSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = jsonEncode({
      'id': session.id,
      'email': session.email,
      'name': session.name,
      'role': session.role,
      'client_id': session.clientId,
    });
    await prefs.setString(_sessionKey, sessionJson);
  }

  Future<UserSession?> getSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(_sessionKey);
    if (sessionJson == null) return null;
    try {
      final Map<String, dynamic> data = jsonDecode(sessionJson);
      return UserSession.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await _cookieJar.deleteAll();
  }

  // ── Auth ─────────────────────────────────────────────────────────────────

  // ── Auth ─────────────────────────────────────────────────────────────────

  /// Returns UserSession on success.
  /// Throws [ApiException] on failure.
  Future<UserSession> login(String email, String password) async {
    final res = await _dio.post(
      '/api/login',
      data: {'email': email.trim(), 'password': password},
    );
    if (res.statusCode == 200) {
      final user = res.data['user'] as Map<String, dynamic>;
      return UserSession.fromJson(user);
    }
    throw ApiException(_errorMessage(res));
  }

  Future<void> logout() async {
    try {
      await _dio.post('/api/logout');
    } catch (_) {}
    await clearSession();
  }

  // ── Tickets ───────────────────────────────────────────────────────────────

  /// Fetch tickets. Admins see all; clients see their own.
  /// Optionally filter by status: "new" | "processing" | "completed"
  Future<List<Ticket>> getTickets({String? status}) async {
    final res = await _dio.get(
      '/api/tickets',
      queryParameters: status != null ? {'status': status} : null,
    );
    if (res.statusCode == 200) {
      final list = res.data['tickets'] as List<dynamic>? ?? [];
      return list
          .map((e) => Ticket.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw ApiException(_errorMessage(res));
  }

  /// Create a ticket (client or admin).
  Future<Ticket> createTicket({
    required String title,
    required String type,
    required String remarks,
    String? clientId, // admin only
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'type': type,
      'remarks': remarks,
    };
    if (clientId != null) body['client_id'] = clientId;

    final res = await _dio.post('/api/tickets', data: body);
    if (res.statusCode == 201) {
      return Ticket.fromJson(res.data as Map<String, dynamic>);
    }
    throw ApiException(_errorMessage(res));
  }

  /// Update ticket status (admin only).
  Future<void> updateTicketStatus(String ticketId, String status) async {
    final res = await _dio.patch(
      '/api/tickets/$ticketId/status',
      data: {'status': status},
    );
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(res));
    }
  }

  // ── Clients (admin only) ──────────────────────────────────────────────────

  Future<List<Client>> getClients() async {
    final res = await _dio.get('/api/clients');
    if (res.statusCode == 200) {
      final list = res.data['clients'] as List<dynamic>? ?? [];
      return list
          .map((e) => Client.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw ApiException(_errorMessage(res));
  }

  /// Create a client. Returns the generated one-time password.
  Future<String> createClient({
    required String name,
    required String email,
    String phone = '',
    String address = '',
  }) async {
    final body = <String, dynamic>{'name': name, 'email': email};
    if (phone.isNotEmpty) body['phone'] = phone;
    if (address.isNotEmpty) body['address'] = address;

    final res = await _dio.post('/api/clients', data: body);
    if (res.statusCode == 201) {
      return res.data['password'] as String;
    }
    throw ApiException(_errorMessage(res));
  }

  Future<void> updateClient({
    required String id,
    required String name,
    required String email,
    required String phone,
    required String address,
  }) async {
    final res = await _dio.put(
      '/api/clients/$id',
      data: {
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
      },
    );
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(res));
    }
  }

  Future<String> resetClientPassword(String clientId) async {
    final res = await _dio.patch('/api/clients/$clientId/reset-password');
    if (res.statusCode == 200) {
      return res.data['password'] as String;
    }
    throw ApiException(_errorMessage(res));
  }

  // ── Products ─────────────────────────────────────────────────────────────

  Future<List<Product>> getProducts() async {
    final res = await _dio.get('/api/products');
    if (res.statusCode == 200) {
      final list = res.data['products'] as List<dynamic>? ?? [];
      return list
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw ApiException(_errorMessage(res));
  }

  Future<void> createProduct({required String name, required double cost}) async {
    final res = await _dio.put(
      '/api/products',
      data: {'name': name, 'cost': cost},
    );
    if (res.statusCode != 201) {
      throw ApiException(_errorMessage(res));
    }
  }

  Future<void> deleteProduct(String productId) async {
    final res = await _dio.delete('/api/products/$productId');
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(res));
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _errorMessage(Response res) {
    // Try to extract a message field from the JSON body, otherwise use status.
    try {
      final body = res.data;
      if (body is Map && body.containsKey('message')) {
        return body['message'].toString();
      }
      if (body is Map && body.containsKey('error')) {
        return body['error'].toString();
      }
    } catch (_) {}
    return 'Request failed (${res.statusCode})';
  }
}

// ── Custom exception ──────────────────────────────────────────────────────
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
