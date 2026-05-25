import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

final examRepositoryProvider = Provider<ExamRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ExamRepository(apiClient.dio);
});

class ExamRepository {
  final Dio _dio;
  ExamRepository(this._dio);

  Future<List<dynamic>> getSchedules() async {
    final response = await _dio.get('/exam/schedules');
    return response.data;
  }

  Future<List<dynamic>> getExamSeats() async {
    final response = await _dio.get('/exam/exam-seats');
    return response.data;
  }

  Future<List<dynamic>> getResults() async {
    final response = await _dio.get('/exam/results');
    return response.data;
  }
}
