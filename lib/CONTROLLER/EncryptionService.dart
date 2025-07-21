import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Use AES-GCM for encryption
  final _algorithm = AesGcm.with256bits();

  // Cache for user's key pairs and shared secrets
  final Map<String, SimpleKeyPair> _keyPairCache = {};
  final Map<String, SecretKey> _sharedSecretCache = {};

  /// Generate a new key pair for the current user
  Future<SimpleKeyPair> generateKeyPair() async {
    final keyPair = await X25519().newKeyPair();
    return keyPair;
  }

  /// Store user's public key in Firestore
  Future<void> storePublicKey(SimpleKeyPair keyPair) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception('User not authenticated');

    final publicKey = await keyPair.extractPublicKey();
    final publicKeyBytes = publicKey.bytes;

    await _firestore.collection('user_keys').doc(currentUserId).set({
      'publicKey': base64Encode(publicKeyBytes),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Cache the key pair
    _keyPairCache[currentUserId] = keyPair;
  }

  /// Retrieve public key for a user
  Future<SimplePublicKey?> getPublicKey(String userId) async {
    try {
      final doc = await _firestore.collection('user_keys').doc(userId).get();
      if (!doc.exists) return null;

      final publicKeyBase64 = doc.data()?['publicKey'] as String?;
      if (publicKeyBase64 == null) return null;

      final publicKeyBytes = base64Decode(publicKeyBase64);
      return SimplePublicKey(publicKeyBytes, type: KeyPairType.x25519);
    } catch (e) {
      print('Error retrieving public key for user $userId: $e');
      return null;
    }
  }

  /// Get or generate key pair for current user
  Future<SimpleKeyPair> getCurrentUserKeyPair() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception('User not authenticated');

    // Check cache first
    if (_keyPairCache.containsKey(currentUserId)) {
      return _keyPairCache[currentUserId]!;
    }

    // Try to retrieve from local storage or generate new
    final keyPair = await generateKeyPair();
    await storePublicKey(keyPair);

    return keyPair;
  }

  /// Generate shared secret between current user and another user
  Future<SecretKey> getSharedSecret(String otherUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception('User not authenticated');

    // Create a consistent cache key regardless of order
    final cacheKey = [currentUserId, otherUserId]..sort();
    final sharedSecretKey = cacheKey.join('_');

    // Check cache first
    if (_sharedSecretCache.containsKey(sharedSecretKey)) {
      return _sharedSecretCache[sharedSecretKey]!;
    }

    // Get current user's key pair
    final currentUserKeyPair = await getCurrentUserKeyPair();

    // Get other user's public key
    final otherUserPublicKey = await getPublicKey(otherUserId);
    if (otherUserPublicKey == null) {
      throw Exception('Could not retrieve public key for user $otherUserId');
    }

    // Generate shared secret using ECDH
    final sharedSecret = await X25519().sharedSecretKey(
      keyPair: currentUserKeyPair,
      remotePublicKey: otherUserPublicKey,
    );

    // Cache the shared secret
    _sharedSecretCache[sharedSecretKey] = sharedSecret;

    return sharedSecret;
  }

  /// Encrypt a message for a specific recipient
  Future<Map<String, String>> encryptMessage(
      String message, String recipientId) async {
    print(
        '🔐 EncryptionService: Encrypting message for recipient: $recipientId');

    try {
      final sharedSecret = await getSharedSecret(recipientId);
      print('🔐 EncryptionService: Got shared secret');

      // Convert message to bytes
      final messageBytes = utf8.encode(message);

      // Generate a random nonce
      final nonce = _algorithm.newNonce();

      // Encrypt the message
      final secretBox = await _algorithm.encrypt(
        messageBytes,
        secretKey: sharedSecret,
        nonce: nonce,
      );

      print('🔐 EncryptionService: Message encrypted successfully');

      return {
        'encryptedData': base64Encode(secretBox.cipherText),
        'nonce': base64Encode(secretBox.nonce),
        'mac': base64Encode(secretBox.mac.bytes),
      };
    } catch (e) {
      print('❌ EncryptionService: Error encrypting message: $e');
      rethrow;
    }
  }

  /// Decrypt a message from a specific sender
  Future<String> decryptMessage(
      Map<String, String> encryptedData, String senderId) async {
    try {
      final sharedSecret = await getSharedSecret(senderId);

      // Extract encrypted components
      final cipherText = base64Decode(encryptedData['encryptedData']!);
      final nonce = base64Decode(encryptedData['nonce']!);
      final mac = Mac(base64Decode(encryptedData['mac']!));

      // Create secret box
      final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);

      // Decrypt the message
      final decryptedBytes = await _algorithm.decrypt(
        secretBox,
        secretKey: sharedSecret,
      );

      return utf8.decode(decryptedBytes);
    } catch (e) {
      print('Error decrypting message: $e');
      return '[Decryption failed]';
    }
  }

  /// Initialize encryption for current user (call this on app startup)
  Future<void> initializeEncryption() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      // Check if user already has a key pair
      final doc =
          await _firestore.collection('user_keys').doc(currentUserId).get();

      if (!doc.exists) {
        // Generate new key pair for first-time user
        await getCurrentUserKeyPair();
        print('New key pair generated for user: $currentUserId');
      } else {
        // User already has keys, generate a new key pair for this session
        // (We don't store private keys remotely for security)
        await getCurrentUserKeyPair();
        print('Key pair initialized for existing user: $currentUserId');
      }
    } catch (e) {
      print('Error initializing encryption: $e');
    }
  }

  /// Verify that two users can exchange encrypted messages
  Future<bool> verifyEncryptionSetup(String otherUserId) async {
    try {
      final testMessage =
          'encryption_test_${DateTime.now().millisecondsSinceEpoch}';
      final encrypted = await encryptMessage(testMessage, otherUserId);
      final decrypted = await decryptMessage(encrypted, otherUserId);
      return decrypted == testMessage;
    } catch (e) {
      print('Encryption verification failed: $e');
      return false;
    }
  }

  /// Get encryption status for a user
  Future<Map<String, dynamic>> getEncryptionStatus(String userId) async {
    try {
      final hasPublicKey = await getPublicKey(userId) != null;
      final canEncrypt = hasPublicKey && _auth.currentUser != null;

      return {
        'hasPublicKey': hasPublicKey,
        'canEncrypt': canEncrypt,
        'userId': userId,
        'isInitialized': _keyPairCache.isNotEmpty,
      };
    } catch (e) {
      return {
        'hasPublicKey': false,
        'canEncrypt': false,
        'userId': userId,
        'isInitialized': false,
        'error': e.toString(),
      };
    }
  }

  /// Clear cached keys (call on logout)
  void clearCache() {
    _keyPairCache.clear();
    _sharedSecretCache.clear();
  }

  /// Encrypt message for community (uses a simpler symmetric approach)
  Future<Map<String, String>> encryptCommunityMessage(
      String message, String communityId) async {
    try {
      // For communities, we'll use a community-specific key derived from the community ID
      // This is a simplified approach - in production, you might want a more sophisticated key management
      final communityKey = await _deriveCommunityKey(communityId);

      // Convert message to bytes
      final messageBytes = utf8.encode(message);

      // Generate a random nonce
      final nonce = _algorithm.newNonce();

      // Encrypt the message
      final secretBox = await _algorithm.encrypt(
        messageBytes,
        secretKey: communityKey,
        nonce: nonce,
      );

      return {
        'encryptedData': base64Encode(secretBox.cipherText),
        'nonce': base64Encode(secretBox.nonce),
        'mac': base64Encode(secretBox.mac.bytes),
      };
    } catch (e) {
      print('Error encrypting community message: $e');
      rethrow;
    }
  }

  /// Decrypt community message
  Future<String> decryptCommunityMessage(
      Map<String, String> encryptedData, String communityId) async {
    try {
      final communityKey = await _deriveCommunityKey(communityId);

      // Extract encrypted components
      final cipherText = base64Decode(encryptedData['encryptedData']!);
      final nonce = base64Decode(encryptedData['nonce']!);
      final mac = Mac(base64Decode(encryptedData['mac']!));

      // Create secret box
      final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);

      // Decrypt the message
      final decryptedBytes = await _algorithm.decrypt(
        secretBox,
        secretKey: communityKey,
      );

      return utf8.decode(decryptedBytes);
    } catch (e) {
      print('Error decrypting community message: $e');
      return '[Decryption failed]';
    }
  }

  /// Derive a symmetric key for community encryption
  Future<SecretKey> _deriveCommunityKey(String communityId) async {
    // This is a simplified approach. In production, you'd want to:
    // 1. Store community keys securely
    // 2. Implement key rotation
    // 3. Use proper key derivation functions
    // 4. Implement member-specific encryption for better security

    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception('User not authenticated');

    // For better security, we could derive a key based on community membership
    // and implement proper key management with rotation
    final keyMaterial = utf8.encode('SwiftTalk:Community:$communityId:v1');
    final hash = await Sha256().hash(keyMaterial);

    return SecretKey(hash.bytes);
  }

  /// Encrypt file content (for future file encryption implementation)
  Future<Map<String, String>> encryptFileContent(
      List<int> fileBytes, String recipientId) async {
    try {
      final sharedSecret = await getSharedSecret(recipientId);

      // Generate a random nonce
      final nonce = _algorithm.newNonce();

      // Encrypt the file content
      final secretBox = await _algorithm.encrypt(
        fileBytes,
        secretKey: sharedSecret,
        nonce: nonce,
      );

      return {
        'encryptedData': base64Encode(secretBox.cipherText),
        'nonce': base64Encode(secretBox.nonce),
        'mac': base64Encode(secretBox.mac.bytes),
      };
    } catch (e) {
      print('Error encrypting file content: $e');
      rethrow;
    }
  }

  /// Decrypt file content (for future file encryption implementation)
  Future<List<int>> decryptFileContent(
      Map<String, String> encryptedData, String senderId) async {
    try {
      final sharedSecret = await getSharedSecret(senderId);

      // Extract encrypted components
      final cipherText = base64Decode(encryptedData['encryptedData']!);
      final nonce = base64Decode(encryptedData['nonce']!);
      final mac = Mac(base64Decode(encryptedData['mac']!));

      // Create secret box
      final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);

      // Decrypt the file content
      final decryptedBytes = await _algorithm.decrypt(
        secretBox,
        secretKey: sharedSecret,
      );

      return decryptedBytes;
    } catch (e) {
      print('Error decrypting file content: $e');
      rethrow;
    }
  }
}
