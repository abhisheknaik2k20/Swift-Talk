import 'dart:async';
import 'package:SwiftTalk/CONTROLLER/User_Repository.dart';
import 'package:SwiftTalk/MODELS/User.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CallStatusProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserRepository _userRepository;
  bool _isCallActive = false;
  bool get isCallActive => _isCallActive;
  late StreamSubscription<UserModel?> _subscription;
  CallStatusProvider(this._userRepository) {
    _initCallStatusStream();
  }
  void _initCallStatusStream() {
    if (_auth.currentUser != null) {
      _subscription = _userRepository
          .streamUserData(_auth.currentUser!.uid)
          .listen((userData) {
        if (userData != null) {
          final newCallStatus = userData.isCall;
          if (newCallStatus != _isCallActive) {
            _isCallActive = newCallStatus;
            notifyListeners();
          }
        }
      });
    }
  }

  Future<void> updateCallStatus(bool isActive) async {
    if (_auth.currentUser != null) {
      try {
        await _db
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .update({'isCall': isActive});
        _isCallActive = isActive;
        notifyListeners();
      } catch (e) {
        print('Error updating call status: $e');
      }
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
