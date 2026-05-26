// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_connect_app/core/network/webrtc_service.dart';
import 'package:campus_connect_app/core/network/callkit_service.dart';
import 'package:campus_connect_app/core/network/push_notification_service.dart';
import 'package:campus_connect_app/chat/view/incoming_call_screen.dart';
import 'package:campus_connect_app/core/routes/app_router.dart';

class WebRTCListener extends ConsumerStatefulWidget {
  final Widget child;

  const WebRTCListener({super.key, required this.child});

  @override
  ConsumerState<WebRTCListener> createState() => _WebRTCListenerState();
}

class _WebRTCListenerState extends ConsumerState<WebRTCListener> {
  StreamSubscription? _incomingCallSub;
  StreamSubscription? _callRejectedSub;
  StreamSubscription? _callBusySub;
  StreamSubscription? _callKitAcceptSub;
  StreamSubscription? _notificationTapSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final webrtcService = ref.read(webrtcServiceProvider);

      // ── In-app incoming call (WebSocket) ──────────────────────────────────
      _incomingCallSub = webrtcService.onIncomingCall.listen((data) {
        _showIncomingCallScreen(data);
      });

      _callRejectedSub = webrtcService.onCallRejected.listen((_) {
        _showSnackBar('Call Declined', const Color(0xFFEF4444));
      });

      _callBusySub = webrtcService.onCallBusy.listen((_) {
        _showSnackBar('User is busy', const Color(0xFFF5B800));
      });

      // ── CallKit native UI accepted ──────────────────────────────────────
      _callKitAcceptSub = CallKitService.instance.onCallAccepted.listen((data) {
        _navigateToCallScreen(data);
      });

      // ── Chat notification tapped (background or foreground banner) ────────
      _notificationTapSub =
          PushNotificationService.instance.onNotificationTap.listen((roomId) {
        final navContext = rootNavigatorKey.currentContext;
        if (navContext != null) {
          GoRouter.of(navContext).push('/chat/$roomId');
        }
      });
    });
  }

  @override
  void dispose() {
    _incomingCallSub?.cancel();
    _callRejectedSub?.cancel();
    _callBusySub?.cancel();
    _callKitAcceptSub?.cancel();
    _notificationTapSub?.cancel();
    super.dispose();
  }

  void _showIncomingCallScreen(Map<String, dynamic> data) {
    final navContext = rootNavigatorKey.currentContext;
    if (navContext == null) return;

    Navigator.of(navContext).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return IncomingCallScreen(callData: data);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  /// Called when the user taps "Accept" on the native CallKit full-screen UI
  /// (i.e. app was backgrounded or killed when the call arrived via FCM).
  void _navigateToCallScreen(Map<String, dynamic> data) {
    final navContext = rootNavigatorKey.currentContext;
    if (navContext == null) return;

    final webrtcService = ref.read(webrtcServiceProvider);

    GoRouter.of(navContext).push(
      '/call',
      extra: {
        'isIncoming': true,
        'remoteUserId': data['from'],
        'callerName': data['name'] ?? 'Unknown',
        'offerData': data['signal'],
      },
    );

    // Answer the call via WebRTC
    webrtcService.answerCall(data['from'], data['signal']);
  }

  void _showSnackBar(String message, Color color) {
    final navContext = rootNavigatorKey.currentContext;
    if (navContext == null) return;

    ScaffoldMessenger.maybeOf(navContext)?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == const Color(0xFFEF4444)
                  ? Icons.call_end_rounded
                  : Icons.phone_missed_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(message, style: const TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
