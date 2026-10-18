import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';

Future<void> main(List<String> args) async {
  final config = await _loadConfig();
  final applyOnly = args.contains('--check');

  final url = _directUrl(_sanitizeUrl(config.url));

  stdout.writeln('Connecting to ${_safeUrl(url)} ...');
  final conn = await Connection.openFromUrl(url);

  try {
    final version = await conn.execute('select version()');
    stdout.writeln('Connected: ${version.first.first}');

    if (!applyOnly) {
      stdout.writeln('Applying schema ...');
      final statements = kSchemaSql
          .split(';')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty);
      for (final statement in statements) {
        await conn.execute(statement);
      }
      stdout.writeln('Schema applied.');
    } else {
      stdout.writeln('Check-only mode: schema not modified.');
    }

    final tables = await conn.execute(
      "select tablename from pg_tables where schemaname = 'public' order by tablename",
    );
    stdout.writeln('Tables: ${tables.map((r) => r.first).join(', ')}');

    for (final table in const [
      'buildtrack_users',
      'projects',
      'tasks',
      'materials',
      'team_members',
      'timeline_steps',
    ]) {
      final count = await conn.execute('select count(*) from $table');
      stdout.writeln('  $table rows: ${count.first.first}');
    }
  } finally {
    await conn.close();
  }
}

const String kSchemaSql = '''
create table if not exists buildtrack_users (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  email text not null unique,
  password_hash text not null,
  company text not null default '',
  phone text not null default '',
  role text not null default 'Project Manager',
  created_at timestamptz not null default now()
);

create table if not exists projects (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references buildtrack_users(id) on delete cascade,
  name text not null,
  location text not null default '',
  client text not null default '',
  status text not null default 'active',
  progress integer not null default 0 check (progress between 0 and 100),
  start_date date,
  end_date date,
  budget numeric not null default 0,
  spent numeric not null default 0,
  phase text not null default '',
  members integer not null default 0,
  current_stage text not null default '',
  created_at timestamptz not null default now()
);
create index if not exists projects_user_idx on projects(user_id);

create table if not exists tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references buildtrack_users(id) on delete cascade,
  project_id uuid references projects(id) on delete set null,
  title text not null,
  team text not null default '',
  due_date date,
  due_time text not null default '',
  status text not null default 'pending',
  completed_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists tasks_user_idx on tasks(user_id);
create index if not exists tasks_project_idx on tasks(project_id);

create table if not exists materials (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references buildtrack_users(id) on delete cascade,
  project_id uuid references projects(id) on delete set null,
  name text not null,
  category text not null default '',
  quantity numeric not null default 0,
  unit text not null default '',
  status text not null default 'available',
  icon text not null default 'cube',
  created_at timestamptz not null default now()
);
create index if not exists materials_user_idx on materials(user_id);

create table if not exists team_members (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references buildtrack_users(id) on delete cascade,
  project_id uuid references projects(id) on delete set null,
  name text not null,
  role text not null default '',
  created_at timestamptz not null default now()
);
create index if not exists team_user_idx on team_members(user_id);

create table if not exists timeline_steps (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references projects(id) on delete cascade,
  name text not null,
  position integer not null default 0,
  status text not null default 'pending',
  unique (project_id, position)
);
''';

Future<({String url})> _loadConfig() async {
  final fromEnv = Platform.environment['NEON_DATABASE_URL'];
  if (fromEnv != null && fromEnv.isNotEmpty) {
    return (url: fromEnv);
  }

  final candidates = <String>['env.json', '../env.json', '../../env.json'];
  for (final path in candidates) {
    final file = File(path);
    if (!file.existsSync()) continue;
    final decoded = jsonDecode(await file.readAsString());
    final url = decoded['NEON_DATABASE_URL'];
    if (url is String && url.isNotEmpty) return (url: url);
  }
  throw StateError(
    'NEON_DATABASE_URL not found. Add env.json with {"NEON_DATABASE_URL": "..."}',
  );
}

String _sanitizeUrl(String url) {
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

String _directUrl(String url) {
  final uri = Uri.parse(url);
  final host = uri.host;
  if (!host.contains('-pooler')) return url;
  final directHost = host.replaceFirst('-pooler', '');
  return uri.replace(host: directHost).toString();
}

String _safeUrl(String url) {
  final uri = Uri.parse(url);
  final userInfo = uri.userInfo;
  final masked = userInfo.isEmpty ? '' : '${userInfo.split(':').first}:***@';
  return '${uri.scheme}://$masked${uri.host}${uri.path}';
}
