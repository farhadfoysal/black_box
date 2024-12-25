class Userr {
  final String email;
  final String name;
  final String userId;
  final String phoneNumber;

  Userr({
    required this.email,
    required this.name,
    required this.userId,
    required this.phoneNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'userId': userId,
      'phoneNumber': phoneNumber,
    };
  }

  factory Userr.fromMap(Map<String, dynamic> map) {
    return Userr(
      email: map['email'],
      name: map['name'],
      userId: map['userId'],
      phoneNumber: map['phoneNumber'],
    );
  }
}
