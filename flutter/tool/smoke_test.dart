import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';

Future<void> main() async {
  final file = File('env.json');
  if (!file.existsSync()) {
    stderr.writeln('env.json not found — run from the flutter/ directory.');
    exit(1);
  }
  final url =
      (jsonDecode(file.readAsStringSync()) as Map)['NEON_DATABASE_URL']
          as String;

  final uri = Uri.parse(url);
  final params = Map<String, String>.of(uri.queryParameters)
    ..removeWhere((key, value) => key == 'channel_binding');
  final cleaned = uri.replace(
    query: params.entries.map((e) => '${e.key}=${e.value}').join('&'),
  );
  final poolUrl = '${cleaned.toString()}&max_connection_count=2';

  stdout.writeln('Opening pool ...');
  final pool = Pool.withUrl(poolUrl);

  final smokeEmail =
      'smoke-${DateTime.now().millisecondsSinceEpoch}@buildtrack.test';

  final id = await pool.run((conn) async {
    final inserted = await conn.execute(
      Sql.named(
        'insert into buildtrack_users (name, email, password_hash, company) '
        r'values (@name, @email, @passwordHash, @company) returning id::text as id',
      ),
      parameters: {
        'name': 'Smoke Test',
        'email': smokeEmail,
        'passwordHash': 'not-a-real-hash',
        'company': 'BuildTrack CI',
      },
    );
    final id = inserted.first.toColumnMap()['id'] as String;
    stdout.writeln('  inserted user: $id');

    final found = await conn.execute(
      Sql.named('select name from buildtrack_users where id = @id'),
      parameters: {'id': id},
    );
    stdout.writeln('  read back: ${found.first.first}');

    await conn.execute(
      Sql.named('select 1 where @projectId::uuid is null'),
      parameters: {'projectId': null},
    );
    stdout.writeln('  nullable uuid cast: ok');

    await conn.execute(
      Sql.named('delete from buildtrack_users where id = @id'),
      parameters: {'id': id},
    );
    stdout.writeln('  cleaned up');
    return id;
  });

  final remaining = await pool.run((conn) async {
    final rows = await conn.execute('select count(*) from buildtrack_users');
    return rows.first.first;
  });
  await pool.close();
  stdout.writeln('buildtrack_users rows remaining: $remaining');
  stdout.writeln('SMOKE TEST PASSED (user $id created + removed)');
}
