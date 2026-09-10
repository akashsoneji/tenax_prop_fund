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

  // ---------------------------------------------------------------------------
  // Profile & KYC
  // ---------------------------------------------------------------------------
  /// User profile. `GET` returns the profile envelope; `PUT` updates name,
  /// email, phone, country_code, city.
  static const profile = '/profile';

  /// KYC verification status. `GET` returns the standard envelope whose `data`
  /// describes the user's document/verification state.
  static const kyc = '/kyc';

  /// KYC document upload (`POST`, multipart). Fields: `id_document`,
  /// `id_document_back`, `proof_of_address`, `proof_of_address_back`.
  static const kycDocuments = '/kyc/documents';

  /// Home dashboard snapshot (KPIs, live accounts, health, activity). This is
  /// the one live `/api/v1` data screen; every other portal screen uses the
  /// Inertia `/app/...` routes or static demo data.
  static const dashboard = '/dashboard';

  /// Referral summary for the Home "Refer & earn" card. Standard
  /// `{success, message, data}` envelope where `data` nests `referral`
  /// (code/share_url) and `stats` (referrals count, to_be_paid).
  static const referrals = '/growth/referrals';

  /// Trading accounts list for the "Account Center" screen. Standard
  /// `{success, message, data[], meta}` envelope. Query params: `status`
  /// (all | active | breached | passed | raw-status) and `phase`
  /// (all | evaluation | verification | funded | breached).
  static const accounts = '/accounts';

  /// Single trading account overview. Standard `{success, message, data}`
  /// envelope where `data` carries the account fields plus nested `stats`,
  /// `objectives`, `credentials`, `overview` and `chart`.
  static String accountDetail(Object id) => '/accounts/$id/overview';

  /// Platform & credentials for a single account. Standard `{success, data}`
  /// envelope; `data.account.credentials` holds login/server/passwords and
  /// `data.platform_locked` flags a locked platform. `reveal=true` unmasks the
  /// passwords server-side.
  static String accountPlatform(Object id, {bool reveal = false}) =>
      '/accounts/$id/platform?reveal=$reveal';

  /// Reset quote for a single account. Standard `{success, data}` envelope with
  /// `data.account` and `data.quote` (pricing + eligibility). POST to the same
  /// path with `{payment_method_id}` to purchase a reset.
  static String accountReset(Object id) => '/accounts/$id/reset';



  /// Live tradable instruments list (parsed into `Instrument`s).
  static const instruments = '/instruments';

  /// Instruments scoped to a single trading [account].
  static String instrumentsByAccount(String account) =>
      '/instruments/$account';

  // ---------------------------------------------------------------------------
  // Trade / Positions
  // ---------------------------------------------------------------------------
  // Ported from the white_label app (`lib/constants/api_const.dart`), where the
  // same backend exposes these under a `user/trade/...` prefix on its ajax base.
  // tenax's REST base already carries `/api/v1`, and every existing path here is
  // root-relative (`/accounts`, `/dashboard`), so the trade paths follow that
  // convention below.
  //
  // These trade endpoints live on the WEB host under `/api/user/trade/...`
  // (verified against the live pipzefunded.com portal), NOT the `/api/v1`
  // mobile base — the mobile API v1 collection has no trade routes. They are
  // therefore called via ApiClient.postWeb / getWeb, which target the root host.
  static const placeOrder = '/api/user/trade/new-order';
  static const closePositionByPositionId =
      '/api/user/trade/closePositionByPositionId';
  static const closePositions = '/api/user/trade/closePositions';
  static const cancelPendingOrder = '/api/user/trade/cancel-pending-order';
  static const closePendingOrder = '/api/user/trade/closePendingOrder';
  static const modifyPendingOrder = '/api/user/trade/modify-pending-order';
  static const updateTPSL = '/api/user/trade/update-tp-sl';
  static const updatePendingOrderTPSL =
      '/api/user/trade/update-pending-order-tp-sl';

  /// Trade history (GET) on the web host. Standard envelope; `data` may be a
  /// flat list or `{data, pagination, totals, summary}`.
  static const tradeHistory = '/api/user/trade/tradehistory';
}
