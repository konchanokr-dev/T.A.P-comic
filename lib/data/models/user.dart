class User {
  final int? id;
  final String uuid;       
  final String name;    
  final String password;   

  const User({
    this.id,
    required this.uuid,
    required this.name,
    required this.password,
  });

  factory User.fromApi(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      uuid: map['uuid'] as String,
      name: map['name'] as String,
      password: '', 
    );
  }

  factory User.fromPrefs(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      uuid: map['uuid'] as String,
      name: map['name'] as String,
      password: map['password'] as String,
    );
  }

  static fromJson(json) {}
}

   
  
