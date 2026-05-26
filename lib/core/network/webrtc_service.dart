import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:campus_connect_app/core/network/chat_repository.dart';

final webrtcServiceProvider = Provider<WebRTCService>((ref) {
  final chatRepo = ref.watch(chatRepositoryProvider);
  return WebRTCService(chatRepo);
});

enum CallConnectionState { idle, ringing, connecting, connected, ended }

class WebRTCService {
  final ChatRepository _chatRepository;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  bool _inCall = false;
  String? _remoteUserId;

  // Toggle states tracked in service
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = true; // speaker on by default for video calls
  bool _isFrontCamera = true;

  bool get isMuted => _isMuted;
  bool get isCameraOff => _isCameraOff;
  bool get isSpeakerOn => _isSpeakerOn;
  bool get isFrontCamera => _isFrontCamera;
  bool get inCall => _inCall;

  // Streams for UI updates
  final _onCallStateChanged = StreamController<bool>.broadcast();
  final _onIncomingCall = StreamController<Map<String, dynamic>>.broadcast();
  final _onConnectionState = StreamController<CallConnectionState>.broadcast();
  final _onCallRejected = StreamController<void>.broadcast();
  final _onCallBusy = StreamController<void>.broadcast();
  final _onRemoteFilterChanged = StreamController<int>.broadcast();

  Stream<bool> get onCallStateChanged => _onCallStateChanged.stream;
  Stream<Map<String, dynamic>> get onIncomingCall => _onIncomingCall.stream;
  Stream<CallConnectionState> get onConnectionState => _onConnectionState.stream;
  Stream<void> get onCallRejected => _onCallRejected.stream;
  Stream<void> get onCallBusy => _onCallBusy.stream;
  Stream<int> get onRemoteFilterChanged => _onRemoteFilterChanged.stream;

  CallConnectionState _connectionState = CallConnectionState.idle;
  CallConnectionState get connectionState => _connectionState;

  bool _isSignalingInitialized = false;
  bool _isRenderersInitialized = false;
  Future<void>? _initFuture;

  Timer? _callTimeout;

  WebRTCService(this._chatRepository) {
    _initFuture = _initRenderers();
  }

