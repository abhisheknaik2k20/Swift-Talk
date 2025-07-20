import 'package:SwiftTalk/MODELS/User.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Community {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final int memberCount;
  final DateTime lastActivity;
  final String createdBy;
  final DateTime createdAt;
  final List<UserModel> members;
  Community(
      {required this.id,
      required this.name,
      required this.description,
      required this.imageUrl,
      required this.memberCount,
      required this.lastActivity,
      required this.createdBy,
      required this.createdAt,
      required this.members});
  factory Community.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    DateTime lastActivity;
    if (data['lastActivity'] != null) {
      lastActivity = (data['lastActivity'] as Timestamp).toDate();
    } else {
      lastActivity = DateTime.now();
    }
    DateTime createdAt;
    if (data['createdAt'] != null) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    } else {
      createdAt = DateTime.now();
    }

    List<UserModel> members = [];
    if (data['members'] != null && data['members'] is List) {
      members = (data['members'] as List).map((memberData) {
        return UserModel.fromMap(memberData);
      }).toList();
    }

    return Community(
        id: doc.id,
        name: data['name'] ?? 'Unknown Community',
        description: data['description'] ?? 'No description',
        imageUrl: data['imageUrl'] ?? 'default_image_url_here',
        memberCount: data['memberCount'] ?? 0,
        lastActivity: lastActivity,
        createdBy: data['createdBy'] ?? '',
        createdAt: createdAt,
        members: members);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'memberCount': memberCount,
      'lastActivity': Timestamp.fromDate(lastActivity),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'members': members.map((user) => user.toMap()).toList()
    };
  }

  Community copyWith(
      {String? name,
      String? description,
      String? imageUrl,
      int? memberCount,
      DateTime? lastActivity,
      String? createdBy,
      DateTime? createdAt,
      List<UserModel>? members}) {
    return Community(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        imageUrl: imageUrl ?? this.imageUrl,
        memberCount: memberCount ?? this.memberCount,
        lastActivity: lastActivity ?? this.lastActivity,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt ?? this.createdAt,
        members: members ?? this.members);
  }

  Community addMember(UserModel user) {
    if (members.any((member) => member.uid == user.uid)) return this;

    List<UserModel> updatedMembers = List.from(members)..add(user);
    return copyWith(
        members: updatedMembers,
        memberCount: updatedMembers.length,
        lastActivity: DateTime.now());
  }

  Community removeMember(String userId) {
    List<UserModel> updatedMembers =
        members.where((member) => member.uid != userId).toList();
    return copyWith(
        members: updatedMembers,
        memberCount: updatedMembers.length,
        lastActivity: DateTime.now());
  }
}
