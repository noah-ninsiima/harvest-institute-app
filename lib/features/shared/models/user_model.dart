import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { student, instructor, admin }

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final UserRole role;
  final String contact;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    required this.contact,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'role': role.name,
      'contact': contact,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.student,
      ),
      contact: map['contact'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
