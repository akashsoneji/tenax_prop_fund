import 'user_model.dart';

/// What `POST /auth/login` resolved to.
///
/// The endpoint answers `200 success: true` for BOTH a completed login and a
/// two-factor challenge, so the caller has to branch on the payload rather than
/// on the status code:
/// - [user] set → fully authenticated, the token can be persisted;
/// - [challengeToken] set → the account has 2FA on and the user must enter a
///   code before any token exists.
class LoginOutcome {
  const LoginOutcome.authenticated(UserModel this.user) : challengeToken = null;

  const LoginOutcome.twoFactor(String this.challengeToken) : user = null;

  final UserModel? user;
  final String? challengeToken;

  bool get requiresTwoFactor => challengeToken != null;
}
