class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.publicKey,
    this.hasKeyBundle = false,
  });

  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? publicKey;
  final bool hasKeyBundle;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      photoUrl: json['photoUrl'] as String?,
      publicKey: json['publicKey'] as String?,
      hasKeyBundle: json['hasKeyBundle'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'publicKey': publicKey,
        'hasKeyBundle': hasKeyBundle,
      };

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    String? publicKey,
    bool? hasKeyBundle,
  }) {
    return UserModel(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      publicKey: publicKey ?? this.publicKey,
      hasKeyBundle: hasKeyBundle ?? this.hasKeyBundle,
    );
  }
}
