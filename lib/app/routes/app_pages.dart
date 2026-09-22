import 'package:get/get.dart';

import '../../features/account/bindings/account_binding.dart';
import '../../features/account/views/account_view.dart';
import '../../features/accounts/bindings/accounts_binding.dart';
import '../../features/accounts/views/accounts_view.dart';
import '../../features/notifications/bindings/notifications_binding.dart';
import '../../features/notifications/views/notifications_view.dart';
import '../../features/offers/bindings/offers_binding.dart';
import '../../features/offers/views/offers_view.dart';
import '../../features/payout_methods/bindings/payout_methods_binding.dart';
import '../../features/payout_methods/views/payout_methods_view.dart';
import '../../features/referral/bindings/referral_binding.dart';
import '../../features/referral/views/referral_view.dart';
import '../../features/support/bindings/support_binding.dart';
import '../../features/support/views/support_view.dart';
import '../../features/chart/views/chart_view.dart';
import '../../features/symbols/bindings/symbols_binding.dart';
import '../../features/symbols/views/symbols_view.dart';
import '../../features/billing/bindings/billing_binding.dart';
import '../../features/billing/views/billing_view.dart';
import '../../features/calculators/bindings/calculators_binding.dart';
import '../../features/calculators/views/calculators_view.dart';
import '../../features/certificates/bindings/certificate_viewer_binding.dart';
import '../../features/certificates/bindings/certificates_binding.dart';
import '../../features/certificates/views/certificate_viewer_view.dart';
import '../../features/certificates/views/certificates_view.dart';
import '../../features/challenge/bindings/challenge_binding.dart';
import '../../features/challenge/views/challenge_view.dart';
import '../../features/challenge/views/challenge_compare_view.dart';
import '../../features/competitions/bindings/competitions_binding.dart';
import '../../features/competitions/views/competition_detail_view.dart';
import '../../features/competitions/views/competitions_view.dart';
import '../../features/configure/bindings/configure_binding.dart';
import '../../features/configure/views/configure_view.dart';
import '../../features/payment/bindings/complete_payment_binding.dart';
import '../../features/payment/views/complete_payment_view.dart';
import '../../features/payment/views/gateway_payment_view.dart';
import '../../features/downloads/bindings/downloads_binding.dart';
import '../../features/downloads/views/downloads_view.dart';
import '../../features/economic_calendar/bindings/economic_calendar_binding.dart';
import '../../features/economic_calendar/views/economic_calendar_view.dart';
import '../../features/faq/bindings/faq_binding.dart';
import '../../features/faq/views/faq_view.dart';
import '../../features/authentication/bindings/auth_binding.dart';
import '../../features/authentication/views/forgot_password_view.dart';
import '../../features/authentication/views/register_view.dart';
import '../../features/authentication/views/terms_view.dart';
import '../../features/get_started/views/get_started_view.dart';
import '../../features/home/bindings/home_binding.dart';
import '../../features/home/views/home_shell_view.dart';
import '../../features/home/views/tabs/more_tab_view.dart';
import '../../features/kyc/bindings/edit_profile_binding.dart';
import '../../features/kyc/bindings/kyc_binding.dart';
import '../../features/kyc/bindings/kyc_docs_binding.dart';
import '../../features/kyc/views/edit_profile_view.dart';
import '../../features/kyc/views/kyc_docs_view.dart';
import '../../features/kyc/views/profile_kyc_view.dart';
import '../../features/rewards/bindings/rewards_binding.dart';
import '../../features/rewards/views/rewards_view.dart';
import '../../features/settings/bindings/settings_binding.dart';
import '../../features/settings/views/settings_view.dart';
import '../../features/splash/views/splash_view.dart';
import '../../features/trading_rules/bindings/trading_rules_binding.dart';
import '../../features/trading_rules/views/trading_rules_view.dart';
import '../../features/verification/bindings/add_bank_binding.dart';
import '../../features/verification/bindings/verification_binding.dart';
import '../../features/verification/views/add_bank_view.dart';
import '../../features/verification/views/verification_documents_view.dart';
import '../../features/verification/views/verification_overview_view.dart';
import '../../features/verification/views/verification_personal_view.dart';
import '../flavor/flavor_resolver.dart';
import 'app_routes.dart';

