import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:campus_connect_app/core/network/webrtc_service.dart';
import 'package:campus_connect_app/chat/view/video_filter.dart';

class CallScreen extends ConsumerStatefulWidget {
  final bool isIncoming;
  final String remoteUserId;
  final String callerName;
  final Map<String, dynamic>? offerData;

  const CallScreen({
    super.key,
    required this.isIncoming,
    required this.remoteUserId,
    required this.callerName,
    this.offerData,
  });

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> with TickerProviderStateMixin {
  late final StreamSubscription<bool> _callStateSub;
  late final StreamSubscription<CallConnectionState> _connectionSub;
  late final StreamSubscription<int> _remoteFilterSub;

  CallConnectionState _callState = CallConnectionState.ringing;

  // Call timer
  Timer? _callTimer;
  int _callDurationSeconds = 0;

  // Filter
  int _selectedFilterIndex = 0;
  int _remoteFilterIndex = 0;

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Controls visibility
  bool _controlsVisible = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    final webrtcService = ref.read(webrtcServiceProvider);

    // Pulse animation for ringing state
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Listen to call state
    _callStateSub = webrtcService.onCallStateChanged.listen((inCall) {
      if (!inCall && mounted) {
        _showEndedThenPop();
      }
    });

    _connectionSub = webrtcService.onConnectionState.listen((state) {
      if (mounted) {
        setState(() => _callState = state);
        if (state == CallConnectionState.connected) {
          _pulseController.stop();
          _startCallTimer();
          _startHideControlsTimer();
        }
      }
    });

    _remoteFilterSub = webrtcService.onRemoteFilterChanged.listen((index) {
      if (mounted) {
        setState(() => _remoteFilterIndex = index);
      }
    });
  }

