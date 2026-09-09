/// Central registry of every REST path still used by the app.
///
/// The mobile app now talks to only a handful of live endpoints:
/// - Auth (`POST /auth/*`) — real login/register/logout that mints the bearer
///   token every other request depends on.
/// - The Inertia portal routes (Dashboard, Accounts, Account detail, Referral)
///   are called by their absolute `/app/...` URL through
///   `ApiClient.getInertiaProps`, NOT through the constants below — so they do
///   not appear here.
///
/// Every remaining feature screen (KYC, billing, rewards, payout methods,
/// notifications, offers, competitions, certificates, challenge) runs on static
/// demo data and makes no network call, so their old paths were removed.
///
/// Paths are relative to `FlavorConfig.apiBaseUrl`.
abstract class ApiEndpoints {
  // Auth
  static const register = '/auth/register';
  static const login = '/auth/login';
  static const forgotPassword = '/auth/forgot-password';
  static const logout = '/auth/logout';

  /// Home dashboard snapshot (KPIs, live accounts, health, activity). This is
  /// the one live `/api/v1` data screen; every other portal screen uses the
  /// Inertia `/app/...` routes or static demo data.
  static const dashboard = '/dashboard';

  /// Trading accounts list for the "Account Center" screen. Standard
  /// `{success, message, data[], meta}` envelope. Query params: `status`
  /// (all | active | breached | passed | raw-status) and `phase`
  /// (all | evaluation | verification | funded | breached).
  static const accounts = '/accounts';

  /// Single trading account overview. Standard `{success, message, data}`
  /// envelope where `data` carries the account fields plus nested `stats`,
  /// `objectives`, `credentials`, `overview` and `chart`.
  static String accountDetail(Object id) => '/accounts/$id';
}
