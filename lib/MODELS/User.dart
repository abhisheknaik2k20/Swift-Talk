import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String? description;
  final String email;
  final String name;
  final String uid;
  final String photoURL;
  final String status;
  final Timestamp? createdAt;
  final String username;
  final bool isCall;
  final String? fcmToken;
  final List<StatusImages>? statusImages;

  UserModel(
      {required this.email,
      required this.name,
      required this.uid,
      required this.photoURL,
      this.status = 'Online',
      this.createdAt,
      required this.username,
      this.isCall = false,
      this.fcmToken,
      this.description,
      this.statusImages});

  Map<String, dynamic> toMap() {
    try {
      return {
        'email': email,
        'name': name,
        'uid': uid,
        'photoURL': photoURL,
        'status': status,
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
        'username': username,
        'isCall': isCall,
        'fcmToken': fcmToken,
        'description': description,
        'statusImages': statusImages != null
            ? statusImages!.map((image) => image.toMap()).toList()
            : []
      };
    } catch (e) {
      print("Error in UserModel.toMap(): $e");
      return {
        'email': email,
        'name': name,
        'uid': uid,
        'photoURL': photoURL,
        'status': 'Online',
        'createdAt': FieldValue.serverTimestamp(),
        'username': username,
        'isCall': false,
        'fcmToken': null,
        'description': null,
        'statusImages': []
      };
    }
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    try {
      List<StatusImages> parsedStatusImages = [];
      if (map['statusImages'] != null) {
        if (map['statusImages'] is List) {
          final statusImagesList = map['statusImages'] as List;
          parsedStatusImages = statusImagesList.map((imageData) {
            if (imageData is Map<String, dynamic>) {
              try {
                return StatusImages.fromMap(imageData);
              } catch (e) {
                print("Error parsing individual StatusImage: $e");
                return StatusImages(
                    name: map['name'] ?? '',
                    imageUrl: '',
                    createdAt: map['createdAt'] ?? Timestamp.now());
              }
            } else if (imageData is String) {
              return StatusImages(
                  name: map['name'] ?? '',
                  imageUrl: imageData,
                  createdAt: map['createdAt'] ?? Timestamp.now());
            } else {
              return StatusImages(
                  name: map['name'] ?? '',
                  imageUrl: '',
                  createdAt: map['createdAt'] ?? Timestamp.now());
            }
          }).toList();
        } else if (map['statusImages'] is String) {
          final String statusImageStr = map['statusImages'] as String;
          if (statusImageStr.isNotEmpty) {
            parsedStatusImages = [
              StatusImages(
                  name: map['name'] ?? '',
                  imageUrl: statusImageStr,
                  createdAt: map['createdAt'] ?? Timestamp.now())
            ];
          }
        }
      }

      return UserModel(
          email: map['email'] ?? '',
          name: map['name'] ?? '',
          uid: map['uid'] ?? '',
          photoURL: map['photoURL'] ?? '',
          status: map['status'] ?? 'Offline',
          createdAt: map['createdAt'],
          username: map['username'] ?? '',
          isCall: map['isCall'] ?? false,
          fcmToken: map['fcmToken'],
          description: map['description'],
          statusImages: parsedStatusImages);
    } catch (e) {
      print("Error in UserModel.fromMap(): $e");
      return UserModel(
          email: map['email'] ?? '',
          name: map['name'] ?? '',
          uid: map['uid'] ?? '',
          photoURL: map['photoURL'] ?? '',
          username: map['username'] ?? '',
          statusImages: []);
    }
  }

  UserModel copyWith(
      {String? email,
      String? name,
      String? uid,
      String? photoURL,
      String? status,
      Timestamp? createdAt,
      String? username,
      bool? isCall,
      String? fcmToken,
      String? description,
      List<String>? statusImages}) {
    try {
      List<StatusImages>? newStatusImages;
      if (statusImages != null) {
        newStatusImages = statusImages.map((imageUrl) {
          try {
            return StatusImages(
                name: name ?? this.name,
                imageUrl: imageUrl,
                createdAt: createdAt ?? this.createdAt ?? Timestamp.now());
          } catch (e) {
            print("Error creating StatusImage in copyWith: $e");
            return StatusImages(
                name: this.name,
                imageUrl: '',
                createdAt: this.createdAt ?? Timestamp.now());
          }
        }).toList();
      }

      return UserModel(
          description: description ?? this.description,
          email: email ?? this.email,
          name: name ?? this.name,
          uid: uid ?? this.uid,
          photoURL: photoURL ?? this.photoURL,
          status: status ?? this.status,
          createdAt: createdAt ?? this.createdAt,
          username: username ?? this.username,
          isCall: isCall ?? this.isCall,
          fcmToken: fcmToken ?? this.fcmToken,
          statusImages: newStatusImages ?? this.statusImages);
    } catch (e) {
      print("Error in UserModel.copyWith(): $e");
      return UserModel(
          email: this.email,
          name: this.name,
          uid: this.uid,
          photoURL: this.photoURL,
          status: this.status,
          createdAt: this.createdAt,
          username: this.username,
          isCall: this.isCall,
          fcmToken: this.fcmToken,
          description: this.description,
          statusImages: this.statusImages);
    }
  }
}

class StatusImages {
  final String imageUrl;
  final Timestamp createdAt;
  final String? name;
  StatusImages(
      {required this.imageUrl, required this.createdAt, required this.name});
  Map<String, dynamic> toMap() {
    try {
      return {'name': name ?? '', 'imageUrl': imageUrl, 'createdAt': createdAt};
    } catch (e) {
      print("Error in StatusImages.toMap(): $e");
      return {'name': '', 'imageUrl': '', 'createdAt': Timestamp.now()};
    }
  }

  factory StatusImages.fromMap(Map<String, dynamic> map) {
    try {
      Timestamp timeStamp;
      if (map['createdAt'] is Timestamp) {
        timeStamp = map['createdAt'];
      } else if (map['createdAt'] is DateTime) {
        timeStamp = Timestamp.fromDate(map['createdAt']);
      } else {
        timeStamp = Timestamp.now();
      }
      return StatusImages(
          name: map['name'],
          imageUrl: map['imageUrl'] ?? '',
          createdAt: timeStamp);
    } catch (e) {
      print("Error in StatusImages.fromMap(): $e");
      return StatusImages(name: '', imageUrl: '', createdAt: Timestamp.now());
    }
  }
}
