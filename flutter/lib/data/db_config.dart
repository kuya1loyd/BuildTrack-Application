class DbConfig {
  DbConfig._();

  static const databaseUrl = String.fromEnvironment('NEON_DATABASE_URL');

  /// Forces the HTTP bridge even off-web. Used by tests so they exercise the
  /// same data path the browser build uses.
  static const forceBridge = bool.fromEnvironment('FORCE_DB_BRIDGE');

  static bool get isConfigured => databaseUrl.isNotEmpty || forceBridge;

  static bool get isDebug => bool.fromEnvironment('DEBUG_DATABASE');

  static bool get isVerboseLoggingEnabled => isDebug || forceBridge;

  static String get poolUrl {
    final base = sanitizeUrl(databaseUrl);
    if (base.isEmpty) return base;
    final separator = base.contains('?') ? '&' : '?';
    return '$base'
        '${separator}max_connection_count=$poolSize'
        '&max_connection_age=$maxConnectionAgeSeconds'
        '&max_query_count=$maxQueryCount'
        '&connect_timeout=$connectTimeoutSeconds';
  }

  static String sanitizeUrl(String url) {
    if (url.isEmpty) return url;
    final uri = Uri.parse(url);
    if (!uri.hasQuery) return url;
    final params = Map<String, String>.of(uri.queryParameters)
      ..removeWhere((key, value) => key == 'channel_binding');
    return uri
        .replace(
          query: params.entries.map((e) => '${e.key}=${e.value}').join('&'),
        )
        .toString();
  }

  static const poolSize = 3;
  static const maxConnectionAgeSeconds = 1800;
  static const maxQueryCount = 500;
  static const connectTimeoutSeconds = 12;

  static const connectionTimeout = Duration(seconds: 12);
}
