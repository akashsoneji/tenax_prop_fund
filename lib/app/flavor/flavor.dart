/// Available white-label clients. Business logic is identical across all of
/// them — only theme, assets and some UI vary per flavor.
enum Flavor {
  /// "Tenax Prop". All flavors share one UI; they differ only by config.
  tenax,
  pipzeFunded,
  alibabafxProp,
  pipprop;

  static Flavor fromName(String name) {
    switch (name) {
      case 'pipze_funded':
        return Flavor.pipzeFunded;
      case 'alibabafx_prop':
        return Flavor.alibabafxProp;
      case 'pipprop':
        return Flavor.pipprop;
      case 'tenax':
      default:
        return Flavor.tenax;
    }
  }
}

/// Deployment environment, kept separate from [Flavor] on purpose so any
/// client can build against dev / staging / prod.
enum AppEnv { development, staging, production }

AppEnv appEnvFromName(String name) {
  switch (name) {
    case 'staging':
      return AppEnv.staging;
    case 'production':
      return AppEnv.production;
    case 'development':
    default:
      return AppEnv.development;
  }
}
