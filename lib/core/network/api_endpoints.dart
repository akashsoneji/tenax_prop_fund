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

  /// Confirms an email/OTP code (`POST`). Body: `{email, code}`. Used by the
  /// post-register verification dialog (needs the bearer token from register).
  static const verifyEmail = '/auth/verify-email';

  /// Re-sends the verification/reset OTP (`POST`). Body: `{email}`.
  static const resendOtp = '/auth/resend-otp';

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

  static const challenges = '/challenges';
  static const challengeCompare = '/challenges/compare';
  static const challengeCoupon = '/challenges/coupon';

  /// Creates an order for the configured plan (`POST`). Body: `plan_version_id`,
  /// `addon_ids`, `coupon_code` (nullable), `payment_method_id`. Response
  /// `data` carries `order_id`, `path` (free | manual | gateway) and an
  /// optional `gateway_url`.
  static const challengePurchase = '/challenges/purchase';

  /// Single order snapshot for the Complete-payment screen (`GET`). `data`
  /// carries `order`, `choices` and `payment_instructions`.
  static String order(Object id) => '/orders/$id';

  /// Manual payment proof upload (`POST`, multipart). Fields: `proof` (file)
  /// and optional `reference`.
  static String orderProof(Object id) => '/orders/$id/proof';

  /// Referral summary for the Home "Refer & earn" card. Standard
  /// `{success, message, data}` envelope where `data` nests `referral`
  /// (code/share_url) and `stats` (referrals count, to_be_paid).
  static const referrals = '/growth/referrals';

  /// Promo vouchers for the "My offers" screen. Standard
  /// `{success, message, data}` envelope where `data` nests `offers[]` and
  /// `available_count`.
  static const offers = '/growth/offers';

  /// Achievement certificates for the "Certificates" screen. Standard
  /// `{success, message, data}` envelope where `data` nests `certificates[]`
  /// (each with `criteria[]`, `earned`, `download_url`) and `earned_count`.
  static const certificates = '/growth/certificates';

  /// Rendered certificate document (`GET`). `data` carries `name`, `holder`,
  /// `issued_at`, `verification_code`, `format` (`html`) and the `html` body
  /// the viewer loads into its WebView.
  static String certificateDownload(Object id) =>
      '/growth/certificates/$id/download';

  /// Trading competitions for the "Competitions" screen. Standard
  /// `{success, message, data}` envelope where `data` nests `competitions[]`
  /// (each with `prizes[]`, `rules[]`, `leaderboard[]`), `competitions_meta`
  /// (pagination), `accounts[]` (eligible entry accounts) and `stats`
  /// (`cash_pool`).
  static const competitions = '/growth/competitions';

  /// Enters a competition with one of the eligible trading accounts (`POST`).
  /// Body: `{competition_id, trading_account_id}`. Response carries a
  /// user-facing `message` and a null `data`.
  static const competitionRegister = '/growth/competitions/register';

  /// Trading accounts list for the "Account Center" screen. Standard
  /// `{success, message, data[], meta}` envelope. Query params: `status`
  /// (all | active | breached | passed | raw-status) and `phase`
  /// (all | evaluation | verification | funded | breached).
  static const accounts = '/accounts';

  /// Single trading account overview. Standard `{success, message, data}`
  /// envelope where `data` carries the account fields plus nested `stats`,
  /// `objectives`, `credentials`, `overview` and `chart`.
  static String accountDetail(Object id) => '/accounts/$id/overview';

  /// MT5 accounts list for the global active/primary-account selector
  /// (`GET`). Standard envelope; `data.accounts[]` each carry `id`, `login`,
  /// `is_primary`, `is_active`; `data.primary_account_id` names the active one.
  static const mt5Accounts = '/mt5accounts/get';

  /// Sets the user's primary (active) MT5 account (`POST`). Body:
  /// `{account_id}`. Response `data` carries `primary_account_id` and `login`.
  static const mt5SetPrimary = '/mt5accounts/set-primary';

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



  static const calculators = '/tools/calculators';

  /// Economic calendar. Standard `{success, message, data}` envelope where
  /// `data` nests `events[]` and `filters`. Query param `currency` (e.g. `ALL`).
  static const calendar = '/tools/calendar';

  /// Live tradable instruments list. Envelope `data` carries `symbols[]` and
  /// `categories[]`; optional `q` query param filters server-side.
  static const instruments = '/tools/symbols';

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

  // ---------------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------------
  /// Paged notifications feed. Standard `{success, message, data[], meta}`
  /// envelope; each element has `id, type, title, body, event_key, meta,
  /// read_at, created_at`. Query param `page`.
  static const notifications = '/notifications';

  /// Unread badge count. `data.count` holds the integer.
  static const notificationsUnreadCount = '/notifications/unread-count';

  /// Mark ALL notifications read (`POST`).
  static const notificationsReadAll = '/notifications/read-all';

  /// Mark a single notification read (`POST`). `data.count` returns the new
  /// unread total.
  static String notificationRead(Object id) => '/notifications/$id/read';

  /// Notification channel preferences. `GET` returns `{catalog[], preferences}`;
  /// `PUT` persists the `preferences` map.
  static const notificationPreferences = '/notifications/preferences';

  // ---------------------------------------------------------------------------
  // Support / Help
  // ---------------------------------------------------------------------------
  /// Trading rules rulebook. `data` is `{tabs[], sections[]}`.
  static const supportRules = '/support/rules';

  /// FAQ list. `data.items[]` holds `{q, a}` pairs.
  static const supportFaq = '/support/faq';

  /// Support ticket topics for the "Open a ticket" form. `data.topics[]` holds
  /// `{value, label}` pairs.
  static const supportTopics = '/support/topics';

  /// Support tickets list. Standard `{success, data[], meta}` envelope. Query
  /// param `tab` (open | closed | all). `POST` creates a ticket.
  static const supportTickets = '/support/tickets';

  /// Single support ticket with its messages thread.
  static String supportTicketDetail(Object id) => '/support/tickets/$id';

  /// Reply to a support ticket (`POST` with `{message}`).
  static String supportTicketReply(Object id) => '/support/tickets/$id/reply';
}
