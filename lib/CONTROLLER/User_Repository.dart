import 'package:SwiftTalk/MODELS/User.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class UserRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  Future<void> saveUser(String email) async {
    String fcmToken = await _messaging.getToken() ?? '';
    final userData = UserModel(
        email: email,
        name: _auth.currentUser?.displayName ?? '',
        uid: _auth.currentUser?.uid ?? '',
        photoURL: _auth.currentUser?.photoURL ?? '',
        username: _auth.currentUser?.displayName ?? '',
        fcmToken: fcmToken);
    await _usersCollection
        .doc(_auth.currentUser?.uid)
        .set(userData.toMap(), SetOptions(merge: true));
  }

  UserModel errorUser() {
    return UserModel(
        email: "N/A",
        name: "UNKNOWN",
        uid: "INVALID",
        photoURL: "NULL",
        username: "UNKNOWN");
  }

  Future<UserModel?> getUserById(String userId) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  Future<UserModel?> getCurrentUser() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      return getUserById(currentUser.uid);
    }
    return null;
  }

  Future<void> updateUserStatus(String userId, String status) async {
    await _usersCollection.doc(userId).update({'status': status});
  }

  Future<void> updateStatusImages(
      String userId, List<String> statusImages) async {
    List<Map<String, dynamic>> statusImagesList = statusImages
        .map((e) => StatusImages(
                name: _auth.currentUser?.displayName ?? '',
                imageUrl: e,
                createdAt: Timestamp.now())
            .toMap())
        .toList();

    final docRef = _usersCollection.doc(userId);
    final docSnapshot = await docRef.get();
    if (docSnapshot.exists) {
      final data = docSnapshot.data();
      if (data != null &&
          (data as Map<String, dynamic>).containsKey('statusImages')) {
        await docRef.update({'statusImages': statusImagesList});
      } else {
        await docRef
            .set({'statusImages': statusImagesList}, SetOptions(merge: true));
      }
    } else {
      await docRef.set({'statusImages': statusImagesList});
    }
  }

  Future<bool> deleteUserStatusImageByUrl(String imageUrl) async {
    final docRef = _usersCollection.doc(_auth.currentUser?.uid);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data();
      if (data is Map<String, dynamic> && data.containsKey('statusImages')) {
        // Get the current status images array
        List<dynamic> statusImagesList = List.from(data['statusImages']);
        print('Original statusImages count: ${statusImagesList.length}');

        // Find the index of the object with the matching imageUrl
        int indexToRemove = -1;
        for (int i = 0; i < statusImagesList.length; i++) {
          Map<String, dynamic> statusImage = statusImagesList[i];
          if (statusImage['imageUrl'] == imageUrl) {
            indexToRemove = i;
            break;
          }
        }

        // If found, remove it
        if (indexToRemove != -1) {
          print('Deleting image with URL: $imageUrl');
          statusImagesList.removeAt(indexToRemove);
          await docRef.update({'statusImages': statusImagesList});
          print('Updated statusImages count: ${statusImagesList.length}');
          return true;
        } else {
          print('Image URL not found: $imageUrl');
        }
      } else {
        print('statusImages key not found');
      }
    } else {
      print('Document does not exist');
    }

    return false;
  }

  Future<void> updateUserProfile(String userId, String photoURL) async {
    await _usersCollection.doc(userId).update({'photoURL': photoURL});
  }

  Future<void> updateFcmToken(String userId) async {
    String fcmToken = await _messaging.getToken() ?? '';
    await _usersCollection.doc(userId).update({'fcmToken': fcmToken});
  }

  Future<void> updateCallStatus(String userId, bool isCall) async {
    await _usersCollection.doc(userId).update({'isCall': isCall});
  }

  Stream<List<UserModel>> getAllUsers() {
    return _usersCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .where((user) => user.uid != _auth.currentUser?.uid)
          .toList();
    });
  }

  Stream<UserModel?> streamUserData(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) => doc.exists
        ? UserModel.fromMap(doc.data() as Map<String, dynamic>)
        : null);
  }

  Future<List<UserModel>> getAllUsersOnce() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();

      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error getting users: $e');
      return [];
    }
  }
}

extension UserRepositoryE2E on UserRepository {
  Future<void> saveUserPublicKey(String userId, String publicKeyBase64) async {
    await FirebaseFirestore.instance
        .collection('user_public_keys')
        .doc(userId)
        .set({'publicKey': publicKeyBase64});
  }

  Future<String?> getUserPublicKey(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('user_public_keys')
          .doc(userId)
          .get();

      if (doc.exists) {
        return doc.data()?['publicKey'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user public key: $e');
      return null;
    }
  }
}
