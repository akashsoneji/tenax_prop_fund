import 'dart:async';

import 'package:get/get.dart';

import '../../../core/base/base_controller.dart';
import '../../../core/network/api_response.dart';
import '../../../core/state/data_state.dart';
import '../../../core/websocket/pusher_client.dart';
import '../../authentication/repositories/auth_repository.dart';
import '../models/dashboard_models.dart';
import '../repositories/home_repository.dart';

/// Owns the shell's tab index and the live Home dashboard snapshot.
///
/// The KPI + focus + live-account data loads through [BaseController] as a
/// single `DataState<DashboardData>` the Home tab binds to. On top of that REST
/// snapshot, the controller subscribes to a per-account WebSocket topic and
/// splices live equity ticks into the snapshot so the hero equity, KPI tiles
/// and account strip update in real time without a refetch. The notification
/// badge count is its own small Rx polled from REST and bumped by WS.
class HomeController extends BaseController<DashboardData> {
  HomeController(this._repository, this._pusher, this._auth);

  final HomeRepository _repository;
  final PusherClient _pusher;
  final AuthRepository _auth;

  /// Guards against subscribing the per-user channel more than once.
  String? _channel;

  /// The authenticated trader id — used as the Pusher channel fallback when the
  /// dashboard payload does not carry `liveUserId`.
  int _authUserId = 0;

  final selectedTab = 0.obs;

  /// The logged-in user's first name, shown after "Welcome back,".
  final userName = ''.obs;

  /// Unread notification count for the hero bell badge.
  final unreadCount = 0.obs;

  /// WebSocket connection indicator for the "live" pill in the hero.
  final isLive = false.obs;

  final _wsSubs = <StreamSubscription>[];

  void selectTab(int index) => selectedTab.value = index;

  @override
  Future<ApiResponse<DashboardData>> fetch() => _repository.getDashboard();

  @override
  bool isEmpty(DashboardData data) => data.isEmpty;

  @override
  void onInit() {
    super.onInit();
    _loadUserName();
    _loadUnreadCount();
    _bindConnectionState();
  }

  Future<void> _loadUserName() async {
    final user = await _auth.currentUser();
    if (isClosed || user == null) return;
    final first = user.firstName.trim().isNotEmpty
        ? user.firstName.trim()
        : user.name.trim().split(' ').first;
    userName.value = first;
    _authUserId = int.tryParse(user.id) ?? 0;
    // If the snapshot was already loaded before we knew the user id, subscribe
    // now that the channel can be resolved.
    _onSnapshotLoaded();
  }

  @override
  Future<void> load() async {
    await super.load();
    _onSnapshotLoaded();
    _loadReferral();
    _loadUnreadCount();
  }

  @override
  Future<void> refreshData() async {
    await super.refreshData();
    _loadUnreadCount();
    _onSnapshotLoaded();
    _loadReferral();
  }

  /// The `/app/dashboard` payload already carries the referral summary, so read
  /// it from the last fetch and splice it into the loaded snapshot for the Home
  /// card (no extra network call).
  void _loadReferral() {
    final referral = _repository.getReferralCard();
    if (isClosed || referral == null) return;
    final current = state;
    if (current is! DataSuccess<DashboardData>) return;
    stateRx.value = DataSuccess(current.data.copyWith(referral: referral));
  }

  void _loadUnreadCount() {
    if (!isClosed) unreadCount.value = _repository.getUnreadCount();
  }

  void _bindConnectionState() {
    _wsSubs.add(_pusher.states.listen((s) {
      if (!isClosed) isLive.value = s == PusherState.connected;
    }));
    _wsSubs.add(_pusher.accountStates.listen(_onAccountTick));
  }

  /// After a fresh REST snapshot, connect and subscribe ONCE to the per-user
  /// account channel `private-trader.{liveUserId}.accounts`. The channel is
  /// per-user (not per-account); each frame carries its own `account_id`.
  void _onSnapshotLoaded() {
    final current = state;
    if (current is! DataSuccess<DashboardData>) return;
    final userId =
        current.data.liveUserId != 0 ? current.data.liveUserId : _authUserId;
    if (userId == 0) return;
    _pusher.connect();
    final channel = 'private-trader.$userId.accounts';
    if (_channel != channel) {
      _channel = channel;
      _pusher.subscribe(channel);
    }
  }

  /// Applies a decoded live account frame to the in-memory snapshot, patching
  /// the matching `live_accounts` row plus the hero equity and the KPI equity
  /// tile so the whole top of the screen ticks in real time.
  void _onAccountTick(AccountStateEvent ev) {
    final current = state;
    if (current is! DataSuccess<DashboardData>) return;

    final id = ev.accountId;
    final equityMinor = ev.equityMinor;
    final balanceMinor = ev.balanceMinor;

    final snapshot = current.data;
    final accounts = snapshot.liveAccounts
        .map((a) => a.id == id
            ? a.copyWith(equityMinor: equityMinor, balanceMinor: balanceMinor)
            : a)
        .toList();

    var focus = snapshot.focus;
    var kpis = snapshot.kpis;
    if (focus != null && focus.accountId == id) {
      final currency = focus.currency;
      focus = focus.copyWith(
        equityMinor: equityMinor,
        equity: _formatMoney(equityMinor, currency),
        balanceMinor: balanceMinor,
        balance: _formatMoney(balanceMinor, currency),
      );
      kpis = kpis
          .map((k) => switch (k.metric) {
                'equity_minor' || 'sum_equity' => k.copyWith(
                    valueMinor: equityMinor,
                    value: _formatMoney(equityMinor, currency)),
                'balance_minor' || 'sum_balance' => k.copyWith(
                    valueMinor: balanceMinor,
                    value: _formatMoney(balanceMinor, currency)),
                _ => k,
              })
          .toList();
    }

    stateRx.value = DataSuccess(
      snapshot.copyWith(liveAccounts: accounts, focus: focus, kpis: kpis),
    );
  }

  String _formatMoney(int minor, String currency) {
    final major = minor / 100;
    final symbol = currency == 'USD' ? '\$' : '';
    final s = major.toStringAsFixed(2);
    final parts = s.split('.');
    final buf = StringBuffer();
    final intPart = parts[0];
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
      buf.write(intPart[i]);
    }
    return '$symbol$buf.${parts[1]}';
  }

  @override
  void onClose() {
    if (_channel != null) _pusher.unsubscribe(_channel!);
    for (final s in _wsSubs) {
      s.cancel();
    }
    super.onClose();
  }
}
