import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:SwiftTalk/VIEWS/WebRTC.dart';
import 'package:vibration/vibration.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  void _toggleVibration(bool shouldVibrate) {
    if (shouldVibrate) {
      Vibration.vibrate(pattern: [100, 200, 300, 400], repeat: 1);
    } else {
      Vibration.cancel();
    }
  }

  void _handleCallAccept() {
    _toggleVibration(false);
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const MyHomePage()));
  }

  Future<void> _handleCallReject() async {
    _toggleVibration(false);
    try {
      await _db.collection('users').doc(_uid).update({'isCall': false});
      await _db
          .collection('users')
          .doc(_uid)
          .collection('call_info')
          .doc(_uid)
          .delete();
    } catch (e) {
      print('Error rejecting call: $e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color(0xFF075E54),
      body: StreamBuilder<DocumentSnapshot>(
          stream: _db
              .collection('users')
              .doc(_uid)
              .collection('call_info')
              .doc(_uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }
            String callerName = 'Unknown Caller';
            bool hasCallData = false;
            try {
              if (snapshot.hasData &&
                  snapshot.data != null &&
                  snapshot.data!.exists &&
                  snapshot.data!.data() != null) {
                Map<String, dynamic>? data =
                    snapshot.data!.data() as Map<String, dynamic>?;
                if (data != null && data.containsKey('caller_Name')) {
                  callerName = data['caller_Name'] ?? 'Unknown Caller';
                  hasCallData = true;
                }
              }
            } catch (e) {
              print('Error processing call data: $e');
              callerName = 'Unknown Caller';
              hasCallData = false;
            }
            if (hasCallData) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _toggleVibration(true);
              });
            }
            return SafeArea(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Expanded(
                      flex: 2,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 6),
                                    gradient: RadialGradient(colors: [
                                      Colors.white.withOpacity(0.1),
                                      Colors.white.withOpacity(0.2)
                                    ])),
                                child: const CircleAvatar(
                                    radius: 100,
                                    backgroundColor: Colors.white24,
                                    child: Icon(Icons.person,
                                        color: Colors.white, size: 120))),
                            const SizedBox(height: 20),
                            Text(callerName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 10),
                            Text(
                                hasCallData
                                    ? 'Incoming Call'
                                    : 'No Active Call',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 18))
                          ])),
                  Expanded(
                      child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(30),
                                  topRight: Radius.circular(30)),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    spreadRadius: 5)
                              ]),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _CallButton(
                                    icon: Icons.call,
                                    backgroundColor: Colors.green,
                                    onPressed:
                                        hasCallData ? _handleCallAccept : null),
                                _CallButton(
                                    icon: Icons.call_end,
                                    backgroundColor: Colors.red,
                                    onPressed:
                                        hasCallData ? _handleCallReject : null)
                              ])))
                ]));
          }));
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback? onPressed;

  const _CallButton(
      {required this.icon, required this.backgroundColor, this.onPressed});

  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
          color: onPressed != null ? backgroundColor : Colors.grey.shade400,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color:
                    (onPressed != null ? backgroundColor : Colors.grey.shade400)
                        .withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 3)
          ]),
      child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white, size: 40),
          iconSize: 60,
          padding: const EdgeInsets.all(20)));
}