  Future<void> _initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
    _isRenderersInitialized = true;
  }

  Future<void> ensureRenderersInitialized() async {
    if (!_isRenderersInitialized && _initFuture != null) {
      await _initFuture;
    }
  }

  void _setConnectionState(CallConnectionState state) {
    _connectionState = state;
    _onConnectionState.add(state);
  }

  void _startCallTimeout() {
    _callTimeout?.cancel();
    _callTimeout = Timer(const Duration(seconds: 45), () {
      if (_connectionState == CallConnectionState.ringing ||
          _connectionState == CallConnectionState.connecting) {
        endCall();
      }
    });
  }

  void _cancelCallTimeout() {
    _callTimeout?.cancel();
    _callTimeout = null;
  }

  void initializeSignaling() {
    if (_isSignalingInitialized) return;

    final socket = _chatRepository.socket;
    if (socket == null) return;

    _isSignalingInitialized = true;

    socket.on('incoming_call', (data) {
      if (_inCall) {
        // Already in a call — send busy signal
        socket.emit('call_busy', {'to': data['from']});
        return;
      }
      _onIncomingCall.add(Map<String, dynamic>.from(data));
    });

    socket.on('call_accepted', (data) async {
      _cancelCallTimeout();
      _setConnectionState(CallConnectionState.connecting);
      final description = RTCSessionDescription(data['sdp'], data['type']);
      await _peerConnection?.setRemoteDescription(description);
    });

    socket.on('ice_candidate', (data) async {
      final candidate = RTCIceCandidate(
        data['candidate'],
        data['sdpMid'],
        data['sdpMLineIndex'],
      );
      await _peerConnection?.addCandidate(candidate);
    });

    socket.on('call_ended', (_) {
      endCall();
    });

    socket.on('call_rejected', (_) {
      _cancelCallTimeout();
      _onCallRejected.add(null);
      endCall();
    });

    socket.on('call_busy', (_) {
      _cancelCallTimeout();
      _onCallBusy.add(null);
      endCall();
    });

    socket.on('filter_changed', (data) {
      if (data != null && data['filterIndex'] != null) {
        _onRemoteFilterChanged.add(data['filterIndex']);
      }
    });
  }

  Future<void> _createPeerConnection() async {
    try {
      final configuration = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          {'urls': 'stun:stun1.l.google.com:19302'},
        ]
      };

      _peerConnection = await createPeerConnection(configuration);

      _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
        if (_remoteUserId != null) {
          _chatRepository.socket?.emit('ice_candidate', {
            'to': _remoteUserId,
            'candidate': candidate.toMap(),
          });
        }
      };

      _peerConnection?.onTrack = (RTCTrackEvent event) {
        if (event.track.kind == 'video') {
          _remoteStream = event.streams[0];
          remoteRenderer.srcObject = _remoteStream;
        }
      };

      _peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
        switch (state) {
          case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
            _setConnectionState(CallConnectionState.connecting);
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
            _setConnectionState(CallConnectionState.connected);
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
            if (_inCall) {
              _setConnectionState(CallConnectionState.ended);
              endCall();
            }
            break;
          default:
            break;
        }
      };

      // Get local media
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {'facingMode': 'user'},
      });

      localRenderer.srcObject = _localStream;

      // Set speaker on by default for video calls
      Helper.setSpeakerphoneOn(_isSpeakerOn);

      _localStream?.getTracks().forEach((track) {
        _peerConnection?.addTrack(track, _localStream!);
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> startCall(String remoteId, String myName, String myId) async {
    try {
      await ensureRenderersInitialized();

      _inCall = true;
      _resetToggles();
      _onCallStateChanged.add(true);
      _setConnectionState(CallConnectionState.ringing);
      _remoteUserId = remoteId;
      _startCallTimeout();
      await _createPeerConnection();

      final offer = await _peerConnection?.createOffer();
      await _peerConnection?.setLocalDescription(offer!);

      _chatRepository.socket?.emit('call_user', {
        'userToCall': remoteId,
        'signalData': offer?.toMap(),
        'from': myId,
        'name': myName,
      });
    } catch (e) {
      endCall();
    }
  }

  Future<void> answerCall(String remoteId, Map<String, dynamic> offerData) async {
    try {
      await ensureRenderersInitialized();

      _inCall = true;
      _resetToggles();
      _onCallStateChanged.add(true);
      _setConnectionState(CallConnectionState.connecting);
      _remoteUserId = remoteId;
      await _createPeerConnection();

      final offer = RTCSessionDescription(offerData['sdp'], offerData['type']);
      await _peerConnection?.setRemoteDescription(offer);

      final answer = await _peerConnection?.createAnswer();
      await _peerConnection?.setLocalDescription(answer!);

      _chatRepository.socket?.emit('answer_call', {
        'to': remoteId,
        'signal': answer?.toMap(),
      });
    } catch (e) {
      endCall();
    }
  }

  void rejectCall(String callerId) {
    _chatRepository.socket?.emit('reject_call', {'to': callerId});
  }

  Future<void> endCall() async {
    _cancelCallTimeout();
    try {
      if (_remoteUserId != null) {
        _chatRepository.socket?.emit('end_call', {'to': _remoteUserId});
      }

      try {
        _localStream?.getTracks().forEach((track) => track.stop());
        _localStream?.dispose();
      } catch (_) {}
      _localStream = null;

      try {
        _peerConnection?.close();
      } catch (_) {}
      _peerConnection = null;

      localRenderer.srcObject = null;
      remoteRenderer.srcObject = null;
    } finally {
      _inCall = false;
      _remoteUserId = null;
      _setConnectionState(CallConnectionState.idle);
      _onCallStateChanged.add(false);
    }
  }

  void _resetToggles() {
    _isMuted = false;
    _isCameraOff = false;
    _isSpeakerOn = true;
    _isFrontCamera = true;
  }

  void toggleMute() {
    if (_localStream != null) {
      final audioTracks = _localStream!.getAudioTracks();
      if (audioTracks.isNotEmpty) {
        _isMuted = !_isMuted;
        audioTracks[0].enabled = !_isMuted;
      }
    }
  }

  void toggleCamera() {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        _isCameraOff = !_isCameraOff;
        videoTracks[0].enabled = !_isCameraOff;
      }
    }
  }

  Future<void> switchCamera() async {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        await Helper.switchCamera(videoTracks[0]);
        _isFrontCamera = !_isFrontCamera;
      }
    }
  }

  void toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    Helper.setSpeakerphoneOn(_isSpeakerOn);
  }

  void sendFilterChange(int filterIndex) {
    if (_remoteUserId != null) {
      _chatRepository.socket?.emit('filter_changed', {
        'to': _remoteUserId,
        'filterIndex': filterIndex,
      });
    }
  }

  void dispose() {
    _cancelCallTimeout();
    localRenderer.dispose();
    remoteRenderer.dispose();
    _onCallStateChanged.close();
    _onIncomingCall.close();
    _onConnectionState.close();
    _onCallRejected.close();
    _onCallBusy.close();
    endCall();
  }
}
