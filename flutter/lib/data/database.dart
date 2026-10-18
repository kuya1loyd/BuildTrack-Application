import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';

import 'db_config.dart';
import 'http_session.dart';

class Database {
  Database._();

  static final Database instance = Database._();

  Pool? _pool;

  /// Serialises every native database operation. Screens load their own data
  /// independently, so without this several queries race for the small pool
  /// and the pool lock times out. The HTTP bridge does not need this because
  /// the bridge server pools on its side.
  Future<void> _tail = Future<void>.value();

  Future<T> _queue<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<Pool> get connection async {
    final existing = _pool;
    if (existing != null) return existing;

    if (!DbConfig.isConfigured) {
      throw const DbNotConfiguredException();
    }

    final pool = Pool.withUrl(DbConfig.poolUrl);
    _pool = pool;
    return pool;
  }

  Future<void> close() async {
    final pool = _pool;
    _pool = null;
    await pool?.close();
  }

  Future<T> use<T>(Future<T> Function(Session conn) action) async {
    if (kIsWeb || DbConfig.forceBridge) {
      return action(HttpSession());
    }
    final pool = await connection;
    return _queue(() => pool.run(action));
  }

  static String newId() => const Uuid().v4();
}

class DbNotConfiguredException implements Exception {
  const DbNotConfiguredException();

  @override
  String toString() =>
      'Database URL not configured. Run with '
      '--dart-define-from-file=env.json containing NEON_DATABASE_URL.';
}
