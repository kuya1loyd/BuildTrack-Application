import 'package:buildtrack/data/repositories.dart';
import 'package:buildtrack/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the task-bucketing rules that decide which Tasks view a task shows
/// up in. Tasks that are invisible in the default "Today" view look like they
/// were never added — the original bug report.
void main() {
  final today = DateTime.now();
  final yesterday = today.subtract(const Duration(days: 1));
  final tomorrow = today.add(const Duration(days: 1));
  final nextWeek = today.add(const Duration(days: 6));
  final farFuture = today.add(const Duration(days: 30));

  test('pending tasks with no due date count as today', () {
    expect(taskBucket(null, TaskStatus.pending), 'today');
  });

  test('overdue and same-day tasks are today', () {
    expect(taskBucket(yesterday, TaskStatus.pending), 'today');
    expect(taskBucket(today, TaskStatus.pending), 'today');
  });

  test('tasks due within the week are the week bucket', () {
    expect(taskBucket(tomorrow, TaskStatus.pending), 'week');
    expect(taskBucket(nextWeek, TaskStatus.pending), 'week');
  });

  test('tasks due later than a week out are later', () {
    expect(taskBucket(farFuture, TaskStatus.pending), 'later');
  });

  test('completed tasks always show in the today view', () {
    expect(taskBucket(null, TaskStatus.completed), 'today');
    expect(taskBucket(farFuture, TaskStatus.completed), 'today');
  });

  test('in-progress and delayed tasks keep their due-date bucket', () {
    expect(taskBucket(null, TaskStatus.inProgress), 'today');
    expect(taskBucket(tomorrow, TaskStatus.delayed), 'week');
  });
}
