import 'package:buildtrack/data/http_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:postgres/postgres.dart';

/// These tests make real HTTP calls to the local database bridge, so they must
/// live in their own file: any testWidgets in the same file installs the
/// flutter test binding, which stubs HttpClient and returns 400 for every
/// request. Run with: flutter test --dart-define-from-file=env.json
/// (Skipped when no API_BRIDGE_TOKEN is available from the dart-defines.)
void main() {
  final enabled = DbBridgeConfig.apiToken.isNotEmpty;

  test('HttpSession parses bridge responses into rows', () async {
    final session = HttpSession();
    final result = await session.execute(
      Sql.named('select 1 as one, @value::text as value'),
      parameters: {'value': 'bridge-ok'},
    );
    expect(result.length, 1);
    expect(result.first.toColumnMap()['one'], isNotNull);
    expect(result.first.toColumnMap()['value'], 'bridge-ok');
    debugPrint('bridge select parsed: ok');
  }, timeout: const Timeout(Duration(minutes: 2)), skip: !enabled);

  test('HttpSession insert + returning round-trips through the bridge', () async {
    final session = HttpSession();
    final insert = await session.execute(
      Sql.named(
        'insert into buildtrack_users (name, email, password_hash) '
        'values (@name, @email, @passwordHash) '
        'returning id::text as id, name',
      ),
      parameters: {
        'name': 'Bridge Probe',
        'email': 'bridge-probe-${DateTime.now().microsecondsSinceEpoch}'
            '@buildtrack.test',
        'passwordHash': 'not-a-real-hash',
      },
    );
    final row = insert.first.toColumnMap();
    expect(row['id'], isA<String>());
    expect(row['id'], isNotEmpty);
    debugPrint('bridge insert returned id: ${row['id']}');

    final select = await session.execute(
      Sql.named('select name from buildtrack_users where id = @id'),
      parameters: {'id': row['id']},
    );
    expect(select.first.first, 'Bridge Probe');

    await session.execute(
      Sql.named('delete from buildtrack_users where id = @id'),
      parameters: {'id': row['id']},
    );
    debugPrint('bridge insert cleaned up');
  }, timeout: const Timeout(Duration(minutes: 2)), skip: !enabled);
}
