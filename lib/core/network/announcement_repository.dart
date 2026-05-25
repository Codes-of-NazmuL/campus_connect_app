import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AnnouncementRepository(apiClient);
});

class AnnouncementRepository {
  final ApiClient _apiClient;
  AnnouncementRepository(this._apiClient);

  Future<List<Map<String, dynamic>>> fetchAnnouncements() async {
    try {
      final response = await _apiClient.dio.get('/announcements');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['error'] ?? 'Failed to load announcements',
      );
    }
  }

  Future<Map<String, dynamic>> createAnnouncement({
    required String title,
    required String content,
    String target = 'ALL',
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/announcements',
        data: {'title': title, 'content': content, 'target': target},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['error'] ?? 'Failed to create announcement',
      );
    }
  }

  Future<void> deleteAnnouncement(String id) async {
    try {
      await _apiClient.dio.delete('/announcements/$id');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['error'] ?? 'Failed to delete announcement',
      );
    }
  }
}
