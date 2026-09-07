/// Authenticated user. Shared across all flavors — business content is
/// identical regardless of branding. Mirrors the `user` object returned by
/// `/auth/login`, `/auth/register` and `/me`.
class UserModel {
  final String id;
  final String name;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String countryCode;
  final bool emailVerified;
  final bool twoFactorEnabled;

  /// Bearer token. Present after login/register; empty when the model is
  /// rehydrated from `/me` (the token is kept in secure storage separately).
  final String token;

  const UserModel({
    required this.id,
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone = '',
    this.countryCode = '',
    this.emailVerified = false,
    this.twoFactorEnabled = false,
    this.token = '',
  });

  /// Display name for the UI — falls back to the email local-part.
  String get displayName =>
      name.isNotEmpty ? name : (firstName.isNotEmpty ? firstName : email.split('@').first);

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        firstName: json['first_name'] as String? ?? '',
        lastName: json['last_name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        countryCode: json['country_code'] as String? ?? '',
        emailVerified: json['email_verified'] as bool? ?? false,
        twoFactorEnabled: json['two_factor_enabled'] as bool? ?? false,
        token: json['token'] as String? ?? '',
      );

  UserModel copyWith({String? token}) => UserModel(
        id: id,
        name: name,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        countryCode: countryCode,
        emailVerified: emailVerified,
        twoFactorEnabled: twoFactorEnabled,
        token: token ?? this.token,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'country_code': countryCode,
        'email_verified': emailVerified,
        'two_factor_enabled': twoFactorEnabled,
        'token': token,
      };
}
