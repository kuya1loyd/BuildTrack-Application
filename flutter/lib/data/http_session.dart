import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';

class HttpSession implements Session {
  HttpSession({String? baseUrl})
    : baseUrl = (baseUrl ?? DbBridgeConfig.apiBaseUrl).replaceFirst(
        RegExp(r'/+$'),
        '',
      );

  final String baseUrl;

  @override
  bool get isOpen => true;

  @override
  Future<void> get closed => Completer<void>().future;

  @override
  Future<Statement> prepare(Object query) => throw UnsupportedError(
    'The HTTP bridge does not support prepared statements.',
  );

  @override
  Future<Result> execute(
    Object query, {
    Object? parameters,
    bool ignoreRows = false,
    QueryMode? queryMode,
    Duration? timeout,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/query'),
          headers: {
            'Content-Type': 'application/json',

            'Authorization': 'Bearer ${DbBridgeConfig.apiToken}',
          },
          body: jsonEncode({
            'sql': _sqlTextOf(query),
            'parameters': parameters,
          }),
        )
        .timeout(timeout ?? const Duration(seconds: 15));

    final Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(response.body);
      body = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      throw PostgresException(
        'The database bridge returned a malformed response.',
      );
    }

    if (response.statusCode == 401) {
      throw PostgresException(
        'The database bridge rejected this session. '
        'Restart the app with --dart-define-from-file=env.json so the '
        'API_BRIDGE_TOKEN in env.json reaches the app.',
      );
    }

    if (response.statusCode != 200 || body.containsKey('error')) {
      throw PostgresException(
        'Database bridge error: ${body['error'] ?? response.statusCode}',
      );
    }

    final rawRows = (body['rows'] as List?) ?? const [];
    final columnNames = <String>[];
    final values = <List<Object?>>[];
    for (final raw in rawRows.cast<Map<String, dynamic>>()) {
      if (columnNames.isEmpty) columnNames.addAll(raw.keys);
      values.add(raw.values.map(_decodeValue).toList());
    }

    final schema = ResultSchema([
      for (final name in columnNames)
        ResultSchemaColumn(typeOid: 0, type: Type.text, columnName: name),
    ]);
    final rows = [
      for (final row in values) ResultRow(values: row, schema: schema),
    ];

    return Result(
      rows: rows,
      affectedRows: (body['rowCount'] as int?) ?? rows.length,
      schema: schema,
    );
  }

  String _sqlTextOf(Object query) {
    if (query is String) return query;
    final sql = (query as dynamic).sql;
    if (sql is String) return sql;
    throw ArgumentError('Unsupported query type: ${query.runtimeType}');
  }

  Object? _decodeValue(Object? value) {
    if (value is! Map) return value;
    final tag = value[r'$t'];
    if (tag is! String) return value;
    final payload = value['v'];
    switch (tag) {
      case 'null':
        return null;
      case 'datetime':
        return DateTime.parse(payload as String);
      case 'bigint':
        return int.parse(payload as String);
      case 'numeric':
        return double.parse(payload as String);
      default:
        return payload;
    }
  }
}

class PostgresException implements Exception {
  PostgresException(this.message);
  final String message;
  @override
  String toString() => message;
}

class DbBridgeConfig {
  DbBridgeConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8787',
  );

  static const apiToken = String.fromEnvironment('API_BRIDGE_TOKEN');
}
