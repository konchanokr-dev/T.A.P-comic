class UserModel {
  final String name;
  final String uuid;

  UserModel({
    required this.name,
    required this.uuid,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'] ?? "user",
      uuid: json['uuid'] ?? "",
    );
  }
}