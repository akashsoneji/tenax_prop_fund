/// Parsed payload of `GET /mobile-app-details`.
class AppStatusModel {
  final String appVersion;
  final bool isUnderMaintenance;
  final bool isForceUpdate;
  final String? laterDate;
  final String? updateUrlIos;
  final String? updateUrlAndroid;
  final String? releaseNotes;

  const AppStatusModel({
    required this.appVersion,
    required this.isUnderMaintenance,
    required this.isForceUpdate,
    this.laterDate,
    this.updateUrlIos,
    this.updateUrlAndroid,
    this.releaseNotes,
  });

  factory AppStatusModel.fromJson(Map<String, dynamic> json) {
    return AppStatusModel(
      appVersion: (json['app_version'] as String?) ??
          (json['latest_version'] as String?) ??
          '1.0.0',
      isUnderMaintenance: json['is_under_maintenance'] as bool? ?? false,
      isForceUpdate: (json['is_force_update'] as bool?) ??
          (json['force_update'] as bool?) ??
          false,
      laterDate: json['later_date'] as String?,
      updateUrlIos: json['update_url_ios'] as String?,
      updateUrlAndroid: json['update_url_android'] as String?,
      releaseNotes: json['release_notes'] as String?,
    );
  }

  @override
  String toString() =>
      'AppStatusModel(v=$appVersion, maintenance=$isUnderMaintenance, force=$isForceUpdate)';
}
