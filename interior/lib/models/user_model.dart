import 'package:equatable/equatable.dart';

/// Maps to root/users/{userId} (Sec. 24)
class UserModel extends Equatable {
  final String uid;
  final String name;
  final String email;
  final String? profileImage;
  final int createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.profileImage,
    required this.createdAt,
  });

  factory UserModel.fromMap(String uid, Map<dynamic, dynamic> map) {
    return UserModel(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      profileImage: map['profileImage'] as String?,
      createdAt: map['createdAt'] as int? ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      if (profileImage != null) 'profileImage': profileImage,
      'createdAt': createdAt,
    };
  }

  UserModel copyWith({String? name, String? profileImage}) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [uid, name, email, profileImage, createdAt];
}
