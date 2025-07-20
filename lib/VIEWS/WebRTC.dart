import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:SwiftTalk/CONTROLLER/WebRTCLogic.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  Signaling signaling = Signaling();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  String? roomId;
  String? AccessKey;
  String? myUid;
  String? otherUid;
  DocumentSnapshot? snapshot;
  Map<String, dynamic>? data;
  bool sending_Call = false;
  bool reciving_Call = false;
  bool isMuted = false;
  bool isCamOn = true;
  String? currrentUser;
  String? otherUser;
  static const platform = MethodChannel('samples.flutter.dev/microphone');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeRenderers();
    _setupSignaling();
    getSnapShot();
  }

  void _initializeRenderers() {
    try {
      _localRenderer.initialize();
      _remoteRenderer.initialize();
    } catch (e) {
      print('Renderer initialization error: $e');
    }
  }

  void _setupSignaling() {
    try {
      signaling.onAddRemoteStream = ((stream) {
        _remoteRenderer.srcObject = stream;
        if (mounted) setState(() {});
      });
      signaling.openUserMedia(_localRenderer, _remoteRenderer);
    } catch (e) {
      print('Signaling setup error: $e');
    }
  }

  Future<void> _muteMicrophone() async {
    try {
      await platform.invokeMethod('muteMicrophone');
      FirebaseFirestore.instance.collection('rooms').doc(AccessKey).update({
        '${currrentUser}Audio': false,
      });
    } on PlatformException catch (e) {
      print("Failed to mute microphone: '${e.message}'.");
    }
  }

  Future<void> _unmuteMicrophone() async {
    try {
      await platform.invokeMethod('unmuteMicrophone');
      FirebaseFirestore.instance.collection('rooms').doc(AccessKey).update({
        '${currrentUser}Audio': true,
      });
    } on PlatformException catch (e) {
      print("Failed to unmute microphone: '${e.message}'.");
    }
  }

  void createRoom() async {
    try {
      roomId = await signaling.createRoom(_remoteRenderer);
      setState(() {});
      AccessKey = data!['key'];
      await FirebaseFirestore.instance.collection('rooms').doc(AccessKey).set({
        'roomID': roomId,
        'user1Cam': true,
        'user1Audio': true,
        'user2Cam': true,
        'user2Audio': true,
        'user1hangup': false,
        'user2hangup': false
      });
      currrentUser = 'user1';
      otherUser = 'user2';
      List substring = AccessKey!.split('_');
      if (substring[0] == FirebaseAuth.instance.currentUser!.uid) {
        myUid = substring[0];
        otherUid = substring[1];
      } else {
        myUid = substring[1];
        otherUid = substring[0];
      }
    } catch (e) {
      print('Room creation error: $e');
    }
  }

  void joinRoom() async {
    try {
      AccessKey = data!['key'];
      snapshot = await db.collection('rooms').doc(AccessKey).get();
      data = snapshot!.data() as Map<String, dynamic>;
      roomId = data?['roomID'];
      signaling.joinRoom(roomId!, _remoteRenderer);
      currrentUser = 'user2';
      otherUser = 'user1';
    } catch (e) {
      print('Join room error: $e');
    }
  }

  void getSnapShot() async {
    try {
      snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('call_info')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();
      data = snapshot!.data() as Map<String, dynamic>;
    } catch (e) {
      print('Snapshot retrieval error: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  FirebaseFirestore db = FirebaseFirestore.instance;
  String uid = FirebaseAuth.instance.currentUser!.uid;
  Widget _buildVideoCallInterface(Map<String, dynamic>? roomData) {
    if (roomData?['${otherUser}hangup'] == true) {
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('Call Ended',
            style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Container(
            decoration:
                const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            padding: const EdgeInsets.all(20),
            child: const Icon(Icons.call_end, color: Colors.white, size: 100))
      ]));
    }

    return Stack(fit: StackFit.expand, children: [
      _buildRemoteVideo(roomData),
      Positioned(top: 40, right: 20, child: _buildLocalVideoPreview()),
      if (roomData?['${otherUser}Audio'] == false)
        const Positioned(
            top: 40,
            left: 20,
            child: Icon(Icons.mic_off, color: Colors.white, size: 30)),
      Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: _buildCallControlButtons(roomData))
    ]);
  }

  Widget _buildRemoteVideo(Map<String, dynamic>? roomData) {
    if (roomData?['${otherUser}Cam'] == false) {
      return Container(
          color: Colors.black,
          child: const Center(
              child: Icon(Icons.videocam_off, color: Colors.white, size: 100)));
    }
    return roomData?['${otherUser}Cam'] == true
        ? RTCVideoView(_remoteRenderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
        : Container(
            color: Colors.black,
            child: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  CircularProgressIndicator(color: Colors.teal),
                  const SizedBox(height: 20),
                  const Text('Connecting...',
                      style: TextStyle(color: Colors.white))
                ])));
  }

  Widget _buildLocalVideoPreview() => Container(
      width: 120,
      height: 170,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 2)),
      child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: RTCVideoView(_localRenderer,
              mirror: true,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)));

  Widget _buildCallControlButtons(Map<String, dynamic>? roomData) => Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _buildCircularButton(
            icon: isMuted ? Icons.mic_off : Icons.mic,
            color: Colors.black54,
            onPressed: () {
              setState(() {
                isMuted = !isMuted;
                isMuted ? _muteMicrophone() : _unmuteMicrophone();
              });
            }),
        _buildCircularButton(
            icon: isCamOn ? Icons.videocam : Icons.videocam_off,
            color: Colors.black54,
            onPressed: () {
              setState(() {
                isCamOn = !isCamOn;
                FirebaseFirestore.instance
                    .collection('rooms')
                    .doc(AccessKey)
                    .update({'${currrentUser}Cam': isCamOn});
              });
            }),
        _buildCircularButton(
            icon: Icons.call_end,
            color: Colors.red,
            onPressed: () async {
              signaling.hangUp(_localRenderer);
              await _endCall();
            })
      ]));

  Widget _buildCircularButton(
      {required IconData icon,
      required Color color,
      required VoidCallback onPressed}) {
    return Container(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 30),
            onPressed: onPressed));
  }

  Future<void> _endCall() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('call_info')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .delete();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({'isCall': false});

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUid)
          .collection('call_info')
          .doc(otherUid)
          .delete();

      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(AccessKey)
          .update({'${currrentUser}hangup': true});

      await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUid)
          .update({'isCall': false});
    } catch (e) {
      print(e.toString());
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder(
      stream: db
          .collection('users')
          .doc(uid)
          .collection('call_info')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data?.data()?['sending_Call'] == true &&
              sending_Call == false) {
            sending_Call = true;
            createRoom();
          }
          if (snapshot.data?.data()?['reciving_Call'] == true &&
              reciving_Call == false) {
            reciving_Call = true;
            joinRoom();
          }
        }
        return Scaffold(
            backgroundColor: Colors.black,
            body: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('rooms')
                    .doc(AccessKey)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    var roomData = snapshot.data!.data();
                    return _buildVideoCallInterface(roomData);
                  }
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.green));
                }));
      });
}
