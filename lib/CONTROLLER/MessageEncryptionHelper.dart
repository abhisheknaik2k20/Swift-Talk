import 'package:SwiftTalk/CONTROLLER/EncryptionService.dart';
import 'package:SwiftTalk/MODELS/Message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessageEncryptionHelper {
  static final EncryptionService _encryptionService = EncryptionService();
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static Future<Message> createEncryptedMessage({
    required String messageText,
    required String receiverId,
    String type = 'text',
  }) async {
    print(
        '🔐 Attempting to encrypt message: "$messageText" for receiver: $receiverId');

    try {
      // Initialize encryption if not already done
      await _encryptionService.initializeEncryption();

      final encryptedData =
          await _encryptionService.encryptMessage(messageText, receiverId);

      print('🔐 Message encrypted successfully');

      return Message(
        senderName: _auth.currentUser?.displayName ?? '',
        senderId: _auth.currentUser!.uid,
        senderEmail: _auth.currentUser?.email ?? '',
        receiverId: receiverId,
        message: '[Encrypted Message]', // Placeholder text
        timestamp: Timestamp.now(),
        type: type,
        isEncrypted: true,
        encryptedData: encryptedData,
      );
    } catch (e) {
      print('Encryption failed, sending unencrypted message: $e');
      return Message(
        senderName: _auth.currentUser?.displayName ?? '',
        senderId: _auth.currentUser!.uid,
        senderEmail: _auth.currentUser?.email ?? '',
        receiverId: receiverId,
        message: messageText,
        timestamp: Timestamp.now(),
        type: type,
        isEncrypted: false,
      );
    }
  }

  /// Create an encrypted message for community chat
  static Future<Message> createEncryptedCommunityMessage({
    required String messageText,
    required String communityId,
    String type = 'text',
  }) async {
    try {
      final encryptedData = await _encryptionService.encryptCommunityMessage(
          messageText, communityId);

      return Message(
        senderName: _auth.currentUser?.displayName ?? '',
        senderId: _auth.currentUser!.uid,
        senderEmail: _auth.currentUser?.email ?? '',
        receiverId: communityId,
        message: '[Encrypted Message]', // Placeholder text
        timestamp: Timestamp.now(),
        type: type,
        isEncrypted: true,
        encryptedData: encryptedData,
      );
    } catch (e) {
      // Fallback to unencrypted message if encryption fails
      print('Community encryption failed, sending unencrypted message: $e');
      return Message(
        senderName: _auth.currentUser?.displayName ?? '',
        senderId: _auth.currentUser!.uid,
        senderEmail: _auth.currentUser?.email ?? '',
        receiverId: communityId,
        message: messageText,
        timestamp: Timestamp.now(),
        type: type,
        isEncrypted: false,
      );
    }
  }

  /// Decrypt a message for display
  static Future<String> getDecryptedMessageText(Message message,
      {String? communityId}) async {
    print('Attempting to decrypt message from ${message.senderId}');

    // If message is not encrypted, return as is
    if (!message.isEncrypted || message.encryptedData == null) {
      print('Message is not encrypted, returning as-is');
      return message.message;
    }

    try {
      String decryptedText;
      if (communityId != null) {
        // Community message decryption
        print('Decrypting community message for community: $communityId');
        decryptedText = await _encryptionService.decryptCommunityMessage(
          message.encryptedData!,
          communityId,
        );
      } else {
        // Direct message decryption
        print('Decrypting direct message from: ${message.senderId}');
        decryptedText = await _encryptionService.decryptMessage(
          message.encryptedData!,
          message.senderId,
        );
      }

      print(' Message decrypted successfully: "$decryptedText"');
      return decryptedText;
    } catch (e) {
      print(' Failed to decrypt message: $e');
      return '[Failed to decrypt message]';
    }
  }

  /// Initialize encryption for the current user
  static Future<void> initializeUserEncryption() async {
    await _encryptionService.initializeEncryption();
  }

  /// Clear encryption cache (call on logout)
  static void clearEncryptionCache() {
    _encryptionService.clearCache();
  }

  /// Check if encryption is available for a specific user
  static Future<bool> isEncryptionAvailable(String userId) async {
    try {
      final publicKey = await _encryptionService.getPublicKey(userId);
      return publicKey != null;
    } catch (e) {
      return false;
    }
  }

  /// Get encryption status for current conversation
  static Future<Map<String, dynamic>> getConversationEncryptionStatus(
      String otherUserId) async {
    try {
      final status = await _encryptionService.getEncryptionStatus(otherUserId);
      return status;
    } catch (e) {
      return {
        'hasPublicKey': false,
        'canEncrypt': false,
        'error': e.toString(),
      };
    }
  }

  /// Verify encryption setup between two users
  static Future<bool> verifyEncryptionSetup(String otherUserId) async {
    try {
      return await _encryptionService.verifyEncryptionSetup(otherUserId);
    } catch (e) {
      print('Encryption verification failed: $e');
      return false;
    }
  }

  /// Create encrypted file message (placeholder for future implementation)
  static Future<FileMessage> createEncryptedFileMessage({
    required String fileUrl,
    required String filename,
    required String receiverId,
    required String type,
    required int fileSize,
  }) async {
    // Note: This is a placeholder. Full file encryption would require:
    // 1. Downloading the file
    // 2. Encrypting the file content
    // 3. Uploading the encrypted file
    // 4. Storing encryption metadata

    print(
        'File encryption not yet implemented. Sending unencrypted file reference.');

    return FileMessage(
      senderName: _auth.currentUser?.displayName ?? '',
      senderId: _auth.currentUser!.uid,
      senderEmail: _auth.currentUser?.email ?? '',
      receiverId: receiverId,
      message: fileUrl,
      timestamp: Timestamp.now(),
      filename: filename,
      type: type,
      fileSize: fileSize,
      isEncrypted: false, // Set to false until file encryption is implemented
    );
  }
}
