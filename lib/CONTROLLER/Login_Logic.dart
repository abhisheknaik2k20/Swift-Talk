import 'package:SwiftTalk/CONTROLLER/User_Repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthLoadingProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}

class AuthManager {
  final AuthLoadingProvider loadingProvider;
  AuthManager({required this.loadingProvider});
  Future<void> emailpassLogin(
      String email, String password, BuildContext context) async {
    final auth = FirebaseAuth.instance;
    final userRepository = UserRepository();
    loadingProvider.setLoading(true);
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
      await userRepository.updateFcmToken(auth.currentUser!.uid);
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.code), backgroundColor: Colors.red));
      }
    } finally {
      loadingProvider.setLoading(false);
    }
  }

  Future<void> emailpassSignup(String name, String phone, String email,
      String password, BuildContext context) async {
    final auth = FirebaseAuth.instance;
    final userRepository = UserRepository();
    try {
      await auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await auth.currentUser?.updateDisplayName(name);
      await userRepository.saveUser(email);
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.code), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('An error occurred, please try again.'),
          backgroundColor: Colors.red));
    }
  }

  Future<void> implementGoogleSignIn(BuildContext context) async {
    final auth = FirebaseAuth.instance;
    final userRepository = UserRepository();
    loadingProvider.setLoading(true);
    try {
      GoogleSignInAccount? googleUser = await GoogleSignIn().signInSilently();
      googleUser ??= await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
      final UserCredential userCredential =
          await auth.signInWithCredential(credential);
      if (userCredential.user == null) return;
      await userRepository
          .saveUser(userCredential.additionalUserInfo?.profile?['email']);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sign-in failed: ${e.toString()}')));
      }
      print('Google sign-in error: $e');
    } finally {
      loadingProvider.setLoading(false);
    }
  }
}
