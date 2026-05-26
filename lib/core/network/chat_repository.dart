import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ChatRepository(apiClient);
});

class ChatRepository {
  final ApiClient _apiClient;
  io.Socket? _socket;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  ChatRepository(this._apiClient);

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  io.Socket? get socket => _socket;

  Future<void> connectSocket() async {
    if (_socket != null && _socket!.connected) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    // In emulator, localhost is 10.0.2.2. Adjust appropriately for iOS/real devices.
    // The API client baseUrl is usually http://10.0.2.2:5000/api
    // We just want the base url: http://10.0.2.2:5000
    final baseUrl = _apiClient.dio.options.baseUrl.replaceAll('/api', '');

    _socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {});

    _socket!.on('receive_message', (data) {
      _messageController.add(Map<String, dynamic>.from(data));
    });

    _socket!.onDisconnect((_) {});
  }

  void disconnectSocket() {
    _socket?.disconnect();
    _socket = null;
  }

  void joinRoom(String roomId) {
    if (_socket?.connected == true) {
      _socket!.emit('join_room', roomId);
    }
  }

  void leaveRoom(String roomId) {
    if (_socket?.connected == true) {
      _socket!.emit('leave_room', roomId);
    }
  }

  void sendMessage(String roomId, String content) {
    if (_socket?.connected == true) {
      _socket!.emit('send_message', {'roomId': roomId, 'content': content});
    }
  }

  Future<List<Map<String, dynamic>>> fetchRooms() async {
    try {
      final response = await _apiClient.dio.get('/chat/rooms');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to load chat rooms');
    }
  }

  Future<Map<String, dynamic>> createRoom({
    required List<String> participantIds,
    String? name,
    bool isGroup = false,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/chat/rooms',
        data: {
          'participantIds': participantIds,
          'name': name,
          'isGroup': isGroup,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['error'] ?? 'Failed to create chat room',
      );
    }
  }

  Future<List<Map<String, dynamic>>> fetchMessages(String roomId) async {
    try {
      final response = await _apiClient.dio.get('/chat/rooms/$roomId/messages');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to load messages');
    }
  }

  Future<List<Map<String, dynamic>>> searchUsers({
    String query = '',
    String role = 'ALL',
  }) async {
    try {
      final response = await _apiClient.dio.get('/users/search', queryParameters: {
        if (query.isNotEmpty) 'query': query,
        if (role != 'ALL') 'role': role,
      });
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to search users');
    }
  }

  Future<void> leaveChatRoom(String roomId) async {
    try {
      await _apiClient.dio.delete('/chat/rooms/$roomId/leave');
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Failed to leave chat room');
    }
  }
}
