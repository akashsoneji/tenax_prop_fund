import 'package:flutter/material.dart';

import '../../../core/network/api_response.dart';
import '../models/download_models.dart';

/// Single source of truth for the Downloads & guides data. Today it returns
/// demo data after a short delay to simulate the network; when the API lands,
/// replace the body of [getDownloads] with an `ApiClient` call + `fromJson`.
/// The controller and view do not change when that swap happens.
class DownloadsRepository {
  Future<ApiResponse<List<DownloadSection>>> getDownloads() async {
    try {
      // Simulated network latency so the shimmer is visible during development.
      await Future<void>.delayed(const Duration(milliseconds: 900));
      return ApiResponse.success(_demoSections);
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  // -------------------------------------------------------------------------
  // Demo data (moved out of the controller). Delete when the API is wired.
  // -------------------------------------------------------------------------
  static const List<DownloadSection> _demoSections = [
    DownloadSection('downloads.section_platform', [
      DownloadItem(
        icon: Icons.arrow_downward_rounded,
        title: 'downloads.mt5_ios',
        subtitle: 'downloads.app_store',
      ),
      DownloadItem(
        icon: Icons.arrow_downward_rounded,
        title: 'downloads.mt5_android',
        subtitle: 'downloads.google_play',
      ),
      DownloadItem(
        icon: Icons.arrow_downward_rounded,
        title: 'downloads.mt5_windows',
        subtitle: 'downloads.desktop_installer',
      ),
      DownloadItem(
        icon: Icons.arrow_downward_rounded,
        title: 'downloads.mt5_macos',
        subtitle: 'downloads.desktop_installer',
      ),
      DownloadItem(
        icon: Icons.arrow_downward_rounded,
        title: 'downloads.web_terminal',
        subtitle: 'downloads.no_install',
      ),
    ]),
    DownloadSection('downloads.section_read_first', [
      DownloadItem(
        icon: Icons.article_outlined,
        title: 'downloads.guide_daily_limit',
        subtitle: 'downloads.guide_daily_limit_sub',
        meta: '6 min',
      ),
      DownloadItem(
        icon: Icons.article_outlined,
        title: 'downloads.guide_rewards',
        subtitle: 'downloads.guide_rewards_sub',
        meta: '5 min',
      ),
      DownloadItem(
        icon: Icons.article_outlined,
        title: 'downloads.guide_first_phase',
        subtitle: 'downloads.guide_first_phase_sub',
        meta: '68 min',
      ),
      DownloadItem(
        icon: Icons.article_outlined,
        title: 'downloads.guide_prohibited',
        subtitle: 'downloads.guide_prohibited_sub',
        meta: '7 min',
      ),
    ]),
    DownloadSection('downloads.section_video', [
      DownloadItem(
        icon: Icons.desktop_windows_outlined,
        title: 'downloads.video_setup_mt5',
        subtitle: '',
        meta: '4:12',
      ),
      DownloadItem(
        icon: Icons.desktop_windows_outlined,
        title: 'downloads.video_account_screen',
        subtitle: '',
        meta: '3:05',
      ),
      DownloadItem(
        icon: Icons.desktop_windows_outlined,
        title: 'downloads.video_request_reward',
        subtitle: '',
        meta: '2:38',
      ),
    ]),
  ];
}
