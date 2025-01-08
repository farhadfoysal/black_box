import 'dart:convert';
import 'dart:ui';

import '../../utility/utils.dart';


class TaskModel {
  final String id;
  final String uid;
  final String title;
  final Color color;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime dueAt;
  final int isSynced;
  TaskModel({
    required this.id,
    required this.uid,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.dueAt,
    required this.color,
    required this.isSynced,
  });

  TaskModel copyWith({
    String? id,
    String? uid,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? dueAt,
    Color? color,
    int? isSynced,
  }) {
    return TaskModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dueAt: dueAt ?? this.dueAt,
      color: color ?? this.color,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'uid': uid,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'dueAt': dueAt.toIso8601String(),
      'hexColor': rgbToHex(color),
      'isSynced': isSynced,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] ?? '',
      uid: map['uid'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      dueAt: DateTime.parse(map['dueAt']),
      color: hexToRgb(map['hexColor']),
      isSynced: map['isSynced'] ?? 1,
    );
  }

  String toJson() => json.encode(toMap());

  factory TaskModel.fromJson(String source) =>
      TaskModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'TaskModel(id: $id, uid: $uid, title: $title, description: $description, createdAt: $createdAt, updatedAt: $updatedAt, dueAt: $dueAt, color: $color)';
  }

  @override
  bool operator ==(covariant TaskModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.uid == uid &&
        other.title == title &&
        other.description == description &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.dueAt == dueAt &&
        other.color == color &&
        other.isSynced == isSynced;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    uid.hashCode ^
    title.hashCode ^
    description.hashCode ^
    createdAt.hashCode ^
    updatedAt.hashCode ^
    dueAt.hashCode ^
    color.hashCode ^
    isSynced.hashCode;
  }
}



// // ignore_for_file: public_member_api_docs, sort_constructors_first
// import 'dart:convert';
//
// class UserModel {
//   final String id;
//   final String email;
//   final String name;
//   final String token;
//   final DateTime createdAt;
//   final DateTime updatedAt;
//   UserModel({
//     required this.id,
//     required this.email,
//     required this.name,
//     required this.token,
//     required this.createdAt,
//     required this.updatedAt,
//   });
//
//   UserModel copyWith({
//     String? id,
//     String? email,
//     String? name,
//     String? token,
//     DateTime? createdAt,
//     DateTime? updatedAt,
//   }) {
//     return UserModel(
//       id: id ?? this.id,
//       email: email ?? this.email,
//       name: name ?? this.name,
//       token: token ?? this.token,
//       createdAt: createdAt ?? this.createdAt,
//       updatedAt: updatedAt ?? this.updatedAt,
//     );
//   }
//
//   Map<String, dynamic> toMap() {
//     return <String, dynamic>{
//       'id': id,
//       'email': email,
//       'name': name,
//       'token': token,
//       'createdAt': createdAt.toIso8601String(),
//       'updatedAt': updatedAt.toIso8601String(),
//     };
//   }
//
//   factory UserModel.fromMap(Map<String, dynamic> map) {
//     return UserModel(
//       id: map['id'] ?? '',
//       email: map['email'] ?? '',
//       name: map['name'] ?? '',
//       token: map['token'] ?? '',
//       createdAt: DateTime.parse(map['createdAt']),
//       updatedAt: DateTime.parse(map['updatedAt']),
//     );
//   }
//
//   String toJson() => json.encode(toMap());
//
//   factory UserModel.fromJson(String source) =>
//       UserModel.fromMap(json.decode(source) as Map<String, dynamic>);
//
//   @override
//   String toString() {
//     return 'UserModel(id: $id, email: $email, name: $name, token: $token, createdAt: $createdAt, updatedAt: $updatedAt)';
//   }
//
//   @override
//   bool operator ==(covariant UserModel other) {
//     if (identical(this, other)) return true;
//
//     return other.id == id &&
//         other.email == email &&
//         other.name == name &&
//         other.token == token &&
//         other.createdAt == createdAt &&
//         other.updatedAt == updatedAt;
//   }
//
//   @override
//   int get hashCode {
//     return id.hashCode ^
//     email.hashCode ^
//     name.hashCode ^
//     token.hashCode ^
//     createdAt.hashCode ^
//     updatedAt.hashCode;
//   }
// }