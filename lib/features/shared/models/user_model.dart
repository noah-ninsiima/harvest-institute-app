import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { student, instructor, admin }

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String username; // Added username
  final UserRole role;
  final String contact;
  final String? photoUrl; // Added photoUrl
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.username,
    required this.role,
    required this.contact,
    this.photoUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'username': username,
      'role': role.name,
      'contact': contact,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      username: map['username'] ?? '', // Default empty if missing
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.student,
      ),
      contact: map['contact'] ?? '',
      photoUrl: map['photoUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
