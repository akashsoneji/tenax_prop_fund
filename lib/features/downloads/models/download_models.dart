import 'package:flutter/material.dart';

/// One tappable row in the Downloads screen. [meta] renders on the right
/// (e.g. a read time "6 min" or a video length "4:12") when present.
class DownloadItem {
  const DownloadItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.meta,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? meta;
}

/// A labelled group of [DownloadItem] rows ("Trading platform", "Read first",
/// "Video").
class DownloadSection {
  const DownloadSection(this.title, this.items);
  final String title;
  final List<DownloadItem> items;
}
