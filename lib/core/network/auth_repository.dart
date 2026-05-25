import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient);
});

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<void> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      final token = response.data['token'];
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['error'] ?? 'Login failed');
      }
      throw Exception('Network error occurred');
    }
  }

  Future<void> register(Map<String, dynamic> data) async {
    try {
      await _apiClient.dio.post('/auth/register', data: data);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['error'] ?? 'Registration failed');
      }
      throw Exception('Network error occurred');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _apiClient.dio.get('/users/me');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['error'] ?? 'Failed to load profile');
      }
      throw Exception('Network error occurred');
    }
  }

  Future<List<Map<String, dynamic>>> getAllStudents() async {
    try {
      final response = await _apiClient.dio.get('/users/all');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['error'] ?? 'Failed to load students');
      }
      throw Exception('Network error occurred');
    }
  }
}
