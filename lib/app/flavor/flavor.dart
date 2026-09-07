/// Available white-label clients. Business logic is identical across all of
/// them — only theme, assets and some UI vary per flavor.
enum Flavor {
  /// Base flavor. "Tenax Prop" — carries the default design that every screen
  /// falls back to. Other flavors override only the screens they want to differ.
  tenax,
  clientA,
  clientB,
  clientC;

  static Flavor fromName(String name) {
    switch (name) {
      case 'client_a':
        return Flavor.clientA;
      case 'client_b':
        return Flavor.clientB;
      case 'client_c':
        return Flavor.clientC;
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