  void _showEndedThenPop() {
    if (!mounted) return;
    setState(() => _callState = CallConnectionState.ended);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _startCallTimer() {
    _callTimer?.cancel();
    _callDurationSeconds = 0;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _callDurationSeconds++);
    });
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _callState == CallConnectionState.connected) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  String get _formattedDuration {
    final min = (_callDurationSeconds ~/ 60).toString().padLeft(2, '0');
    final sec = (_callDurationSeconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _callTimer?.cancel();
    _hideControlsTimer?.cancel();
    _callStateSub.cancel();
    _connectionSub.cancel();
    _remoteFilterSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: _callState == CallConnectionState.ended
          ? _buildEndedPhase()
          : (_callState == CallConnectionState.connected
              ? _buildConnectedPhase()
              : _buildRingingPhase()),
    );
  }

  // ─── Phase 1: Ringing / Calling ──────────────────────────
  Widget _buildRingingPhase() {
    final webrtcService = ref.read(webrtcServiceProvider);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            // Pulsing avatar
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(25),
                  border: Border.all(color: Colors.white30, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF777DF2).withAlpha(77),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  FluentIcons.person_24_filled,
                  size: 56,
                  color: Colors.white70,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Name
            Text(
              widget.callerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            // Status
            Text(
              widget.isIncoming ? 'Connecting...' : 'Calling...',
              style: TextStyle(
                color: Colors.white.withAlpha(153),
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            // Animated dots
            _buildAnimatedDots(),
            const Spacer(flex: 3),
            // Cancel button
            GestureDetector(
              onTap: () => webrtcService.endCall(),
              child: Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x66EF4444),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  FluentIcons.call_end_24_filled,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.isIncoming ? 'Connecting' : 'Cancel',
              style: TextStyle(color: Colors.white.withAlpha(128), fontSize: 13),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedDots() {
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final delay = i * 0.3;
              final value = ((_pulseController.value + delay) % 1.0);
              final opacity = (value < 0.5 ? value * 2 : (1 - value) * 2).clamp(0.3, 1.0);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha((opacity * 255).round()),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  // ─── Phase 2: Connected ───────────────────────────────────
  Widget _buildConnectedPhase() {
    final webrtcService = ref.read(webrtcServiceProvider);
    final currentFilter = VideoFilters.presets[_selectedFilterIndex];

    return GestureDetector(
      onTap: () {
        setState(() => _controlsVisible = !_controlsVisible);
        if (_controlsVisible) _startHideControlsTimer();
      },
      child: Stack(
        children: [
          // Remote Video (full screen)
          Positioned.fill(
            child: VideoFilters.presets[_remoteFilterIndex].colorFilter != null
                ? ColorFiltered(
                    colorFilter: VideoFilters.presets[_remoteFilterIndex].colorFilter!,
                    child: RTCVideoView(
                      webrtcService.remoteRenderer,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  )
                : RTCVideoView(
                    webrtcService.remoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
          ),

          // Local Video PIP (with optional filter)
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 60,
            width: 110,
            height: 155,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withAlpha(77), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(102),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: currentFilter.colorFilter != null
                    ? ColorFiltered(
                        colorFilter: currentFilter.colorFilter!,
                        child: RTCVideoView(
                          webrtcService.localRenderer,
                          mirror: true,
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        ),
                      )
                    : RTCVideoView(
                        webrtcService.localRenderer,
                        mirror: true,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
              ),
            ),
          ),

          // Top bar — name + timer + connection status
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            top: _controlsVisible ? 0 : -100,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 8, 20, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withAlpha(179), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  // Connection dot
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Name
                  Expanded(
                    child: Text(
                      widget.callerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Timer
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(38),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formattedDuration,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom controls
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            bottom: _controlsVisible ? 0 : -120,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withAlpha(179), Colors.transparent],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlBtn(
                    icon: webrtcService.isMuted
                        ? FluentIcons.mic_off_24_filled
                        : FluentIcons.mic_24_regular,
                    label: webrtcService.isMuted ? 'Unmute' : 'Mute',
                    isActive: webrtcService.isMuted,
                    onTap: () {
                      webrtcService.toggleMute();
                      setState(() {});
                    },
                  ),
                  _buildControlBtn(
                    icon: webrtcService.isCameraOff
                        ? FluentIcons.video_off_24_filled
                        : FluentIcons.video_24_regular,
                    label: webrtcService.isCameraOff ? 'Cam On' : 'Cam Off',
                    isActive: webrtcService.isCameraOff,
                    onTap: () {
                      webrtcService.toggleCamera();
                      setState(() {});
                    },
                  ),
                  _buildControlBtn(
                    icon: FluentIcons.camera_switch_24_regular,
                    label: 'Flip',
                    onTap: () {
                      webrtcService.switchCamera();
                      setState(() {});
                    },
                  ),
                  _buildControlBtn(
                    icon: webrtcService.isSpeakerOn
                        ? FluentIcons.speaker_2_24_filled
                        : FluentIcons.speaker_off_24_regular,
                    label: webrtcService.isSpeakerOn ? 'Speaker' : 'Earpiece',
                    isActive: !webrtcService.isSpeakerOn,
                    onTap: () {
                      webrtcService.toggleSpeaker();
                      setState(() {});
                    },
                  ),
                  _buildControlBtn(
                    icon: FluentIcons.sparkle_24_regular,
                    label: 'Filters',
                    onTap: _showFilterPicker,
                  ),
                  // End call — bigger & red
                  GestureDetector(
                    onTap: () => webrtcService.endCall(),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x66EF4444),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        FluentIcons.call_end_24_filled,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFFEF4444).withAlpha(230)
                  : Colors.white.withAlpha(38),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }

  void _showFilterPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterPickerSheet(
        selectedIndex: _selectedFilterIndex,
        onFilterSelected: (index) {
          setState(() => _selectedFilterIndex = index);
          ref.read(webrtcServiceProvider).sendFilterChange(index);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  // ─── Phase 3: Ended ───────────────────────────────────────
  Widget _buildEndedPhase() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(20),
              ),
              child: Icon(
                FluentIcons.call_end_24_filled,
                size: 36,
                color: Colors.white.withAlpha(153),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Call Ended',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _callDurationSeconds > 0 ? _formattedDuration : '',
              style: TextStyle(
                color: Colors.white.withAlpha(128),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
