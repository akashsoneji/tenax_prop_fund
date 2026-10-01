import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Keeps the reusable-UI rules from eroding. Scans `lib/features` (minus the
/// frozen chart features) and fails on:
///
/// - `GoogleFonts.` / `TextStyle(`: text styles come from `AppText`.
/// - `OutlinedButton(` / `TextButton(` / `FilledButton(`: buttons come from
///   `AppButton`. The custom-styled buttons that exist today are one-off
///   designs, listed in [_buttonAllowance] with their exact count; adding a
///   new raw button anywhere, or another one in those files, fails.
/// - `Flavor.<x>` outside `lib/app/flavor/`: every flavor ships the same UI;
///   per-flavor screens go through `FlavorResolver` only.
///
/// Comment lines are ignored, so docs may mention these names.
void main() {
  final features = Directory('lib/features');
  const frozen = ['lib/features/chart/', 'lib/features/chart_landscape/'];

  List<File> dartFiles(Directory dir) => dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  Iterable<(String, int, String)> codeLines(File f) sync* {
    final lines = f.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final trimmed = lines[i].trimLeft();
      if (trimmed.startsWith('//')) continue;
      yield (f.path, i + 1, lines[i]);
    }
  }

  final featureFiles = dartFiles(features)
      .where((f) => !frozen.any((p) => f.path.replaceAll(r'\', '/').startsWith(p)))
      .toList();

  List<String> find(RegExp pattern, Iterable<File> files) => [
        for (final f in files)
          for (final (path, line, text) in codeLines(f))
            if (pattern.hasMatch(text)) '$path:$line  ${text.trim()}',
      ];

  test('features take text styles from AppText', () {
    final hits = find(RegExp(r'GoogleFonts\.|(?<![\w.])TextStyle\('), featureFiles);
    expect(hits, isEmpty, reason: 'Use AppText.* instead:\n${hits.join('\n')}');
  });

  test('features use AppButton (only the listed one-off buttons stay raw)', () {
    final raw = RegExp(r'(?<![\w.])(OutlinedButton|TextButton|FilledButton)(\.icon)?\(');
    final counts = <String, int>{};
    for (final f in featureFiles) {
      for (final (path, _, text) in codeLines(f)) {
        final n = raw.allMatches(text).length;
        if (n > 0) counts[path.replaceAll(r'\', '/')] = (counts[path.replaceAll(r'\', '/')] ?? 0) + n;
      }
    }
    final problems = [
      for (final MapEntry(key: path, value: n) in counts.entries)
        if (n > (_buttonAllowance[path] ?? 0))
          '$path has $n raw button(s), allowed ${_buttonAllowance[path] ?? 0}',
    ];
    expect(problems, isEmpty, reason: 'Use AppButton / AppButton.outlined / .text / .tonal:\n${problems.join('\n')}');
  });

  test('no flavor checks outside lib/app/flavor', () {
    final lib = dartFiles(Directory('lib'))
        .where((f) => !f.path.replaceAll(r'\', '/').startsWith('lib/app/flavor/'));
    final hits = find(RegExp(r'\bFlavor\.[a-z]'), lib);
    expect(hits, isEmpty,
        reason: 'All flavors share one UI. Register a per-flavor screen in '
            'FlavorResolver instead:\n${hits.join('\n')}');
  });
}

/// Raw buttons that carry a one-off style no other screen shares (verified:
/// no two styles are identical), so moving them onto an AppButton variant
/// would change the design. Lower a count when you migrate one; never raise it.
const _buttonAllowance = <String, int>{
  'lib/features/account/widgets/reset_confirm_dialog.dart': 1,
  'lib/features/authentication/views/forgot_password_view.dart': 1,
  'lib/features/authentication/views/register_view.dart': 1,
  'lib/features/authentication/widgets/login_form.dart': 1,
  'lib/features/authentication/widgets/otp_dialog.dart': 3,
  'lib/features/authentication/widgets/two_factor_dialog.dart': 1,
  'lib/features/billing/views/invoice_viewer_view.dart': 1,
  'lib/features/certificates/views/certificate_viewer_view.dart': 1,
  'lib/features/configure/views/configure_view.dart': 1,
  'lib/features/get_started/views/get_started_view.dart': 1,
  'lib/features/notifications/views/notifications_view.dart': 2,
  'lib/features/positions/views/positions_view.dart': 1,
  'lib/features/positions/widgets/close_all_sheet.dart': 2,
  'lib/features/positions/widgets/history_filter_sheet.dart': 1,
  'lib/features/referral/widgets/referral_withdraw_sheet.dart': 1,
  'lib/features/rewards/views/rewards_view.dart': 1,
  'lib/features/rewards/widgets/payout_history_card.dart': 1,
  'lib/features/rewards/widgets/payout_history_tab.dart': 2,
  'lib/features/rewards/widgets/request_payout_sheet.dart': 1,
  'lib/features/symbols/views/symbols_view.dart': 1,
  'lib/features/verification/views/verification_personal_view.dart': 1,
};
