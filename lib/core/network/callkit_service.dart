import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Key used to persist the pending call data across isolate boundaries.
const _kPendingCallKey = 'pending_incoming_call';

/// Holds a pending call read in main() BEFORE runApp(). 
/// Allows GoRouter to start directly on the /call screen, skipping 
/// splash and dashboard entirely.
Map<String, dynamic>? startupPendingCall;

class CallKitService {
  CallKitService._();
  static final CallKitService instance = CallKitService._();

  String? _currentCallId;

  // ── Streams that WebRTCListener subscribes to ──────────────────────────────
  // Emits callData map (callerId, callerName, signalData) when user accepts via CallKit UI
  final _onCallAccepted = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onCallAccepted => _onCallAccepted.stream;

  // Emits when user declines via CallKit UI
  final _onCallDeclined = StreamController<void>.broadcast();
  Stream<void> get onCallDeclined => _onCallDeclined.stream;

  Future<void> initialize() async {
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null) return;

      switch (event.event) {
        case Event.actionCallAccept:
          debugPrint('CallKit: ACTION_CALL_ACCEPT');
          _handleCallAccept(event.body);
          break;
        case Event.actionCallDecline:
          debugPrint('CallKit: ACTION_CALL_DECLINE');
          _clearPendingCall(); // clear any saved call data
          _onCallDeclined.add(null);
          break;
        case Event.actionCallEnded:
          debugPrint('CallKit: ACTION_CALL_ENDED');
          _clearPendingCall();
          break;
        case Event.actionCallTimeout:
          debugPrint('CallKit: ACTION_CALL_TIMEOUT');
          _clearPendingCall();
          _onCallDeclined.add(null);
          break;
        default:
          break;
      }
    });
  }

  Future<void> showIncomingCall({
    required String callerId,
    required String callerName,
    required String signalData,
  }) async {
    _currentCallId = const Uuid().v4();

    // ── CRITICAL: Persist call data to SharedPreferences ──────────────────────
    // When the app is KILLED, `firebaseMessagingBackgroundHandler` runs in a
    // *separate Dart isolate*. Any data written to memory (like _pendingCallData)
    // in that isolate is LOST when Android switches to the main UI isolate.
    // SharedPreferences is the ONLY reliable way to pass data across isolates.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPendingCallKey, jsonEncode({
        'callerId': callerId,
        'callerName': callerName,
        'signalData': signalData,
      }));
      debugPrint('CallKit: Persisted pending call data for $callerName');
    } catch (e) {
      debugPrint('CallKit: Failed to persist call data — $e');
    }

    final params = CallKitParams(
      id: _currentCallId,
      nameCaller: callerName,
      appName: 'Campus Connect',
      // Generate a consistent initials-based avatar from the caller's name.
      // TODO: Replace with actual profile photo URL from backend once available.
      avatar: 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(callerName)}&background=0F3460&color=ffffff&size=128&bold=true',
      handle: 'Video Call',
      type: 1, // 0 = Audio, 1 = Video
      textAccept: 'Accept',
      textDecline: 'Decline',
      missedCallNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Missed call',
        callbackText: 'Call back',
      ),
      duration: 30000,
      extra: <String, dynamic>{
        'callerId': callerId,
        'callerName': callerName,
        'signalData': signalData,
      },
      headers: <String, dynamic>{'apiKey': 'abc@123!', 'platform': 'flutter'},
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0955fa',
        backgroundUrl: 'assets/test.png',
        actionColor: '#4CAF50',
        isImportant: true,
      ),
      ios: const IOSParams(
        iconName: 'CallKitLogo',
        handleType: '',
        supportsVideo: true,
        maximumCallGroups: 2,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: true,
        supportsHolding: true,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'system_ringtone_default',
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  Future<void> endCurrentCall() async {
    if (_currentCallId != null) {
      await FlutterCallkitIncoming.endCall(_currentCallId!);
      _currentCallId = null;
    }
    await _clearPendingCall();
  }

  void _handleCallAccept(Map<String, dynamic> body) {
    // First try to get data from the event body's extra field (app was running)
    final rawExtra = body['extra'];

    Map<String, dynamic> extra = {};
    if (rawExtra is Map) {
      rawExtra.forEach((key, value) {
        extra[key.toString()] = value;
      });
    }

    final callerId = extra['callerId']?.toString();
    final callerName = extra['callerName']?.toString();
    final signalDataStr = extra['signalData']?.toString();

    if (callerId != null && signalDataStr != null) {
      // App was running — data came through the event
      try {
        final signalData = jsonDecode(signalDataStr);
        debugPrint('CallKit: accepted call from $callerName (event)');
        final callData = {
          'from': callerId,
          'name': callerName ?? 'Unknown',
          'signal': signalData,
        };
        _onCallAccepted.add(callData);
      } catch (e) {
        debugPrint('CallKit: failed to parse signalData from event — $e');
      }
    } else {
      // App was killed — the event extra may be empty.
      // Data will be loaded from SharedPreferences by consumePendingCall().
      debugPrint('CallKit: accepted call from killed state (no event extra). Will read from prefs.');
    }
  }

  /// Called ONCE in main() before runApp() to detect if the app was launched
  /// by tapping "Accept" on a call notification.
  /// Populates [startupPendingCall] WITHOUT clearing SharedPreferences, so
  /// [consumePendingCall()] can still read and clear the data later.
  static Future<void> checkAndCachePendingCall() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kPendingCallKey);
      if (raw == null) return;

      final map = jsonDecode(raw) as Map<String, dynamic>;
      final callerId = map['callerId'] as String?;
      final callerName = map['callerName'] as String?;
      final signalDataStr = map['signalData'] as String?;

      if (callerId == null || signalDataStr == null) return;

      final signalData = jsonDecode(signalDataStr);
      startupPendingCall = {
        'from': callerId,
        'name': callerName ?? 'Unknown',
        'signal': signalData,
      };
      debugPrint('CallKit: startup pending call detected for $callerName');
    } catch (e) {
      debugPrint('CallKit: Failed to check pending call — $e');
    }
  }

  /// Called by the Dashboard after it fully loads.
  /// Reads the persisted call data from SharedPreferences and clears it.
  Future<Map<String, dynamic>?> consumePendingCall() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kPendingCallKey);
      if (raw == null) return null;

      await prefs.remove(_kPendingCallKey);
      debugPrint('CallKit: Consumed pending call from SharedPreferences');

      final map = jsonDecode(raw) as Map<String, dynamic>;
      final callerId = map['callerId'] as String?;
      final callerName = map['callerName'] as String?;
      final signalDataStr = map['signalData'] as String?;

      if (callerId == null || signalDataStr == null) return null;

      final signalData = jsonDecode(signalDataStr);
      return {
        'from': callerId,
        'name': callerName ?? 'Unknown',
        'signal': signalData,
      };
    } catch (e) {
      debugPrint('CallKit: Failed to consume pending call — $e');
      return null;
    }
  }

  Future<void> _clearPendingCall() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kPendingCallKey);
    } catch (_) {}
  }

  void dispose() {
    _onCallAccepted.close();
    _onCallDeclined.close();
  }
}