/// GetX route table. The login page is resolved per flavor via FlavorResolver;
/// the shared AuthController is provided by AuthBinding regardless of layout.
class AppPages {
  const AppPages._();

  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
    ),
    GetPage(
      name: AppRoutes.getStarted,
      page: () => const GetStartedView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => FlavorResolver.loginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.terms,
      page: () => const TermsView(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeShellView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.more,
      page: () => const MoreTabView(showBack: true),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: AppRoutes.profileKyc,
      page: () => const ProfileKycView(),
      binding: KycBinding(),
    ),
    GetPage(
      name: AppRoutes.editProfile,
      page: () => const EditProfileView(),
      binding: EditProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.kycDocuments,
      page: () => const KycDocsView(),
      binding: KycDocsBinding(),
    ),
    GetPage(
      name: AppRoutes.rewards,
      page: () => const RewardsView(),
      binding: RewardsBinding(),
    ),
    GetPage(
      name: AppRoutes.tradingRules,
      page: () => const TradingRulesView(),
      binding: TradingRulesBinding(),
    ),
    GetPage(
      name: AppRoutes.account,
      page: () => const AccountView(),
      binding: AccountBinding(),
    ),
    GetPage(
      name: AppRoutes.billing,
      page: () => const BillingView(),
      binding: BillingBinding(),
    ),
    GetPage(
      name: AppRoutes.certificates,
      page: () => const CertificatesView(),
      binding: CertificatesBinding(),
    ),
    GetPage(
      name: AppRoutes.certificateViewer,
      page: () => const CertificateViewerView(),
      binding: CertificateViewerBinding(),
    ),
    GetPage(
      name: AppRoutes.calculators,
      page: () => const CalculatorsView(),
      binding: CalculatorsBinding(),
    ),
    GetPage(
      name: AppRoutes.competitions,
      page: () => const CompetitionsView(),
      binding: CompetitionsBinding(),
    ),
    GetPage(
      name: AppRoutes.competitionDetail,
      page: () => const CompetitionDetailView(),
      binding: CompetitionsBinding(),
    ),
    GetPage(
      name: AppRoutes.challenge,
      page: () => const ChallengeView(),
      binding: ChallengeBinding(),
    ),
    GetPage(
      name: AppRoutes.challengeCompare,
      page: () => const ChallengeCompareView(),
      binding: ChallengeBinding(),
    ),
    GetPage(
      name: AppRoutes.configure,
      page: () => const ConfigureView(),
      binding: ConfigureBinding(),
    ),
    GetPage(
      name: AppRoutes.completePayment,
      page: () => const CompletePaymentView(),
      binding: CompletePaymentBinding(),
    ),
    GetPage(
      name: AppRoutes.gatewayPayment,
      page: () => const GatewayPaymentView(),
    ),
    GetPage(
      name: AppRoutes.downloads,
      page: () => const DownloadsView(),
      binding: DownloadsBinding(),
    ),
    GetPage(
      name: AppRoutes.economicCalendar,
      page: () => const EconomicCalendarView(),
      binding: EconomicCalendarBinding(),
    ),
    GetPage(
      name: AppRoutes.faq,
      page: () => const FaqView(),
      binding: FaqBinding(),
    ),
    GetPage(
      name: AppRoutes.verification,
      page: () => const VerificationOverviewView(),
      binding: VerificationBinding(),
    ),
    GetPage(
      name: AppRoutes.verificationPersonal,
      page: () => const VerificationPersonalView(),
      binding: VerificationBinding(),
    ),
    GetPage(
      name: AppRoutes.verificationDocuments,
      page: () => const VerificationDocumentsView(),
      binding: VerificationBinding(),
    ),
    GetPage(
      name: AppRoutes.addBank,
      page: () => const AddBankView(),
      binding: AddBankBinding(),
    ),
    GetPage(
      name: AppRoutes.accounts,
      page: () => const AccountsView(),
      binding: AccountsBinding(),
    ),
    GetPage(
      name: AppRoutes.offers,
      page: () => const OffersView(),
      binding: OffersBinding(),
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsView(),
      binding: NotificationsBinding(),
    ),
    GetPage(
      name: AppRoutes.payoutMethods,
      page: () => const PayoutMethodsView(),
      binding: PayoutMethodsBinding(),
    ),
    GetPage(
      name: AppRoutes.referral,
      page: () => const ReferralView(),
      binding: ReferralBinding(),
    ),
    GetPage(
      name: AppRoutes.support,
      page: () => const SupportView(),
      binding: SupportBinding(),
    ),
    GetPage(
      name: AppRoutes.symbols,
      page: () => const SymbolsView(),
      binding: SymbolsBinding(),
    ),
    GetPage(
      name: AppRoutes.chart,
      page: () => const ChartView(),
    ),
  ];
}
