class UserModel {
  final String uid;
  final String name;
  final String about;
  final String profilePic;
  final String phone;

  UserModel({
    required this.uid,
    required this.name,
    required this.about,
    required this.profilePic,
    required this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'about': about,
      'profilePic': profilePic,
      'phone': phone,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      about: map['about'] ?? '',
      profilePic: map['profilePic'] ?? '',
      phone: map['phone'] ?? '',
    );
  }
}