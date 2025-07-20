import 'package:SwiftTalk/CONTROLLER/Call_Provider.dart';
import 'package:SwiftTalk/CONTROLLER/Login_Logic.dart';
import 'package:SwiftTalk/CONTROLLER/Native_Implement.dart';
import 'package:SwiftTalk/CONTROLLER/NotificationService.dart';
import 'package:SwiftTalk/CONTROLLER/User_Repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:SwiftTalk/firebase_options.dart';
import 'package:SwiftTalk/VIEWS/BlackScreen.dart';
import 'package:SwiftTalk/VIEWS/Login_Screen.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;
  ThemeData get currentTheme => _isDarkMode ? _darkTheme : _lightTheme;

  final ThemeData _darkTheme = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      appBarTheme: AppBarTheme(color: Colors.teal.shade500));

  final ThemeData _lightTheme = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      appBarTheme: AppBarTheme(color: Colors.teal.shade500));

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setDarkMode(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
  print("Handling a background message: ${message.messageId}");
  if (message.data.containsKey('type') && message.data['type'] == 'VideoCall') {
    print("Showing video call notification");
    await NotificationService.showVideoCallNotification(message);
  } else {
    print("Showing normal notification");
    await NotificationService.showFlutterNotification(message);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
  await NotificationService.initialize();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: true,
      carPlay: true,
      criticalAlert: true);

  runApp(MultiProvider(providers: [
    Provider<UserRepository>(create: (_) => UserRepository()),
    ChangeNotifierProxyProvider<UserRepository, CallStatusProvider>(
        create: (context) => CallStatusProvider(context.read<UserRepository>()),
        update: (context, userRepository, previous) => previous!),
    ChangeNotifierProvider(create: (_) => AuthLoadingProvider()),
    ChangeNotifierProvider(create: (_) => ThemeProvider())
  ], child: MyApp()));
  Vibration.cancel();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  UserRepository userRepository = UserRepository();
  FirebaseAuth auth = FirebaseAuth.instance;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupMessaging();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      super.didChangeAppLifecycleState(state);
      String status = state == AppLifecycleState.resumed
          ? 'Online'
          : 'Last seen ${CustomDateFormat.formatDateTime(DateTime.now())}';
      if (auth.currentUser?.uid != null) {
        userRepository.updateUserStatus(auth.currentUser!.uid, status);
      }
      Vibration.cancel();
      _setupMessaging();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (auth.currentUser?.uid != null) {
        userRepository.updateUserStatus(auth.currentUser!.uid,
            'Last seen ${CustomDateFormat.formatDateTime(DateTime.now())}');
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Vibration.cancel();
    super.dispose();
  }

  Future<void> _setupMessaging() async {
    UserRepository userRepository = UserRepository();
    await FirebaseMessaging.instance.subscribeToTopic('all_users');
    FirebaseMessaging.instance.onTokenRefresh
        .listen((newToken) => userRepository.updateFcmToken(newToken));
  }

  @override
  Widget build(BuildContext context) => Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) => MaterialApp(
            navigatorKey: navigatorKey,
            title: 'SwiftTalk',
            theme: themeProvider.currentTheme,
            debugShowCheckedModeBanner: false,
            home: Consumer<AuthLoadingProvider>(
                builder: (context, loading, child) {
              if (loading.isLoading) {
                return Scaffold(
                    body: Center(
                        child: CircularProgressIndicator(color: Colors.teal)));
              }
              return StreamBuilder(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snapshot) => switch (snapshot) {
                        AsyncSnapshot(hasData: true) => const BlackScreen(),
                        _ => const LoginSignupScreen()
                      });
            }),
          ));
}
