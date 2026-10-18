import 'package:flutter/material.dart';

enum ProjectStatus { active, completed, delayed }

enum TaskStatus { pending, inProgress, completed, delayed }

enum StockStatus { available, lowStock, critical, outOfStock }

enum TimelineStatus { done, inProgress, pending }

ProjectStatus projectStatusFrom(String value) => ProjectStatus.values
    .firstWhere((e) => e.name == value, orElse: () => ProjectStatus.active);

TaskStatus taskStatusFrom(String value) => TaskStatus.values.firstWhere(
  (e) => e.name == value,
  orElse: () => TaskStatus.pending,
);

StockStatus stockStatusFrom(String value) => StockStatus.values.firstWhere(
  (e) => e.name == value,
  orElse: () => StockStatus.available,
);

TimelineStatus timelineStatusFrom(String value) => TimelineStatus.values
    .firstWhere((e) => e.name == value, orElse: () => TimelineStatus.pending);

String projectStatusLabel(ProjectStatus status) => switch (status) {
  ProjectStatus.active => 'Active',
  ProjectStatus.completed => 'Completed',
  ProjectStatus.delayed => 'Delayed',
};

String taskStatusLabel(TaskStatus status) => switch (status) {
  TaskStatus.pending => 'Pending',
  TaskStatus.inProgress => 'In Progress',
  TaskStatus.completed => 'Completed',
  TaskStatus.delayed => 'Delayed',
};

String stockStatusLabel(StockStatus status) => switch (status) {
  StockStatus.available => 'Available',
  StockStatus.lowStock => 'Low Stock',
  StockStatus.critical => 'Critical',
  StockStatus.outOfStock => 'Out of Stock',
};

String timelineStatusLabel(TimelineStatus status) => switch (status) {
  TimelineStatus.done => 'Done',
  TimelineStatus.inProgress => 'In Progress',
  TimelineStatus.pending => 'Pending',
};

Color projectStatusColor(ProjectStatus status) {
  switch (status) {
    case ProjectStatus.active:
      return successGreen;
    case ProjectStatus.completed:
      return infoBlue;
    case ProjectStatus.delayed:
      return warningAmber;
  }
}

const Color successGreen = Color(0xFF17A34A);
const Color infoBlue = Color(0xFF2563EB);
const Color warningAmber = Color(0xFFD97706);

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.company,
    required this.phone,
    required this.role,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String email;
  final String company;
  final String phone;
  final String role;
  final String? avatarUrl;

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0].toUpperCase()}${parts.last[0].toUpperCase()}';
  }

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  UserProfile copyWith({
    String? name,
    String? company,
    String? phone,
    String? role,
    String? avatarUrl,
    bool clearAvatar = false,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email,
      company: company ?? this.company,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
    );
  }
}

class Project {
  const Project({
    required this.id,
    required this.name,
    required this.location,
    required this.client,
    required this.status,
    required this.progress,
    required this.startDate,
    required this.endDate,
    required this.budget,
    required this.spent,
    required this.phase,
    required this.members,
    required this.currentStage,
  });

  final String id;
  final String name;
  final String location;
  final String client;
  final ProjectStatus status;
  final int progress;
  final String startDate;
  final String endDate;
  final double budget;
  final double spent;
  final String phase;
  final int members;
  final String currentStage;

  double get budgetUsed => budget <= 0 ? 0 : (spent / budget).clamp(0, 1);

  Project copyWith({
    String? name,
    String? location,
    String? client,
    ProjectStatus? status,
    int? progress,
    String? startDate,
    String? endDate,
    double? budget,
    double? spent,
    String? phase,
    int? members,
    String? currentStage,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      location: location ?? this.location,
      client: client ?? this.client,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      budget: budget ?? this.budget,
      spent: spent ?? this.spent,
      phase: phase ?? this.phase,
      members: members ?? this.members,
      currentStage: currentStage ?? this.currentStage,
    );
  }
}

class Task {
  const Task({
    required this.id,
    required this.title,
    required this.projectId,
    required this.projectName,
    required this.team,
    required this.due,
    required this.dueAt,
    required this.status,
    required this.bucket,
  });

  final String id;
  final String title;
  final String projectId;
  final String projectName;
  final String team;
  final String due;
  final String dueAt;
  final TaskStatus status;
  final String bucket;

  bool get isToday => bucket == 'today';

  Task copyWith({
    TaskStatus? status,
    String? bucket,
    String? team,
    String? due,
    String? dueAt,
    String? projectId,
    String? projectName,
  }) {
    return Task(
      id: id,
      title: title,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      team: team ?? this.team,
      due: due ?? this.due,
      dueAt: dueAt ?? this.dueAt,
      status: status ?? this.status,
      bucket: bucket ?? this.bucket,
    );
  }
}

class Material {
  const Material({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.status,
    required this.icon,
  });

  final String id;
  final String name;
  final String category;
  final double quantity;
  final String unit;
  final StockStatus status;
  final String icon;

  Material copyWith({
    double? quantity,
    StockStatus? status,
    String? category,
    String? icon,
  }) {
    return Material(
      id: id,
      name: name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit,
      status: status ?? this.status,
      icon: icon ?? this.icon,
    );
  }
}

class TimelineStep {
  const TimelineStep({required this.name, required this.status});

  final String name;
  final TimelineStatus status;
}

class TeamMember {
  const TeamMember({required this.id, required this.name, required this.role});

  final String id;
  final String name;
  final String role;
}
