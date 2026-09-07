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
    DownloadSection('Trading platform', [
      DownloadItem(
        icon: Icons.arrow_downward_rounded,
        title: 'MetaTrader 5 · iOS',
        subtitle: 'App Store',
      ),
      DownloadItem(
        icon: Icons.arrow_downward_rounded,
        title: 'MetaTrader 5 · Android',
        subtitle: 'Google Play',
      ),
      DownloadItem(
        icon: Icons.arrow_downward_rounded,
        title: 'MetaTrader 5 · Windows',
        subtitle: 'Desktop installer',
      ),
      DownloadItem(
        icon: Icons.arrow_downward_rounded,
        title: 'MetaTrader 5 · macOS',
        subtitle: 'Desktop installer',
      ),
      DownloadItem(
        icon: Icons.arrow_downward_rounded,
        title: 'Web terminal',
        subtitle: 'No install needed',
      ),
    ]),
    DownloadSection('Read first', [
      DownloadItem(
        icon: Icons.article_outlined,
        title: 'Understanding the daily limit',
        subtitle: 'The rule that ends most accounts',
        meta: '6 min',
      ),
      DownloadItem(
        icon: Icons.article_outlined,
        title: 'How rewards actually work',
        subtitle: 'Cycles, share and the consistency',
        meta: '5 min',
      ),
      DownloadItem(
        icon: Icons.article_outlined,
        title: 'Passing your first phase',
        subtitle: 'What separates the 11% who pass',
        meta: '68 min',
      ),
      DownloadItem(
        icon: Icons.article_outlined,
        title: 'What we prohibit and why',
        subtitle: 'The five strategies that close account',
        meta: '7 min',
      ),
    ]),
    DownloadSection('Video', [
      DownloadItem(
        icon: Icons.desktop_windows_outlined,
        title: 'Setting up MetaTrader 5',
        subtitle: '',
        meta: '4:12',
      ),
      DownloadItem(
        icon: Icons.desktop_windows_outlined,
        title: 'Reading your account screen',
        subtitle: '',
        meta: '3:05',
      ),
      DownloadItem(
        icon: Icons.desktop_windows_outlined,
        title: 'Requesting a reward',
        subtitle: '',
        meta: '2:38',
      ),
    ]),
  ];
}
