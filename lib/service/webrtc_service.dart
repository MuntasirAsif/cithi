import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  final Map<String, dynamic> _config = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
    ]
  };

  Future<void> init() async {
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {'facingMode': 'user'},
    });

    _peerConnection = await createPeerConnection(_config);

    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });
  }

  MediaStream? get localStream => _localStream;

  Future<RTCSessionDescription> createOffer() async {
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    return offer;
  }

  Future<RTCSessionDescription> createAnswer() async {
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    return answer;
  }

  Future<void> setRemoteDescription(RTCSessionDescription desc) async {
    await _peerConnection?.setRemoteDescription(desc);
  }

  void addIceCandidate(RTCIceCandidate candidate) {
    _peerConnection?.addCandidate(candidate);
  }

  void onIceCandidate(Function(RTCIceCandidate) callback) {
    _peerConnection?.onIceCandidate = callback;
  }

  void onTrack(Function(MediaStream) callback) {
    _peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        callback(event.streams[0]);
      }
    };
  }

  void onConnectionState(Function(RTCPeerConnectionState) callback) {
    _peerConnection?.onConnectionState = callback;
  }

  /// 🔇 Toggle local audio
  void toggleAudio(bool enabled) {
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = enabled;
    });
  }

  /// 🎥 Toggle local video
  void toggleVideo(bool enabled) {
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = enabled;
    });
  }

  /// 🔄 Switch between front/back cameras
  Future<void> switchCamera() async {
    final videoTrack = _localStream?.getVideoTracks().first;
    if (videoTrack != null && videoTrack.kind == 'video') {
      await Helper.switchCamera(videoTrack);
    }
  }

  void dispose() {
    _localStream?.dispose();
    _peerConnection?.close();
    _peerConnection = null;
  }
}
