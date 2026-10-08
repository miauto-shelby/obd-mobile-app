enum AppEnvironment {
  development,
  test,
  production;

  static AppEnvironment parse(String value) {
    return switch (value.toLowerCase()) {
      'development' => AppEnvironment.development,
      'test' => AppEnvironment.test,
      'production' => AppEnvironment.production,
      _ => throw StateError('APP_ENV debe ser development, test o production.'),
    };
  }
}

class AppConfiguration {
  AppConfiguration({
    required this.environment,
    required this.apiBaseUrl,
    required this.googleClientId,
    required this.googleServerClientId,
  });

  factory AppConfiguration.fromDartDefines() {
    final environment = AppEnvironment.parse(
      const String.fromEnvironment('APP_ENV', defaultValue: 'development'),
    );
    final suppliedApiBaseUrl = const String.fromEnvironment('API_BASE_URL');
    final apiBaseUrl = suppliedApiBaseUrl.isEmpty
        ? _defaultApiBaseUrlFor(environment)
        : suppliedApiBaseUrl;

    if (apiBaseUrl.isEmpty) {
      throw StateError('API_BASE_URL es obligatoria para APP_ENV=production.');
    }

    final parsedApiUrl = Uri.tryParse(apiBaseUrl);
    if (parsedApiUrl == null ||
        !parsedApiUrl.hasScheme ||
        !parsedApiUrl.hasAuthority) {
      throw StateError('API_BASE_URL debe ser una URL absoluta válida.');
    }

    final googleClientId = const String.fromEnvironment('GOOGLE_CLIENT_ID');
    final suppliedGoogleServerClientId = const String.fromEnvironment(
      'GOOGLE_SERVER_CLIENT_ID',
    );
    final googleServerClientId = suppliedGoogleServerClientId.isEmpty
        ? _defaultGoogleServerClientIdFor(environment)
        : suppliedGoogleServerClientId;

    if (googleServerClientId.isEmpty) {
      throw StateError(
        'GOOGLE_SERVER_CLIENT_ID es obligatoria para APP_ENV=production.',
      );
    }

    return AppConfiguration(
      environment: environment,
      apiBaseUrl: apiBaseUrl.replaceFirst(RegExp(r'/$'), ''),
      googleClientId: googleClientId.isEmpty ? null : googleClientId,
      googleServerClientId: googleServerClientId,
    );
  }

  final AppEnvironment environment;
  final String apiBaseUrl;
  final String? googleClientId;
  final String googleServerClientId;

  static String _defaultApiBaseUrlFor(AppEnvironment environment) {
    return switch (environment) {
      AppEnvironment.development => 'http://127.0.0.1:8080',
      AppEnvironment.test || AppEnvironment.production => '',
    };
  }

  static String _defaultGoogleServerClientIdFor(AppEnvironment environment) {
    return switch (environment) {
      AppEnvironment.development || AppEnvironment.test =>
        '1001362850388-h14mgg5umq5cdopv2qdbkj3fud4u31th.apps.googleusercontent.com',
      AppEnvironment.production => '',
    };
  }
}
