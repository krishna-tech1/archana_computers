import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import '../models/data_models.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  late final CookieJar _cookieJar;

  // ── Base URL ────────────────────────────────────────────────────────────
  // 10.0.2.2 reaches the host machine's localhost from an Android emulator.
  // For a physical device replace with your computer's local IP (e.g. 192.168.x.x).
  static const String _baseUrl = 'https://archana-computers-ticketing-production.up.railway.app';

  ApiService._internal() {
    _cookieJar = CookieJar();

    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
      // Do NOT follow redirects automatically – let us handle 401s.
      validateStatus: (status) => status != null && status < 500,
    ));

    _dio.interceptors.add(CookieManager(_cookieJar));
    _dio.interceptors.add(LogInterceptor(
      responseBody: true,
    ));
  }

  // ── Auth ─────────────────────────────────────────────────────────────────

  /// Returns UserSession on success.
  /// Throws [ApiException] on failure.
  Future<UserSession> login(String email, String password) async {
    final res = await _dio.post('/api/login', data: {
      'email': email.trim(),
      'password': password,
    });
    if (res.statusCode == 200) {
      final user = res.data['user'] as Map<String, dynamic>;
      return UserSession.fromJson(user);
    }
    throw ApiException(_errorMessage(res));
  }

  Future<void> logout() async {
    await _dio.post('/api/logout');
    await _cookieJar.deleteAll();
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
      return list.map((e) => Ticket.fromJson(e as Map<String, dynamic>)).toList();
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
      return Ticket.fromJson(res.data['ticket'] as Map<String, dynamic>);
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
      return list.map((e) => Client.fromJson(e as Map<String, dynamic>)).toList();
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
