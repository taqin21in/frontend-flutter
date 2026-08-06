import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/auth_session.dart';
import '../models/booking.dart';
import '../models/car.dart';

class ApiClient {
  ApiClient({
    http.Client? httpClient,
    this.baseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8080/api',
    ),
  }) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  final String baseUrl;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _post('/auth/login', {
      'email': email,
      'password': password,
    });
    return AuthSession.fromJson(response);
  }

  Future<AuthSession> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await _post('/auth/register', {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'password': password,
    });
    return AuthSession.fromJson(response);
  }

  Future<List<Car>> fetchCars({bool onlyAvailable = false}) async {
    final path = onlyAvailable ? '/cars?status=AVAILABLE' : '/cars';
    final response = await _get(path);
    return (response as List)
        .map((item) => Car.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Booking>> fetchBookings(String email) async {
    final response = await _get('/bookings/user/$email');
    return (response as List)
        .map((item) => Booking.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Booking> createBooking({
    required int userId,
    required int carId,
    required DateTime startDate,
    required DateTime endDate,
    required String pickupLocation,
    required String returnLocation,
  }) async {
    final response = await _post('/bookings', {
      'userId': userId,
      'carId': carId,
      'startDate': _dateOnly(startDate),
      'endDate': _dateOnly(endDate),
      'pickupLocation': pickupLocation,
      'returnLocation': returnLocation,
    });
    return Booking.fromJson(response);
  }

  Future<Booking> payBooking(int bookingId, String method) async {
    final response = await _post('/bookings/$bookingId/pay', {
      'method': method,
    });
    return Booking.fromJson(response);
  }

  Future<dynamic> _get(String path) async {
    final response = await _httpClient.get(Uri.parse('$baseUrl$path'));
    return _handle(response);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _handle(response) as Map<String, dynamic>;
  }

  dynamic _handle(http.Response response) {
    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    if (decoded is Map<String, dynamic>) {
      throw ApiException(decoded['message']?.toString() ?? 'Request gagal');
    }

    throw ApiException('Request gagal dengan status ${response.statusCode}');
  }

  String _dateOnly(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
