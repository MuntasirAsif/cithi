import 'package:cithi/service/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../service/webrtc_service.dart';

class CallScreen extends StatefulWidget {
  final String selfId;
  final String targetId;
  final Map<String, dynamic>? incomingOffer;

  const CallScreen({
    required this.selfId,
    required this.targetId,
    super.key,
    this.incomingOffer,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  final _webrtcService = WebRTCService();
  final _signalingService = SocketService();

  bool isMuted = false;
  bool isVideoOff = false;

  @override
  void initState() {
    super.initState();
    _initRenderers();
    _startCall();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  Future<void> _startCall() async {
    _signalingService.connect(userId: widget.selfId);
    await _webrtcService.init();

    _localRenderer.srcObject = _webrtcService.localStream;

    // Emit ICE candidates
    _webrtcService.onIceCandidate((candidate) {
      print("📤 Local ICE candidate: ${candidate.toMap()}");
      _signalingService.sendIceCandidate(widget.targetId, candidate.toMap());
    });

    // Receive remote stream
    _webrtcService.onTrack((stream) {
      print("🎥 Received remote stream: ${stream.id}");
      for (var track in stream.getTracks()) {
        print("🔍 Track kind: ${track.kind}, enabled: ${track.enabled}");
      }
      setState(() {
        _remoteRenderer.srcObject = stream;
      });
    });

    // Handle incoming answer
    _signalingService.onAnswer((data) async {
      print("📥 Received answer: $data");
      final answer = RTCSessionDescription(
        data['answer']['sdp'],
        data['answer']['type'],
      );
      await _webrtcService.setRemoteDescription(answer);
    });

    // Handle incoming ICE candidates
    _signalingService.onIceCandidate((data) {
      print("📥 Received ICE candidate: $data");
      final candidate = RTCIceCandidate(
        data['candidate'],
        data['sdpMid'],
        data['sdpMLineIndex'],
      );
      _webrtcService.addIceCandidate(candidate);
    });

    // 📞 Handle incoming offer from socket (auto-answer)
    _signalingService.onOffer((data) async {
      print("📥 Incoming offer from ${data['from']}");
      final offer = RTCSessionDescription(
        data['offer']['sdp'],
        data['offer']['type'],
      );
      await _webrtcService.setRemoteDescription(offer);
      final answer = await _webrtcService.createAnswer();
      _signalingService.sendAnswer(data['from'], {
        'sdp': answer.sdp,
        'type': answer.type,
      });
    });

    // Initiate call if we're the caller
    if (widget.incomingOffer != null) {
      final offer = RTCSessionDescription(
        widget.incomingOffer!['sdp'],
        widget.incomingOffer!['type'],
      );
      await _webrtcService.setRemoteDescription(offer);
      final answer = await _webrtcService.createAnswer();
      _signalingService.sendAnswer(widget.targetId, {
        'sdp': answer.sdp,
        'type': answer.type,
      });
    } else {
      final offer = await _webrtcService.createOffer();
      _signalingService.sendOffer(widget.targetId, {
        'sdp': offer.sdp,
        'type': offer.type,
      });
    }

    _webrtcService.onConnectionState((state) {
      print('🔗 Connection State: $state');
    });
  }

  void _toggleMute() {
    setState(() {
      isMuted = !isMuted;
      _webrtcService.toggleAudio(!isMuted);
    });
  }

  void _toggleVideo() {
    setState(() {
      isVideoOff = !isVideoOff;
      _webrtcService.toggleVideo(!isVideoOff);
    });
  }

  void _switchCamera() {
    _webrtcService.switchCamera();
  }

  void _endCall() {
    _localRenderer.srcObject = null;
    _remoteRenderer.srcObject = null;
    _webrtcService.dispose();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _webrtcService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Call with ${widget.targetId}'),
      ),
      body: Column(
        children: [
          Expanded(child: RTCVideoView(_remoteRenderer)),
          Expanded(child: RTCVideoView(_localRenderer, mirror: true)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  onPressed: _toggleMute,
                  backgroundColor: isMuted ? Colors.red : Colors.green,
                  child: Icon(isMuted ? Icons.mic_off : Icons.mic),
                ),
                FloatingActionButton(
                  onPressed: _toggleVideo,
                  backgroundColor: isVideoOff ? Colors.grey : Colors.blue,
                  child: Icon(isVideoOff ? Icons.videocam_off : Icons.videocam),
                ),
                FloatingActionButton(
                  onPressed: _switchCamera,
                  backgroundColor: Colors.orange,
                  child: const Icon(Icons.switch_camera),
                ),
                FloatingActionButton(
                  onPressed: _endCall,
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.call_end),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
