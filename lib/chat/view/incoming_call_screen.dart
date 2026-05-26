import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:campus_connect_app/core/network/webrtc_service.dart';
import 'package:campus_connect_app/core/network/callkit_service.dart';
import 'package:go_router/go_router.dart';

class IncomingCallScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> callData;

  const IncomingCallScreen({super.key, required this.callData});

  @override
  ConsumerState<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends ConsumerState<IncomingCallScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  bool _isHandling = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _handleAccept() async {
    if (_isHandling) return;
    _isHandling = true;

    final webrtcService = ref.read(webrtcServiceProvider);
    final data = widget.callData;

    // Request permissions
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (cameraStatus != PermissionStatus.granted ||
        micStatus != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera and Mic permissions are needed.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
      _isHandling = false;
      return;
    }

    if (!mounted) return;

    // Replace this screen with CallScreen
    context.pushReplacement(
      '/call',
      extra: {
        'isIncoming': true,
        'remoteUserId': data['from'],
        'callerName': data['name'] ?? 'Unknown',
        'offerData': data['signal'],
      },
    );

    // Answer the call
    await webrtcService.answerCall(data['from'], data['signal']);
  }

  void _handleDecline() {
    if (_isHandling) return;
    _isHandling = true;

    final webrtcService = ref.read(webrtcServiceProvider);
    webrtcService.rejectCall(widget.callData['from']);

    // Dismiss the system CallKit notifications ("Incoming call" / "Ongoing call")
    CallKitService.instance.endCurrentCall();

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final callerName = widget.callData['name'] ?? 'Unknown';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F3460),
              Color(0xFF16213E),
              Color(0xFF1A1A2E),
              Color(0xFF0F3460),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                const Spacer(flex: 2),

                // "Incoming Video Call" label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FluentIcons.video_24_filled,
                        color: Colors.white.withAlpha(179),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Incoming Video Call',
                        style: TextStyle(
                          color: Colors.white.withAlpha(179),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Avatar with pulsing glow
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(15),
                      border: Border.all(color: Colors.white.withAlpha(51), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF777DF2).withAlpha(64),
                          blurRadius: 60,
                          spreadRadius: 15,
                        ),
                        BoxShadow(
                          color: const Color(0xFF777DF2).withAlpha(26),
                          blurRadius: 100,
                          spreadRadius: 30,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        callerName.isNotEmpty ? callerName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Caller name
                Text(
                  callerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'wants to video call...',
                  style: TextStyle(
                    color: Colors.white.withAlpha(128),
                    fontSize: 15,
                  ),
                ),

                const Spacer(flex: 3),

                // Accept / Decline buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Decline
                      _buildActionButton(
                        icon: FluentIcons.call_end_24_filled,
                        color: const Color(0xFFEF4444),
                        label: 'Decline',
                        onTap: _handleDecline,
                      ),
                      // Accept
                      _buildActionButton(
                        icon: FluentIcons.video_24_filled,
                        color: const Color(0xFF22C55E),
                        label: 'Accept',
                        onTap: _handleAccept,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(102),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(179),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
