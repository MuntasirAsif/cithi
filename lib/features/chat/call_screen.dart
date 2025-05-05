import 'package:cithi/service/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../service/webrtc_service.dart';

class CallScreen extends StatefulWidget {
  final String selfId;
  final String targetId;
  final Map<String, dynamic>? incomingOffer;

  const CallScreen({required this.selfId, required this.targetId, super.key, this.incomingOffer});

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

    _webrtcService.onIceCandidate((candidate) {
      _signalingService.sendIceCandidate(widget.targetId, {
        'candidate': candidate.toMap(),
      });

    });

    _webrtcService.onTrack((stream) {
      setState(() {
        _remoteRenderer.srcObject = stream;
      });
    });

    _signalingService.onAnswer((data) async {
      var answer = RTCSessionDescription(data['answer']['sdp'], data['answer']['type']);
      await _webrtcService.setRemoteDescription(answer);
    });

    _signalingService.onIceCandidate((data) {
      var candidate = RTCIceCandidate(
        data['candidate']['candidate'],
        data['candidate']['sdpMid'],
        data['candidate']['sdpMLineIndex'],
      );
      _webrtcService.addIceCandidate(candidate);
    });

    if (widget.incomingOffer != null) {
      var offer = RTCSessionDescription(
        widget.incomingOffer!['sdp'],
        widget.incomingOffer!['type'],
      );
      await _webrtcService.setRemoteDescription(offer);
      var answer = await _webrtcService.createAnswer();
      _signalingService.sendAnswer(widget.targetId, {
        'sdp': answer.sdp,
        'type': answer.type,
      });
    } else {
      var offer = await _webrtcService.createOffer();
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

