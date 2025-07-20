import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:SwiftTalk/MODELS/Message.dart' as msg;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:vibration/vibration.dart';
import 'package:SwiftTalk/API_KEYS.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;

class PushNotification {
  static Future<String> getAccessToken() async {
    final serviceAccountJSON = SERVICE_JSON;
    List<String> scopes = SCOPES;
    http.Client client = await auth.clientViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(serviceAccountJSON), scopes);

    auth.AccessCredentials credentials =
        await auth.obtainAccessCredentialsViaServiceAccount(
            auth.ServiceAccountCredentials.fromJson(serviceAccountJSON),
            scopes,
            client);
    client.close();
    return credentials.accessToken.data;
  }

  static sendNotification(
      {required String token,
      required String title,
      required String msg,
      required String type}) async {
    final String serverKey = await getAccessToken();
    String endPointFirebaseCloudMessaging = FIREBASE_ENDPOINT;
    final Map<String, dynamic> message = {
      'message': {
        'token': token,
        'data': {
          'title': title,
          'body': msg,
          'type': type,
          'callerName': FirebaseAuth.instance.currentUser?.displayName ?? ''
        }
      }
    };
    final http.Response response = await http.post(
        Uri.parse(endPointFirebaseCloudMessaging),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $serverKey'
        },
        body: jsonEncode(message));
    if (response.statusCode == 200) {
      print("Notification Sent Successfully");
    } else {
      print("Failed to send notification");
    }
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  static const platform = MethodChannel('app.channel.shared.data');
  static const AndroidNotificationChannel _callChannel =
      AndroidNotificationChannel(
          'channel_no_6', 'This sends Video Call Notifications',
          description:
              'This channel is used for incoming video call notifications.',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('sound'),
          playSound: true,
          enableVibration: true,
          showBadge: true,
          enableLights: true);
  static const AndroidNotificationChannel _standardChannel =
      AndroidNotificationChannel(
          'channel_no_4', 'High Importance Notifications',
          description: 'This channel is used for important notifications.',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          showBadge: true,
          enableLights: true);
  static const AndroidNotificationChannel _downloadChannel =
      AndroidNotificationChannel('channel_no_5', 'File Downloads',
          description: 'Notifications for file downloads',
          importance: Importance.low,
          playSound: false,
          enableVibration: false,
          showBadge: true,
          enableLights: false);
  static final Set<String> _displayedNotifications = {};
  static Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final AndroidInitializationSettings initializtionSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      final DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings();
      final InitializationSettings initializationSettings =
          InitializationSettings(
              android: initializtionSettingsAndroid,
              iOS: initializationSettingsIOS);
      await _notificationsPlugin.initialize(initializationSettings,
          onDidReceiveNotificationResponse:
              (NotificationResponse response) async {
        if (response.payload != null) {
          if (response.payload!.startsWith('{') &&
              response.payload!.endsWith('}')) {
            _handleNotificationAction(response);
          } else {
            await OpenFile.open(response.payload!);
          }
        }
      });
      await _createNotificationChannels();
      await _configureFCM();
      _isInitialized = true;
      debugPrint('Notification and download service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
    }
  }

  static Future<void> _createNotificationChannels() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(_standardChannel);
        await androidPlugin.createNotificationChannel(_callChannel);
        await androidPlugin.createNotificationChannel(_downloadChannel);
        await requestRequiredPermissions();
      }
    } catch (e) {
      debugPrint('Error creating notification channels: $e');
    }
  }

  static Future<bool> requestRequiredPermissions() async {
    if (!Platform.isAndroid) return true;
    try {
      final notificationStatus = await Permission.notification.request();
      final cameraStatus = await Permission.camera.request();
      final microphoneStatus = await Permission.microphone.request();
      final DeviceInfoPlugin info = DeviceInfoPlugin();
      final AndroidDeviceInfo androidInfo = await info.androidInfo;
      bool storageGranted = false;
      try {
        final int androidVersion =
            int.parse(androidInfo.version.release.split('.').first);
        if (androidVersion >= 13) {
          final request = await [
            Permission.videos,
            Permission.photos,
            Permission.audio
          ].request();
          storageGranted = request.values
              .every((status) => status == PermissionStatus.granted);
        } else {
          final status = await Permission.storage.request();
          storageGranted = status.isGranted;
        }
      } catch (e) {
        debugPrint('Error parsing Android version: $e');
        final status = await Permission.storage.request();
        storageGranted = status.isGranted;
      }
      final bool allCriticalPermissionsGranted = notificationStatus.isGranted &&
          cameraStatus.isGranted &&
          microphoneStatus.isGranted;
      if (!allCriticalPermissionsGranted || !storageGranted) {
        debugPrint('Not all permissions granted. Opening app settings.');
        await openAppSettings();
      }
      return allCriticalPermissionsGranted && storageGranted;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return false;
    }
  }

  static Future<void> _configureFCM() async {
    try {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
              alert: false, badge: false, sound: false);
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {});
    } catch (e) {
      debugPrint('Error configuring FCM: $e');
    }
  }

  static void _handleNotificationAction(NotificationResponse response) {
    try {
      debugPrint(
          'Notification action: ${response.actionId}, payload: ${response.payload}');
      if (response.payload == null) return;
      if (response.actionId != 'missed') {
        _notificationsPlugin.cancel(response.id!);
      }
    } catch (e) {
      debugPrint('Error handling notification action: $e');
    }
  }

  static Future<void> showVideoCallNotification(RemoteMessage message) async {
    try {
      String notificationKey = Uuid().v4();
      String callId = notificationKey;
      _displayedNotifications.add(notificationKey);
      Future.delayed(const Duration(minutes: 1), () {
        _displayedNotifications.remove(notificationKey);
      });
      final String callerName = message.data['callerName'] ?? 'Unknown';
      final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      _startCallVibration();
      final List<AndroidNotificationAction> actions = [
        const AndroidNotificationAction('accept', 'Accept',
            showsUserInterface: true),
        const AndroidNotificationAction('decline', 'Decline')
      ];
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(_callChannel.id, _callChannel.name,
              audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
              channelDescription: _callChannel.description,
              importance: Importance.max,
              priority: Priority.max,
              ongoing: true,
              autoCancel: false,
              fullScreenIntent: true,
              category: AndroidNotificationCategory.call,
              actions: actions,
              playSound: true,
              sound: const RawResourceAndroidNotificationSound('sound'),
              enableVibration: true,
              vibrationPattern:
                  Int64List.fromList([0, 1000, 500, 1000, 500, 1000]));

      final NotificationDetails notificationDetails =
          NotificationDetails(android: androidDetails);
      await _notificationsPlugin.show(notificationId, 'Incoming Video Call',
          'Video call from $callerName', notificationDetails,
          payload: json.encode(
              {...message.data, 'type': 'video_call', 'callId': callId}));
      debugPrint('Video call notification displayed successfully');
    } catch (e) {
      debugPrint('Error showing video call notification: $e');
      _showFallbackNotification(message);
    }
  }

  static Future<void> _showFallbackNotification(RemoteMessage message) async {
    try {
      final RemoteNotification? notification = message.notification;
      final String callerName = message.data['callerName'] ?? 'Unknown';
      final String callId = message.data['callId'] ?? '';
      final String notificationKey = 'fallback_${callId}';
      if (_displayedNotifications.contains(notificationKey)) {
        return;
      }
      _displayedNotifications.add(notificationKey);

      await _notificationsPlugin.show(
          notification.hashCode,
          'Incoming Video Call',
          'Video call from $callerName',
          NotificationDetails(
              android: AndroidNotificationDetails(
                  _callChannel.id, _callChannel.name,
                  channelDescription: _callChannel.description,
                  importance: Importance.max,
                  priority: Priority.max,
                  sound: const RawResourceAndroidNotificationSound('sound'),
                  playSound: true)),
          payload: json.encode(message.data));
    } catch (e) {
      debugPrint('Error showing fallback notification: $e');
    }
  }

  static void _startCallVibration() async {
    try {
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(pattern: [500, 1000, 500, 1000], repeat: 1);
      }
    } catch (e) {
      debugPrint('Error starting vibration: $e');
    }
  }

  static void stopCallVibration() {
    try {
      Vibration.cancel();
    } catch (e) {
      debugPrint('Error stopping vibration: $e');
    }
  }

  static Future<void> showFlutterNotification(RemoteMessage message) async {
    try {
      print("This is A Notification received: ${message.data['title']}");
      String uniqueContent = "${message.data['title']}_${message.data['body']}";
      String notificationKey =
          'standard_${message.messageId ?? uniqueContent.hashCode}';

      if (_displayedNotifications.contains(notificationKey)) {
        debugPrint('Preventing duplicate standard notification');
        return;
      }
      _displayedNotifications.add(notificationKey);
      Future.delayed(const Duration(minutes: 5), () {
        _displayedNotifications.remove(notificationKey);
      });
      if (_displayedNotifications.length > 100) {
        final toRemove = _displayedNotifications
            .take(_displayedNotifications.length - 50)
            .toList();
        toRemove.forEach(_displayedNotifications.remove);
      }

      await _notificationsPlugin.show(
          message.data.hashCode,
          message.data['title'],
          message.data['body'],
          NotificationDetails(
              android: AndroidNotificationDetails(
                  _standardChannel.id, _standardChannel.name,
                  channelDescription: _standardChannel.description,
                  importance: Importance.max,
                  priority: Priority.max,
                  playSound: true,
                  enableVibration: true,
                  autoCancel: true)),
          payload: json.encode(message.data));
    } catch (e) {
      debugPrint('Error showing standard notification: $e');
    }
  }

  Future<String?> downloadFile(msg.Message message, String chatRoomID,
      {String? customDirectory}) async {
    debugPrint('Downloading from URL: ${message.message}');
    try {
      if (!_isInitialized) await initialize();

      bool permissionGranted = await requestRequiredPermissions();
      if (!permissionGranted) {
        debugPrint("Storage permission denied by user");
        return null;
      }
      final int notificationId = Random().nextInt(1000);
      final fileName = path.basename(Uri.parse(message.message).path);
      String filePath;
      if (customDirectory != null) {
        final directory = Directory(customDirectory);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        filePath = path.join(customDirectory, fileName);
      } else {
        Directory? appDir;
        if (Platform.isAndroid) {
          try {
            appDir = await getExternalStorageDirectory();
            appDir = Directory("${appDir?.path}/$chatRoomID/${message.type}");
            if (!await appDir.exists()) {
              await appDir.create(recursive: true);
            }
          } catch (e) {
            debugPrint("Failed to get external storage directory: $e");
          }
          filePath = path.join(appDir?.path ?? '', fileName);
        } else {
          appDir = await getApplicationDocumentsDirectory();
          filePath = path.join(appDir.path, fileName);
        }
      }

      await _showProgressNotification(
          notificationId: notificationId,
          title: 'Downloading $fileName',
          progress: 0,
          maxProgress: 100);

      final headResponse = await http.head(Uri.parse(message.message));
      final fileSize = int.parse(headResponse.headers['content-length'] ?? '0');
      final request = http.Request('GET', Uri.parse(message.message));
      final response = await http.Client().send(request);

      if (response.statusCode == 200) {
        final file = File(filePath);
        final downloadedBytes = <int>[];
        int totalBytes = 0;

        await for (final bytes in response.stream) {
          downloadedBytes.addAll(bytes);
          totalBytes += bytes.length;
          final progress =
              fileSize > 0 ? (totalBytes / fileSize * 100).round() : 0;
          await _showProgressNotification(
              notificationId: notificationId,
              title: 'Downloading $fileName',
              progress: progress,
              maxProgress: 100);
        }
        await file.writeAsBytes(downloadedBytes);
        debugPrint('File downloaded successfully to: $filePath');
        await _notificationsPlugin.cancel(notificationId);
        await _showCompletionNotification(
            notificationId: notificationId,
            title: 'Download Complete',
            body: '$fileName has been downloaded',
            payload: filePath);
        return filePath;
      } else {
        debugPrint('Failed to download file: ${response.statusCode}');
        await _notificationsPlugin.cancel(notificationId);
        await _showErrorNotification(
            notificationId: notificationId,
            title: 'Download Failed',
            body: 'Failed to download $fileName');
        return null;
      }
    } catch (e) {
      debugPrint('Error downloading file: $e');
      final int errorNotificationId = Random().nextInt(1000);
      await _showErrorNotification(
          notificationId: errorNotificationId,
          title: 'Download Error',
          body:
              'Error downloading file: ${e.toString().substring(0, min(50, e.toString().length))}');
      return null;
    }
  }

  Future<void> _showProgressNotification(
      {required int notificationId,
      required String title,
      required int progress,
      required int maxProgress}) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(_downloadChannel.id, _downloadChannel.name,
            channelDescription: _downloadChannel.description,
            importance: Importance.low,
            priority: Priority.low,
            onlyAlertOnce: true,
            showProgress: true,
            maxProgress: maxProgress,
            progress: progress,
            ongoing: true,
            autoCancel: false);

    final NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(notificationId, title,
        'Download in progress: $progress%', notificationDetails);
  }

  Future<void> _showCompletionNotification(
      {required int notificationId,
      required String title,
      required String body,
      required String payload}) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(_downloadChannel.id, _downloadChannel.name,
            channelDescription: _downloadChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            autoCancel: true);

    final NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
        notificationId, title, body, notificationDetails,
        payload: payload);
  }

  Future<void> _showErrorNotification(
      {required int notificationId,
      required String title,
      required String body}) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(_downloadChannel.id, _downloadChannel.name,
            channelDescription: _downloadChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            autoCancel: true);

    final NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
        notificationId, title, body, notificationDetails);
  }
}
