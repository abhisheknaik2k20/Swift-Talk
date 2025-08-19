# swift_talk 💬

A modern, feature-rich messaging application built with Flutter that combines real-time chat, video calling, and AI-powered conversations in one seamless experience.

## 🌟 Features

### 📱 Core Messaging
- **Real-time Chat**: Instant messaging with Firebase Firestore
- **Group Communities**: Create and manage community groups
- **File Sharing**: Support for images, videos, audio, and documents
- **Status Updates**: Share status images with your contacts

### 📹 Video & Voice
- **WebRTC Video Calls**: High-quality peer-to-peer video calling
- **Audio Calls**: Crystal clear voice communication
- **Call Notifications**: Receive incoming call alerts with vibration
- **Call Controls**: Mute, camera toggle, and hang-up functionality

### 🤖 AI Integration
- **AI Chat Bot**: Powered by Google Generative AI (Gemini)
- **Markdown Support**: Rich text formatting in AI responses
- **Image Analysis**: AI can analyze and respond to shared images

### 🔐 Authentication
- **Email/Password**: Traditional authentication
- **Google Sign-In**: Quick sign-in with Google accounts
- **User Profiles**: Customizable user profiles with photos

### ☁️ Cloud Storage
- **AWS S3 Integration**: Secure file storage and retrieval
- **Automatic Upload**: Seamless file uploading to cloud storage
- **Optimized Delivery**: Fast file downloads and previews

### 🔔 Notifications
- **Push Notifications**: Firebase Cloud Messaging integration
- **Local Notifications**: In-app notification handling
- **Background Processing**: Receive notifications when app is closed

## 🏗️ Architecture

The app follows a clean architecture pattern with clear separation of concerns:

```
lib/
├── CONTROLLER/          # Business logic and services
│   ├── Call_Provider.dart
│   ├── Chat_Service.dart
│   ├── Login_Logic.dart
│   ├── NotificationService.dart
│   ├── User_Repository.dart
│   └── WebRTCLogic.dart
├── MODELS/              # Data models
│   ├── Community.dart
│   ├── Message.dart
│   ├── Message_Bubble.dart
│   ├── Notification.dart
│   └── User.dart
├── VIEWS/               # UI screens and widgets
│   ├── BlackScreen.dart
│   ├── Call_Screen.dart
│   ├── Chat_Bot.dart
│   ├── Chat_Screen.dart
│   ├── Community_Screen.dart
│   ├── First_Screen.dart
│   ├── login_screen.dart
│   ├── NotificationPage.dart
│   ├── Profile.dart
│   ├── Status_Preview.dart
│   └── WebRTC.dart
├── API_KEYS.dart        # API configuration
├── firebase_options.dart
└── main.dart
```

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: Version 3.2.3 or higher
- **Dart SDK**: Compatible version with Flutter
- **Android Studio/VS Code**: With Flutter extensions
- **Firebase Project**: For authentication and database
- **AWS Account**: For S3 storage (optional)
- **Google AI Studio**: For Gemini API access

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/swift-talk.git
   cd swift-talk
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a new Firebase project
   - Enable Authentication (Email/Password and Google)
   - Enable Firestore Database
   - Enable Cloud Messaging
   - Download `google-services.json` and place it in `android/app/`
   - Update `firebase_options.dart` with your configuration

4. **Configure API Keys**
   
   Create and configure the `lib/API_KEYS.dart` file:
   ```dart
   // AWS S3 Configuration
   const ACCESS_KEY = 'your_aws_access_key';
   const SECRET = 'your_aws_secret_key';
   const REGION = 'your_aws_region';
   const BUCKET = 'your_s3_bucket_name';

   // Google Gemini AI
   const GEMINI_API = 'your_gemini_api_key';

   // Firebase Cloud Messaging
   const SERVICE_JSON = {
     // Your Firebase service account JSON
   };
   const SCOPES = [
     'https://www.googleapis.com/auth/firebase.messaging'
   ];
   const FIREBASE_ENDPOINT = "https://fcm.googleapis.com/v1/projects/your-project-id/messages:send";
   ```

5. **Run the application**
   ```bash
   flutter run
   ```

## 🔧 Configuration

### Firebase Setup

1. **Authentication**
   - Enable Email/Password provider
   - Enable Google Sign-In provider
   - Configure OAuth consent screen

2. **Firestore Database**
   ```javascript
   // Security rules example
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
       match /chatrooms/{document=**} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```

3. **Cloud Messaging**
   - Configure notification icons
   - Set up background message handling

### AWS S3 Setup

1. Create an S3 bucket
2. Configure CORS policy
3. Set up IAM user with appropriate permissions
4. Update API keys in the configuration

## 📦 Dependencies

### Core Dependencies
- **firebase_core**: Firebase initialization
- **firebase_auth**: User authentication
- **cloud_firestore**: NoSQL database
- **firebase_messaging**: Push notifications
- **flutter_webrtc**: Video/audio calling
- **provider**: State management

### UI & UX
- **flutter_local_notifications**: Local notifications
- **vibration**: Haptic feedback
- **file_picker**: File selection
- **markdown_widget**: Rich text rendering

### Storage & Media
- **aws_storage_service**: AWS S3 integration
- **path_provider**: File system access
- **open_file**: File viewing

### AI & External Services
- **google_generative_ai**: Gemini AI integration
- **google_sign_in**: Google authentication
- **http**: Network requests

## 🔒 Security

- **Important**: Add `API_KEYS.dart` to `.gitignore` before committing
- Use environment variables for production deployments
- Implement proper Firestore security rules
- Validate user permissions for all operations

## 🎨 Theming

The app supports both light and dark themes with:
- Material Design 3 components
- Teal color scheme
- Responsive layouts
- Smooth animations

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- WebRTC for real-time communication
- Google AI for Gemini integration

## 📞 Support

For support, email support@swift_talk.com or join our community Discord server.
