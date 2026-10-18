import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/repositories.dart';
import '../data/database.dart';
import '../models/models.dart';

const _kSessionKey = 'buildtrack.session.v1';
const _kLastActivityKey = 'buildtrack.last_activity.v1';
const _sessionTimeoutDuration = Duration(minutes: 30); // 30 minutes timeout

class AppState extends ChangeNotifier {
  AppState();

  UserProfile? _user;
  bool _booting = true;
  bool _loading = false;
  String? _error;

  List<Project> _projects = const [];
  List<Task> _tasks = const [];
  List<Material> _materials = const [];
  List<TeamMember> _team = const [];
  final Map<String, List<TimelineStep>> _timelines = {};
  final Map<String, List<TeamMember>> _projectTeams = {};
  Map<String, int> _weeklyCompletions = const {};

  UserProfile? get user => _user;
  bool get booting => _booting;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasUser => _user != null;

  List<Project> get projects => _projects;
  List<Task> get tasks => _tasks;
  List<Material> get materials => _materials;
  List<TeamMember> get team => _team;
  Map<String, int> get weeklyCompletions => _weeklyCompletions;

  String? _selectedProjectId;
  String? get selectedProjectId =>
      _selectedProjectId ?? (_projects.isNotEmpty ? _projects.first.id : null);

  Project? get selectedProject {
    final id = selectedProjectId;
    if (id == null) return null;
    for (final project in _projects) {
      if (project.id == id) return project;
    }
    return null;
  }

  List<Project> get activeProjects =>
      _projects.where((p) => p.status == ProjectStatus.active).toList();

  int get totalWorkers =>
      _team.length + _projects.fold<int>(0, (sum, p) => sum + p.members);

  int get openIssues =>
      _tasks.where((t) => t.status == TaskStatus.delayed).length +
      _materials
          .where(
            (m) =>
                m.status == StockStatus.critical ||
                m.status == StockStatus.lowStock,
          )
          .length;

  int get overallProgress {
    if (_projects.isEmpty) return 0;
    final sum = _projects.fold<int>(0, (sum, p) => sum + p.progress);
    return (sum / _projects.length).round();
  }

  double get totalBudgetUsed {
    if (_projects.isEmpty) return 0;
    final budget = _projects.fold<double>(0, (sum, p) => sum + p.budget);
    if (budget <= 0) return 0;
    final spent = _projects.fold<double>(0, (sum, p) => sum + p.spent);
    return spent / budget;
  }

  List<Task> get todayTasks => _tasks
      .where((t) => t.bucket == 'today' && t.status != TaskStatus.completed)
      .toList();

  List<TimelineStep> timelineFor(String projectId) =>
      _timelines[projectId] ?? const [];

  List<TeamMember> projectTeamFor(String projectId) =>
      _projectTeams[projectId] ?? const [];

   Future<void> boot() async {
     await _restoreSession();
     _checkSessionTimeout();
     _booting = false;
     notifyListeners();
     if (hasUser) {
       _warmDatabase();
       await refresh();
     }
   }

  void _warmDatabase() {
    if (kIsWeb) return;
    Database.instance.connection.ignore();
  }

   Future<void> _restoreSession() async {
     final prefs = await SharedPreferences.getInstance();
     final raw = prefs.getString(_kSessionKey);
     if (raw == null) return;
     try {
       final map = jsonDecode(raw) as Map<String, dynamic>;
       _user = UserProfile(
         id: map['id'] as String,
         name: map['name'] as String,
         email: map['email'] as String,
         company: map['company'] as String? ?? '',
         phone: map['phone'] as String? ?? '',
         role: map['role'] as String? ?? 'Project Manager',
         avatarUrl: map['avatarUrl'] as String?,
       );
       await _updateLastActivity();
     } catch (_) {
       await prefs.remove(_kSessionKey);
       await prefs.remove(_kLastActivityKey);
     }
   }

   Future<void> _persistSession(UserProfile user) async {
     final prefs = await SharedPreferences.getInstance();
     await prefs.setString(
       _kSessionKey,
       jsonEncode({
         'id': user.id,
         'name': user.name,
         'email': user.email,
         'company': user.company,
         'phone': user.phone,
         'role': user.role,
         'avatarUrl': user.avatarUrl,
       }),
     );
     await _updateLastActivity();
   }

   Future<void> _updateLastActivity() async {
     final prefs = await SharedPreferences.getInstance();
     await prefs.setInt(
       _kLastActivityKey,
       DateTime.now().millisecondsSinceEpoch,
     );
   }

   void _checkSessionTimeout() {
     if (!hasUser) return;
     
     SharedPreferences.getInstance().then((prefs) {
       final lastActivityMillis = prefs.getInt(_kLastActivityKey) ?? 0;
       final lastActivity = DateTime.fromMillisecondsSinceEpoch(lastActivityMillis);
       final now = DateTime.now();
       
       if (now.difference(lastActivity) > _sessionTimeoutDuration) {
         signOut();
       }
     });
   }

