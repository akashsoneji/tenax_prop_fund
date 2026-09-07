import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/competition_models.dart';

/// The purple gradient hero card at the top of the Competitions screen:
/// title + status pill, date range, a 2×2 stat grid and the register CTA.
/// Uses the brand hero gradient so it matches the other hero surfaces.
class CompetitionHeroCard extends StatelessWidget {
  const CompetitionHeroCard({
    super.key,
    required this.info,
    required this.registered,
    required this.onRegister,
  });

  final CompetitionInfo info;
  final bool registered;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stats = [
      CompetitionStat('competitions.prize_pool'.tr, info.prizePool),
      CompetitionStat('competitions.accounts'.tr, info.accounts),
      CompetitionStat('competitions.entry'.tr, info.entry),
      CompetitionStat('competitions.your_rank'.tr, info.rank),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient(scheme),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  info.title,
                  style: GoogleFonts.beVietnamPro(
                    color: AppColors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  info.status,
                  style: GoogleFonts.beVietnamPro(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            info.dateRange,
            style: GoogleFonts.beVietnamPro(
              color: AppColors.white.withValues(alpha: 0.75),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _StatTile(stat: stats[0])),
              const SizedBox(width: 12),
              Expanded(child: _StatTile(stat: stats[1])),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatTile(stat: stats[2])),
              const SizedBox(width: 12),
              Expanded(child: _StatTile(stat: stats[3])),
            ],
          ),
          const SizedBox(height: 18),
          _RegisterButton(registered: registered, onRegister: onRegister),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.stat});
  final CompetitionStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            stat.label,
            style: GoogleFonts.beVietnamPro(
              color: AppColors.white.withValues(alpha: 0.70),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            stat.value,
            style: GoogleFonts.beVietnamPro(
              color: AppColors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Yellow accent CTA — the ONE place yellow is used as a fill (a competition
/// register button, per the design), with deep-purple ink for contrast.
/// Flips to a confirmed state once registered so double-taps are inert.
class _RegisterButton extends StatelessWidget {
  const _RegisterButton({required this.registered, required this.onRegister});
  final bool registered;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: registered ? AppColors.white.withValues(alpha: 0.18) : AppTheme.accent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: registered ? null : onRegister,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (registered) ...[
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.white, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  registered
                      ? 'competitions.registered'.tr
                      : 'competitions.register_free'.tr,
                  style: GoogleFonts.beVietnamPro(
                    color: registered ? AppColors.white : AppColors.brandPurple,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
