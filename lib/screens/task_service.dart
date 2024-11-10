import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Shared filter states
  String selectedTimeRange = 'Today';
  String selectedCategory = 'All';
  String selectedQuadrant = 'All';

  // Get filtered tasks for Activity Monitor
  Stream<QuerySnapshot> getFilteredTasksStream() {
    Query query = _firestore.collection('tasks');

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    switch (selectedTimeRange) {
      case 'Today':
        query = query.where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay));
        break;
      case 'This Week':
        final startOfWeek =
        startOfDay.subtract(Duration(days: startOfDay.weekday - 1));
        query = query.where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek));
        break;
      case 'This Month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        query = query.where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth));
        break;
    }

    if (selectedCategory != 'All') {
      query = query.where('category', isEqualTo: selectedCategory);
    }

    if (selectedQuadrant != 'All') {
      query = query.where('quadrant', isEqualTo: selectedQuadrant);
    }

    return query.orderBy('date', descending: true).snapshots();
  }

  // Get tasks for Daily Routines
  Future<Map<String, List<QueryDocumentSnapshot>>> getWeeklyTasks(DateTime selectedDate) async {
    DateTime startOfWeek = selectedDate.subtract(
      Duration(days: selectedDate.weekday - 1),
    );
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

    final startTimestamp = Timestamp.fromDate(startOfWeek);
    final endTimestamp = Timestamp.fromDate(endOfWeek.add(const Duration(days: 1)));

    try {
      final QuerySnapshot taskSnapshot = await _firestore
          .collection('tasks')
          .where('date', isGreaterThanOrEqualTo: startTimestamp)
          .where('date', isLessThan: endTimestamp)
          .orderBy('date')
          .orderBy('time')
          .get();

      return _groupTasksByDate(taskSnapshot.docs);
    } catch (e) {
      if (_isIndexingError(e)) {
        // Handle non-indexed query
        final QuerySnapshot taskSnapshot = await _firestore
            .collection('tasks')
            .where('date', isGreaterThanOrEqualTo: startTimestamp)
            .where('date', isLessThan: endTimestamp)
            .get();

        return _groupTasksByDate(taskSnapshot.docs, shouldSort: true);
      }
      rethrow;
    }
  }

  bool _isIndexingError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('failed-precondition') ||
        errorString.contains('requires an index');
  }

  Map<String, List<QueryDocumentSnapshot>> _groupTasksByDate(
      List<QueryDocumentSnapshot> docs, {
        bool shouldSort = false,
      }) {
    if (shouldSort) {
      docs.sort((a, b) {
        final dateA = (a.data() as Map<String, dynamic>)['date'] as Timestamp;
        final dateB = (b.data() as Map<String, dynamic>)['date'] as Timestamp;
        final timeA = (a.data() as Map<String, dynamic>)['time'] as String;
        final timeB = (b.data() as Map<String, dynamic>)['time'] as String;

        final dateCompare = dateA.compareTo(dateB);
        if (dateCompare != 0) return dateCompare;
        return timeA.compareTo(timeB);
      });
    }

    Map<String, List<QueryDocumentSnapshot>> grouped = {};
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      if (!grouped.containsKey(dateStr)) {
        grouped[dateStr] = [];
      }
      grouped[dateStr]!.add(doc);
    }

    return grouped;
  }

  // Shared utilities
  Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return Colors.red[700]!;
      case 'high':
        return Colors.orange[700]!;
      case 'medium':
        return Colors.yellow[700]!;
      case 'low':
        return Colors.green[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'work':
        return Colors.blue[50]!;
      case 'personal':
        return Colors.purple[50]!;
      case 'health':
        return Colors.teal[50]!;
      case 'education':
        return Colors.indigo[50]!;
      default:
        return Colors.grey[50]!;
    }
  }

  Color getQuadrantColor(String quadrant) {
    switch (quadrant) {
      case 'Do First':
        return Colors.red;
      case 'Schedule':
        return Colors.blue;
      case 'Delegate':
        return Colors.orange;
      case "Don't Do":
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  // CRUD operations
  Future<void> updateTaskCompletion(String taskId, bool completed) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'completed': completed
    });
  }

  Future<void> deleteTask(String taskId) async {
    await _firestore.collection('tasks').doc(taskId).delete();
  }
}