  Future<void> signIn({required String email, required String password}) async {
    _setLoading(true, clearError: true);
    try {
      final user = await AuthRepository.instance.signIn(
        email: email,
        password: password,
      );
      if (user == null) {
        throw const AuthException('Wrong email, phone number, or password.');
      }
      _user = user;
      await _persistSession(user);
      notifyListeners();
      await refresh();
    } on AuthException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      _error = _friendlyError(e);
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    String company = '',
    String phone = '',
  }) async {
    _setLoading(true, clearError: true);
    try {
      final user = await AuthRepository.instance.signUp(
        name: name,
        email: email,
        password: password,
        company: company,
        phone: phone,
      );
      _user = user;
      await _persistSession(user);
      notifyListeners();
      _projects = const [];
      _tasks = const [];
      _materials = const [];
      _team = const [];
      notifyListeners();
    } on AuthException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      _error = _friendlyError(e);
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSessionKey);
    _user = null;
    _projects = const [];
    _tasks = const [];
    _materials = const [];
    _team = const [];
    _timelines.clear();
    _projectTeams.clear();
    _weeklyCompletions = const {};
    _error = null;
    notifyListeners();
  }

  Future<void> updateProfile(UserProfile profile) async {
    final current = _user;
    if (current == null || current.id != profile.id) return;
    _setLoading(true, clearError: true);
    try {
      await AuthRepository.instance.updateProfile(profile);
      _user = profile;
      await _persistSession(profile);
      notifyListeners();
    } catch (e) {
      _error = _friendlyError(e);
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh() async {
    final user = _user;
    if (user == null) return;
    _setLoading(true, clearError: true);
    try {
      // Fetched sequentially on purpose: a pooled remote database like Neon
      // has a limited connection budget, and parallel queries exhaust the
      // client-side pool and time out.
      final projects = await ProjectsRepository.instance.fetchForUser(user.id);
      final tasks = await TasksRepository.instance.fetchForUser(user.id);
      final materials = await MaterialsRepository.instance.fetchForUser(user.id);
      final team = await TeamRepository.instance.fetchForUser(user.id);
      final weekly = await StatsRepository.instance.weeklyCompletions(user.id);

      _projects = projects;
      _tasks = tasks;
      _materials = materials;
      _team = team;
      _weeklyCompletions = weekly;
      _error = null;
      await _updateLastActivity();
      notifyListeners();

      await _loadProjectDetails();
    } catch (e) {
      _error = _friendlyError(e);
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadProjectDetails() async {
    final user = _user;
    if (user == null) return;
    // Sequential to stay within the pooled database's connection budget.
    for (final project in List<Project>.of(_projects)) {
      final timeline = await TimelineRepository.instance.fetchForProject(
        project.id,
      );
      final team = await TeamRepository.instance.fetchForUser(
        user.id,
        projectId: project.id,
      );
      _timelines[project.id] = timeline;
      _projectTeams[project.id] = team;
    }
    notifyListeners();
  }

  void selectProject(String projectId) {
    _selectedProjectId = projectId;
    notifyListeners();
  }

  /// Records real usage so the 30-minute session timeout is measured from the
  /// last interaction instead of the last sign-in/refresh. Without this a
  /// reload after 30 minutes of normal use signs the user out unexpectedly.
  Future<void> noteActivity() async {
    if (!hasUser) return;
    await _updateLastActivity();
  }

  static const _defaultStages = [
    'Foundation',
    'Structure',
    'Systems',
    'Finishing',
  ];

  Future<void> addProject({
    required String name,
    String location = '',
    String client = '',
    DateTime? startDate,
    DateTime? endDate,
    double budget = 0,
    String phase = '',
    int members = 0,
  }) async {
    final user = _user;
    if (user == null) return;
    _setLoading(true, clearError: true);
    try {
      final project = await ProjectsRepository.instance.insert(
        userId: user.id,
        name: name,
        location: location,
        client: client,
        startDate: startDate,
        endDate: endDate,
        budget: budget,
        phase: phase,
        members: members,
      );
      _projects = [project, ..._projects];
      _selectedProjectId ??= project.id;
      // New projects would otherwise show an empty Project Timeline, since
      // nothing in the UI can create steps. Seed the standard stages.
      try {
        await TimelineRepository.instance.seedSteps(
          project.id,
          _defaultStages,
        );
        final seeded = await TimelineRepository.instance.fetchForProject(
          project.id,
        );
        _timelines[project.id] = seeded;
      } catch (_) {
        // Timeline seeding is cosmetic — never block project creation.
      }
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = _friendlyError(e);
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProjectProgress(
    String projectId,
    int progress,
    double spent,
  ) async {
    final index = _projects.indexWhere((p) => p.id == projectId);
    if (index == -1) return;
    final previous = _projects[index];
    final updated = previous.copyWith(progress: progress, spent: spent);
    _projects = [..._projects]..[index] = updated;
    notifyListeners();
    try {
      await ProjectsRepository.instance.updateProgress(
        projectId,
        progress,
        spent,
      );
    } catch (e) {
      _projects = [..._projects]..[index] = previous;
      _error = _friendlyError(e);
      notifyListeners();
    }
  }

  Future<void> deleteProject(String projectId) async {
    _projects = _projects.where((p) => p.id != projectId).toList();
    notifyListeners();
    try {
      await ProjectsRepository.instance.delete(projectId);
    } catch (e) {
      _error = _friendlyError(e);
      notifyListeners();
      await refresh();
    }
  }

  Future<void> addTask({
    required String title,
    String? projectId,
    String team = '',
    DateTime? dueDate,
    String dueTime = '',
  }) async {
    final user = _user;
    if (user == null) return;
    try {
      final task = await TasksRepository.instance.insert(
        userId: user.id,
        title: title,
        projectId: projectId ?? selectedProjectId,
        team: team,
        dueDate: dueDate,
        dueTime: dueTime,
      );
      final resolvedName = task.projectId.isEmpty
          ? 'No project'
          : _projects
                .firstWhere(
                  (p) => p.id == task.projectId,
                  orElse: () => _projects.first,
                )
                .name;
      final resolved = Task(
        id: task.id,
        title: task.title,
        projectId: task.projectId,
        projectName: resolvedName,
        team: task.team,
        due: task.due,
        dueAt: task.dueAt,
        status: task.status,
        bucket: task.bucket,
      );
      _tasks = [resolved, ..._tasks];
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = _friendlyError(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setTaskStatus(String taskId, TaskStatus status) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;
    final previous = _tasks[index];
    _tasks = [..._tasks]..[index] = previous.copyWith(status: status);
    notifyListeners();
    try {
      await TasksRepository.instance.updateStatus(taskId, status);
    } catch (e) {
      _tasks = [..._tasks]..[index] = previous;
      _error = _friendlyError(e);
      notifyListeners();
    }
  }

  Future<void> deleteTask(String taskId) async {
    _tasks = _tasks.where((t) => t.id != taskId).toList();
    notifyListeners();
    try {
      await TasksRepository.instance.delete(taskId);
    } catch (e) {
      _error = _friendlyError(e);
      notifyListeners();
      await refresh();
    }
  }

  Future<void> addMaterial({
    required String name,
    String category = '',
    double quantity = 0,
    String unit = '',
    StockStatus status = StockStatus.available,
    String icon = 'cube',
  }) async {
    final user = _user;
    if (user == null) return;
    try {
      final material = await MaterialsRepository.instance.insert(
        userId: user.id,
        name: name,
        category: category,
        quantity: quantity,
        unit: unit,
        status: status,
        icon: icon,
      );
      _materials = [..._materials, material]
        ..sort((a, b) => a.name.compareTo(b.name));
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = _friendlyError(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateMaterialQuantity(
    String materialId,
    double quantity,
    StockStatus status,
  ) async {
    final index = _materials.indexWhere((m) => m.id == materialId);
    if (index == -1) return;
    final previous = _materials[index];
    _materials = [..._materials]
      ..[index] = previous.copyWith(quantity: quantity, status: status);
    notifyListeners();
    try {
      await MaterialsRepository.instance.updateQuantity(
        materialId,
        quantity,
        status,
      );
    } catch (e) {
      _materials = [..._materials]..[index] = previous;
      _error = _friendlyError(e);
      notifyListeners();
    }
  }

  Future<void> deleteMaterial(String materialId) async {
    _materials = _materials.where((m) => m.id != materialId).toList();
    notifyListeners();
    try {
      await MaterialsRepository.instance.delete(materialId);
    } catch (e) {
      _error = _friendlyError(e);
      notifyListeners();
      await refresh();
    }
  }

  Future<void> addTeamMember({
    required String name,
    String role = '',
    String? projectId,
  }) async {
    final user = _user;
    if (user == null) return;
    try {
      await TeamRepository.instance.insert(
        userId: user.id,
        name: name,
        role: role,
        projectId: projectId,
      );
      await _loadProjectDetails();
      final team = await TeamRepository.instance.fetchForUser(user.id);
      _team = team;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = _friendlyError(e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> saveTimeline(String projectId, List<String> steps) async {
    try {
      await TimelineRepository.instance.replaceForProject(projectId, steps);
      final timeline = await TimelineRepository.instance.fetchForProject(
        projectId,
      );
      _timelines[projectId] = timeline;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = _friendlyError(e);
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value, {bool clearError = false}) {
    _loading = value;
    if (clearError) _error = null;
  }

  String _friendlyError(Object error) {
    if (error is DbNotConfiguredException) {
      return 'Database not configured. Run with --dart-define-from-file=env.json.';
    }
    final text = error.toString();
    if (text.contains('SocketException') || text.contains('timed out')) {
      return 'Cannot reach the database. Check your connection.';
    }
    if (text.length > 220) return '${text.substring(0, 220)}…';
    return text;
  }
}
