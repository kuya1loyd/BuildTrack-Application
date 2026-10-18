import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:postgres/postgres.dart';

import '../models/models.dart';
import 'database.dart';
import 'http_session.dart';
import 'password_hash.dart';

String _dateText(Object? value) {
  if (value == null) return '';
  if (value is DateTime) {
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '${value.year}-$m-$d';
  }
  return value.toString();
}

DateTime? _dateOrNull(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

String _text(Map<String, dynamic> row, String key) {
  final value = row[key];
  if (value == null) return '';
  if (value is DateTime) return _dateText(value);
  return value.toString();
}

int _int(Map<String, dynamic> row, String key) {
  final value = row[key];
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _double(Map<String, dynamic> row, String key) {
  final value = row[key];
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

class AuthRepository {
  AuthRepository._();
  static final AuthRepository instance = AuthRepository._();

  Future<UserProfile> signUp({
    required String name,
    required String email,
    required String password,
    String company = '',
    String phone = '',
    String role = 'Project Manager',
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (kIsWeb) {
      final body = await _postAuth('/auth/signup', {
        'name': name.trim(),
        'email': normalizedEmail,
        'password': password,
        'company': company.trim(),
        'phone': phone.trim(),
        'role': role,
      });
      return _userFromBridge(body);
    }

    final existing = await _findByEmail(normalizedEmail);
    if (existing != null) {
      throw const AuthException('An account with this email already exists.');
    }

    final passwordHash = PasswordHash.hash(password);

    final row = await Database.instance.use((conn) async {
      final result = await conn.execute(
        Sql.named(
          'insert into buildtrack_users (name, email, password_hash, company, phone, role) '
          'values (@name, @email, @passwordHash, @company, @phone, @role) '
          'returning id::text as id, name, email, company, phone, role',
        ),
        parameters: {
          'name': name.trim(),
          'email': normalizedEmail,
          'passwordHash': passwordHash,
          'company': company.trim(),
          'phone': phone.trim(),
          'role': role,
        },
      );
      return result.first.toColumnMap();
    });

    return UserProfile(
      id: _text(row, 'id'),
      name: _text(row, 'name'),
      email: _text(row, 'email'),
      company: _text(row, 'company'),
      phone: _text(row, 'phone'),
      role: _text(row, 'role'),
    );
  }

  Future<UserProfile?> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (kIsWeb) {
      try {
        final body = await _postAuth('/auth/signin', {
          'email': normalizedEmail,
          'password': password,
        });
        return _userFromBridge(body);
      } on AuthException {
        rethrow;
      }
    }

    final record = await _findByEmail(normalizedEmail);
    if (record == null) return null;

    final storedHash = _text(record, 'password_hash');
    if (!PasswordHash.verify(password, storedHash)) return null;

    if (PasswordHash.isLegacy(storedHash)) {
      final userId = _text(record, 'id');
      try {
        await _storePasswordHash(userId, PasswordHash.hash(password));
      } catch (_) {}
    }

    return UserProfile(
      id: _text(record, 'id'),
      name: _text(record, 'name'),
      email: _text(record, 'email'),
      company: _text(record, 'company'),
      phone: _text(record, 'phone'),
      role: _text(record, 'role'),
    );
  }

  /// Resets a password after checking that [phone] matches the number saved
  /// on the account for [email]. Throws [AuthException] when it does not.
  Future<void> resetPassword({
    required String email,
    required String phone,
    required String newPassword,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (kIsWeb) {
      await _postAuth('/auth/reset', {
        'email': normalizedEmail,
        'phone': phone.trim(),
        'password': newPassword,
      });
      return;
    }

    String digits(String v) => v.replaceAll(RegExp(r'\D'), '');
    const mismatch = AuthException(
      'Email and phone number do not match any account.',
    );
    final record = await _findByEmail(normalizedEmail);
    if (record == null) throw mismatch;
    final stored = digits(_text(record, 'phone'));
    if (stored.length < 6 || stored != digits(phone)) throw mismatch;
    await _storePasswordHash(
      _text(record, 'id'),
      PasswordHash.hash(newPassword),
    );
  }

  Future<void> _storePasswordHash(String userId, String passwordHash) async {
    await Database.instance.use((conn) async {
      await conn.execute(
        Sql.named(
          'update buildtrack_users set password_hash = @passwordHash where id = @id',
        ),
        parameters: {'id': userId, 'passwordHash': passwordHash},
      );
    });
  }

  Future<Map<String, dynamic>> _postAuth(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final response = await http
        .post(
          Uri.parse('${DbBridgeConfig.apiBaseUrl}$path'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${DbBridgeConfig.apiToken}',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 20));

    Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(response.body);
      body = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      body = <String, dynamic>{};
    }

    if (response.statusCode == 401 || response.statusCode == 409) {
      throw AuthException(body['error'] as String? ?? 'Could not sign in.');
    }
    if (response.statusCode != 200) {
      throw PostgresException(
        'The database bridge rejected this request (HTTP ${response.statusCode}).',
      );
    }

    final user = body['user'];
    if (user is! Map<String, dynamic>) {
      throw const AuthException('Could not sign in.');
    }
    return user;
  }

  UserProfile _userFromBridge(Map<String, dynamic> user) {
    return UserProfile(
      id: user['id'] as String? ?? '',
      name: user['name'] as String? ?? '',
      email: user['email'] as String? ?? '',
      company: user['company'] as String? ?? '',
      phone: user['phone'] as String? ?? '',
      role: user['role'] as String? ?? 'Project Manager',
      avatarUrl: user['avatarUrl'] as String? ?? user['avatar_url'] as String?,
    );
  }

  Future<Map<String, dynamic>?> _findByEmail(String email) async {
    return Database.instance.use((conn) async {
      final result = await conn.execute(
        Sql.named(
          'select id::text as id, name, email, password_hash, company, phone, role, avatar_url '
          'from buildtrack_users where email = @email',
        ),
        parameters: {'email': email},
      );
      if (result.isEmpty) return null;
      return result.first.toColumnMap();
    });
  }

  Future<void> updateProfile(UserProfile profile) async {
    await Database.instance.use((conn) async {
      await conn.execute(
        Sql.named(
          'update buildtrack_users set name = @name, company = @company, '
          'phone = @phone, role = @role, avatar_url = @avatarUrl where id = @id',
        ),
        parameters: {
          'id': profile.id,
          'name': profile.name,
          'company': profile.company,
          'phone': profile.phone,
          'role': profile.role,
          'avatarUrl': profile.avatarUrl,
        },
      );
    });
  }
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ProjectsRepository {
  ProjectsRepository._();
  static final ProjectsRepository instance = ProjectsRepository._();

  Future<List<Project>> fetchForUser(String userId) async {
    return Database.instance.use((conn) async {
      final result = await conn.execute(
        Sql.named(
          'select id::text as id, name, location, client, status, progress, '
          "to_char(start_date, 'YYYY-MM-DD') as start_date, "
          "to_char(end_date, 'YYYY-MM-DD') as end_date, "
          'budget, spent, phase, members, current_stage '
          'from projects where user_id = @userId order by created_at desc',
        ),
        parameters: {'userId': userId},
      );
      return result.map((row) {
        final map = row.toColumnMap();
        return Project(
          id: _text(map, 'id'),
          name: _text(map, 'name'),
          location: _text(map, 'location'),
          client: _text(map, 'client'),
          status: projectStatusFrom(_text(map, 'status')),
          progress: _int(map, 'progress'),
          startDate: _text(map, 'start_date'),
          endDate: _text(map, 'end_date'),
          budget: _double(map, 'budget'),
          spent: _double(map, 'spent'),
          phase: _text(map, 'phase'),
          members: _int(map, 'members'),
          currentStage: _text(map, 'current_stage'),
        );
      }).toList();
    });
  }

  Future<Project> insert({
    required String userId,
    required String name,
    String location = '',
    String client = '',
    ProjectStatus status = ProjectStatus.active,
    int progress = 0,
    DateTime? startDate,
    DateTime? endDate,
    double budget = 0,
    double spent = 0,
    String phase = '',
    int members = 0,
    String currentStage = '',
  }) async {
    final row = await Database.instance.use((conn) async {
      final result = await conn.execute(
        Sql.named(
          'insert into projects (user_id, name, location, client, status, progress, '
          'start_date, end_date, budget, spent, phase, members, current_stage) '
          'values (@userId, @name, @location, @client, @status, @progress, '
          '@startDate::date, @endDate::date, @budget, @spent, @phase, @members, @currentStage) '
          "returning id::text as id, name, location, client, status, progress, "
          "to_char(start_date, 'YYYY-MM-DD') as start_date, "
          "to_char(end_date, 'YYYY-MM-DD') as end_date, "
          'budget, spent, phase, members, current_stage',
        ),
        parameters: {
          'userId': userId,
          'name': name.trim(),
          'location': location.trim(),
          'client': client.trim(),
          'status': status.name,
          'progress': progress,
          'startDate': startDate == null ? null : _dateText(startDate),
          'endDate': endDate == null ? null : _dateText(endDate),
          'budget': budget,
          'spent': spent,
          'phase': phase.trim(),
          'members': members,
          'currentStage': currentStage.trim(),
        },
      );
      return result.first.toColumnMap();
    });

    return Project(
      id: _text(row, 'id'),
      name: _text(row, 'name'),
      location: _text(row, 'location'),
      client: _text(row, 'client'),
      status: projectStatusFrom(_text(row, 'status')),
      progress: _int(row, 'progress'),
      startDate: _text(row, 'start_date'),
      endDate: _text(row, 'end_date'),
      budget: _double(row, 'budget'),
      spent: _double(row, 'spent'),
      phase: _text(row, 'phase'),
      members: _int(row, 'members'),
      currentStage: _text(row, 'current_stage'),
    );
  }

  Future<void> updateProgress(
    String projectId,
    int progress,
    double spent,
  ) async {
    await Database.instance.use((conn) async {
      await conn.execute(
        Sql.named(
          'update projects set progress = @progress, spent = @spent where id = @id',
        ),
        parameters: {'progress': progress, 'spent': spent, 'id': projectId},
      );
    });
  }

  Future<void> delete(String projectId) async {
    await Database.instance.use((conn) async {
      await conn.execute(
        Sql.named('delete from projects where id = @id'),
        parameters: {'id': projectId},
      );
    });
  }
}

class TasksRepository {
  TasksRepository._();
  static final TasksRepository instance = TasksRepository._();

  Future<List<Task>> fetchForUser(String userId) async {
    return Database.instance.use((conn) async {
      final result = await conn.execute(
        Sql.named(
          'select t.id::text as id, t.title, coalesce(t.project_id::text, \'\') as project_id, '
          "coalesce(p.name, 'No project') as project_name, "
          "t.team, to_char(t.due_date, 'YYYY-MM-DD') as due_date, t.due_time, t.status "
          'from tasks t left join projects p on p.id = t.project_id '
          'where t.user_id = @userId order by t.due_date asc nulls last, t.created_at desc',
        ),
        parameters: {'userId': userId},
      );
      return result.map((row) => _taskFromRow(row.toColumnMap())).toList();
    });
  }

  Future<Task> insert({
    required String userId,
    required String title,
    String? projectId,
    String team = '',
    DateTime? dueDate,
    String dueTime = '',
    TaskStatus status = TaskStatus.pending,
  }) async {
    final row = await Database.instance.use((conn) async {
      final result = await conn.execute(
        Sql.named(
          'insert into tasks (user_id, project_id, title, team, due_date, due_time, status) '
          'values (@userId, @projectId::uuid, @title, @team, @dueDate::date, @dueTime, @status) '
          'returning id::text as id, title, coalesce(project_id::text, \'\') as project_id, '
          'team, due_time, status',
        ),
        parameters: {
          'userId': userId,
          'projectId': projectId,
          'title': title.trim(),
          'team': team.trim(),
          'dueDate': dueDate == null ? null : _dateText(dueDate),
          'dueTime': dueTime.trim(),
          'status': status.name,
        },
      );
      return result.first.toColumnMap();
    });

    final due = _dueLabel(dueDate, dueTime.trim());
    return Task(
      id: _text(row, 'id'),
      title: _text(row, 'title'),
      projectId: _text(row, 'project_id'),
      projectName: '',
      team: _text(row, 'team'),
      due: due.label,
      dueAt: due.time,
      status: taskStatusFrom(_text(row, 'status')),
      bucket: _bucket(dueDate, status),
    );
  }

  Future<void> updateStatus(String taskId, TaskStatus status) async {
    await Database.instance.use((conn) async {
      await conn.execute(
        Sql.named(
          'update tasks set status = @status, '
          "completed_at = case when @status = 'completed' then now() else null end "
          'where id = @id',
        ),
        parameters: {'status': status.name, 'id': taskId},
      );
    });
  }

  Future<void> delete(String taskId) async {
    await Database.instance.use((conn) async {
      await conn.execute(
        Sql.named('delete from tasks where id = @id'),
        parameters: {'id': taskId},
      );
    });
  }

  Task _taskFromRow(Map<String, dynamic> map) {
    final dueDate = _dateOrNull(map['due_date']);
    final status = taskStatusFrom(_text(map, 'status'));
    final dueLabel = _dueLabel(dueDate, _text(map, 'due_time'));
    return Task(
      id: _text(map, 'id'),
      title: _text(map, 'title'),
      projectId: _text(map, 'project_id'),
      projectName: _text(map, 'project_name'),
      team: _text(map, 'team'),
      due: dueLabel.label,
      dueAt: dueLabel.time,
      status: status,
      bucket: _bucket(dueDate, status),
    );
  }
}

/// Buckets a task by due date for the Today / This Week / All task views.
/// Tasks with no due date count as today's work so they always show up in the
/// default view instead of disappearing into "later".
String taskBucket(DateTime? dueDate, TaskStatus status) {
  if (status == TaskStatus.completed) return 'today';
  if (dueDate == null) return 'today';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
  final diff = due.difference(today).inDays;
  if (diff <= 0) return 'today';
  if (diff <= 7) return 'week';
  return 'later';
}

String _bucket(DateTime? dueDate, TaskStatus status) =>
    taskBucket(dueDate, status);

({String label, String time}) _dueLabel(DateTime? dueDate, String dueTime) {
  if (dueDate == null) {
    return (
      label: 'No due date',
      time: dueTime.isEmpty ? 'Set a due date' : dueTime,
    );
  }
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
  final diff = due.difference(today).inDays;
  final label = switch (diff) {
    < 0 => 'Overdue',
    0 => 'Due today',
    1 => 'Due tomorrow',
    <= 7 => 'Due this week',
    _ => 'Upcoming',
  };
  return (label: label, time: dueTime.isEmpty ? '' : dueTime);
}

class MaterialsRepository {
  MaterialsRepository._();
  static final MaterialsRepository instance = MaterialsRepository._();

  Future<List<Material>> fetchForUser(String userId) async {
    return Database.instance.use((conn) async {
      final result = await conn.execute(
        Sql.named(
          'select id::text as id, name, category, quantity, unit, status, icon '
          'from materials where user_id = @userId order by name asc',
        ),
        parameters: {'userId': userId},
      );
      return result.map((row) {
        final map = row.toColumnMap();
        return Material(
          id: _text(map, 'id'),
          name: _text(map, 'name'),
          category: _text(map, 'category'),
          quantity: _double(map, 'quantity'),
          unit: _text(map, 'unit'),
          status: stockStatusFrom(_text(map, 'status')),
          icon: _text(map, 'icon'),
        );
      }).toList();
    });
  }

  Future<Material> insert({
    required String userId,
    required String name,
    String category = '',
    double quantity = 0,
    String unit = '',
    StockStatus status = StockStatus.available,
    String icon = 'cube',
  }) async {
    final row = await Database.instance.use((conn) async {
      final result = await conn.execute(
        Sql.named(
          'insert into materials (user_id, name, category, quantity, unit, status, icon) '
          'values (@userId, @name, @category, @quantity, @unit, @status, @icon) '
          'returning id::text as id, name, category, quantity, unit, status, icon',
        ),
        parameters: {
          'userId': userId,
          'name': name.trim(),
          'category': category.trim(),
          'quantity': quantity,
          'unit': unit.trim(),
          'status': status.name,
          'icon': icon,
        },
      );
      return result.first.toColumnMap();
    });

    return Material(
      id: _text(row, 'id'),
      name: _text(row, 'name'),
      category: _text(row, 'category'),
      quantity: _double(row, 'quantity'),
      unit: _text(row, 'unit'),
      status: stockStatusFrom(_text(row, 'status')),
      icon: _text(row, 'icon'),
    );
  }

  Future<void> updateQuantity(
    String materialId,
    double quantity,
    StockStatus status,
  ) async {
    await Database.instance.use((conn) async {
      await conn.execute(
        Sql.named(
          'update materials set quantity = @quantity, status = @status where id = @id',
        ),
        parameters: {
          'quantity': quantity,
          'status': status.name,
          'id': materialId,
        },
      );
    });
  }

  Future<void> delete(String materialId) async {
    await Database.instance.use((conn) async {
      await conn.execute(
        Sql.named('delete from materials where id = @id'),
        parameters: {'id': materialId},
      );
    });
  }
}

class TeamRepository {
  TeamRepository._();
  static final TeamRepository instance = TeamRepository._();

  Future<List<TeamMember>> fetchForUser(
    String userId, {
    String? projectId,
  }) async {
    return Database.instance.use((conn) async {
      final result = await conn.execute(
        Sql.named(
          'select id::text as id, name, role, coalesce(project_id::text, \'\') as project_id '
          'from team_members where user_id = @userId '
          'and (@projectId::uuid is null or project_id = @projectId::uuid) order by created_at asc',
        ),
        parameters: {'userId': userId, 'projectId': projectId},
      );
      return result.map((row) {
        final map = row.toColumnMap();
        return TeamMember(
          id: _text(map, 'id'),
          name: _text(map, 'name'),
          role: _text(map, 'role'),
        );
      }).toList();
    });
  }

  Future<void> insert({
    required String userId,
    required String name,
    String role = '',
    String? projectId,
  }) async {
    await Database.instance.use((conn) async {
      await conn.execute(
        Sql.named(
          'insert into team_members (user_id, project_id, name, role) '
          'values (@userId, @projectId::uuid, @name, @role)',
        ),
        parameters: {
          'userId': userId,
          'projectId': projectId,
          'name': name.trim(),
          'role': role.trim(),
        },
      );
    });
  }

  Future<void> delete(String memberId) async {
    await Database.instance.use((conn) async {
      await conn.execute(
        Sql.named('delete from team_members where id = @id'),
        parameters: {'id': memberId},
      );
    });
  }
}

class TimelineRepository {
  TimelineRepository._();
  static final TimelineRepository instance = TimelineRepository._();

  Future<List<TimelineStep>> fetchForProject(String projectId) async {
    return Database.instance.use((conn) async {
      final result = await conn.execute(
        Sql.named(
          'select name, status from timeline_steps where project_id = @projectId '
          'order by position asc',
        ),
        parameters: {'projectId': projectId},
      );
      return result.map((row) {
        final map = row.toColumnMap();
        return TimelineStep(
          name: _text(map, 'name'),
          status: timelineStatusFrom(_text(map, 'status')),
        );
      }).toList();
    });
  }

  /// Inserts default steps for a project that has none yet. Unlike
  /// [replaceForProject] this does not open a transaction, because on the web
  /// bridge each request can land on a different pooled connection, which
  /// would leave the transaction dangling on another session.
  Future<void> seedSteps(String projectId, List<String> stepNames) async {
    final existing = await fetchForProject(projectId);
    if (existing.isNotEmpty) return;
    await Database.instance.use((conn) async {
      for (var i = 0; i < stepNames.length; i++) {
        await conn.execute(
          Sql.named(
            'insert into timeline_steps (project_id, name, position, status) '
            'values (@projectId, @name, @position, @status)',
          ),
          parameters: {
            'projectId': projectId,
            'name': stepNames[i],
            'position': i,
            'status': 'pending',
          },
        );
      }
    });
  }

  Future<void> replaceForProject(
    String projectId,
    List<String> stepNames,
  ) async {
    await Database.instance.use((conn) async {
      await conn.execute('begin');
      try {
        await conn.execute(
          Sql.named('delete from timeline_steps where project_id = @projectId'),
          parameters: {'projectId': projectId},
        );
        for (var i = 0; i < stepNames.length; i++) {
          await conn.execute(
            Sql.named(
              'insert into timeline_steps (project_id, name, position, status) '
              'values (@projectId, @name, @position, @status)',
            ),
            parameters: {
              'projectId': projectId,
              'name': stepNames[i],
              'position': i,
              'status': i == 0 ? 'done' : 'pending',
            },
          );
        }
        await conn.execute('commit');
      } catch (_) {
        await conn.execute('rollback');
        rethrow;
      }
    });
  }
}

class StatsRepository {
  StatsRepository._();
  static final StatsRepository instance = StatsRepository._();

  Future<Map<String, int>> weeklyCompletions(String userId) async {
    return Database.instance.use((conn) async {
      final result = await conn.execute(
        Sql.named(
          "select to_char(date_trunc('week', completed_at), 'YYYY-MM-DD') as week_start, "
          'count(*)::int as total '
          'from tasks where user_id = @userId and completed_at is not null '
          'and completed_at >= now() - interval \'9 weeks\' '
          'group by 1 order by 1',
        ),
        parameters: {'userId': userId},
      );
      return {
        for (final row in result)
          _text(row.toColumnMap(), 'week_start'): _int(
            row.toColumnMap(),
            'total',
          ),
      };
    });
  }
}
