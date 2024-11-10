import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'task_service.dart';

class DailyRoutinesScreen extends StatefulWidget {
  const DailyRoutinesScreen({Key? key}) : super(key: key);

  @override
  _DailyRoutinesScreenState createState() => _DailyRoutinesScreenState();
}

class _DailyRoutinesScreenState extends State<DailyRoutinesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime _selectedDate = DateTime.now();
  Map<String, List<QueryDocumentSnapshot>> _groupedTasks = {};
  bool _isLoading = false;
  String? _errorMessage;
  bool _isIndexing = false;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isIndexing = false;
    });

    try {
      DateTime startOfWeek = _selectedDate.subtract(
        Duration(days: _selectedDate.weekday - 1),
      );
      DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

      final startTimestamp = Timestamp.fromDate(startOfWeek);
      final endTimestamp = Timestamp.fromDate(endOfWeek.add(const Duration(days: 1)));

      QuerySnapshot taskSnapshot;

      try {
        taskSnapshot = await _firestore
            .collection('tasks')
            .where('date', isGreaterThanOrEqualTo: startTimestamp)
            .where('date', isLessThan: endTimestamp)
            .orderBy('date')
            .orderBy('time')
            .get();
      } catch (e) {
        if (e.toString().contains('failed-precondition') ||
            e.toString().contains('requires an index')) {
          setState(() {
            _isIndexing = true;
          });

          taskSnapshot = await _firestore
              .collection('tasks')
              .where('date', isGreaterThanOrEqualTo: startTimestamp)
              .where('date', isLessThan: endTimestamp)
              .get();

          Map<String, List<QueryDocumentSnapshot>> grouped = {};

          var sortedDocs = taskSnapshot.docs.toList()
            ..sort((a, b) {
              final dateA = (a.data() as Map<String, dynamic>)['date'] as Timestamp;
              final dateB = (b.data() as Map<String, dynamic>)['date'] as Timestamp;
              final timeA = (a.data() as Map<String, dynamic>)['time'] as String;
              final timeB = (b.data() as Map<String, dynamic>)['time'] as String;

              final dateCompare = dateA.compareTo(dateB);
              if (dateCompare != 0) return dateCompare;
              return timeA.compareTo(timeB);
            });

          for (var doc in sortedDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final date = (data['date'] as Timestamp).toDate();
            final dateStr = DateFormat('yyyy-MM-dd').format(date);

            if (!grouped.containsKey(dateStr)) {
              grouped[dateStr] = [];
            }
            grouped[dateStr]!.add(doc);
          }

          setState(() {
            _groupedTasks = grouped;
          });
          return;
        } else {
          rethrow;
        }
      }

      Map<String, List<QueryDocumentSnapshot>> grouped = {};
      for (var doc in taskSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final date = (data['date'] as Timestamp).toDate();
        final dateStr = DateFormat('yyyy-MM-dd').format(date);

        if (!grouped.containsKey(dateStr)) {
          grouped[dateStr] = [];
        }
        grouped[dateStr]!.add(doc);
      }

      setState(() {
        _groupedTasks = grouped;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Unable to load tasks. Please try again.';
      });
      _showErrorSnackBar(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _fetchTasks,
        ),
      ),
    );
  }

  Widget _buildIndexingWarning() {
    if (!_isIndexing) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.shade100.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Optimizing database. Some features may be slower than usual.',
              style: TextStyle(
                color: Colors.orange.shade900,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
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

  Color _getCategoryColor(String category) {
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

  void _showTaskDetails(Map<String, dynamic> data, String taskId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildTaskModalHeader(data),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildTaskModalDetail('Description', data['description'] ?? 'No description'),
                          const SizedBox(height: 20),
                          _buildTaskModalDetail('Category', data['category']),
                          const SizedBox(height: 20),
                          _buildTaskModalDetail('Priority', data['priority']),
                          const SizedBox(height: 20),
                          _buildTaskModalDetail('Time', data['time']),
                          const SizedBox(height: 24),
                          _buildTaskModalActions(taskId, data),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskModalHeader(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: _getCategoryColor(data['category']),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  data['title'],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getPriorityColor(data['priority']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getPriorityColor(data['priority']).withOpacity(0.3),
              ),
            ),
            child: Text(
              data['priority'],
              style: TextStyle(
                color: _getPriorityColor(data['priority']),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskModalDetail(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskModalActions(String taskId, Map<String, dynamic> data) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _editTask(taskId, data),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _deleteTask(taskId),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[50],
              foregroundColor: Colors.red[700],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _editTask(String taskId, Map<String, dynamic> data) async {
    Navigator.pop(context);
    final result = await Navigator.pushNamed(
      context,
      '/edit-task',
      arguments: {'taskId': taskId, 'taskData': data},
    );

    if (result == true) {
      _fetchTasks();
    }
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).delete();
      Navigator.pop(context);
      _fetchTasks();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Task deleted successfully'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      _showErrorSnackBar('Failed to delete task');
    }
  }

  Future<void> _navigateToAddTask() async {
    final result = await Navigator.pushNamed(context, '/add-task');
    if (result == true) {
      _fetchTasks();
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Weekly Schedule',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 20,
          ),
        ),
        actions: [
    IconButton(
    icon: Icon(Icons.calendar_today, color: Colors.blue[700]),
    onPressed: () async {
    final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: _selectedDate,
    firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[700]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchTasks();
    }
    },
    ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.blue[700]),
            onPressed: _fetchTasks,
          ),
          const SizedBox(width: 8),
        ],
    );
  }

  Widget _buildWeekHeader() {
    final startOfWeek = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${DateFormat('MMM d').format(startOfWeek)} - ${DateFormat('MMM d').format(endOfWeek)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(7, (index) {
                final date = startOfWeek.add(Duration(days: index));
                final isSelected = DateFormat('yyyy-MM-dd').format(date) ==
                    DateFormat('yyyy-MM-dd').format(_selectedDate);
                final isToday = DateFormat('yyyy-MM-dd').format(date) ==
                    DateFormat('yyyy-MM-dd').format(DateTime.now());

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                  child: Container(
                    width: 45,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue[700]
                          : (isToday ? Colors.blue[50] : Colors.transparent),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('E').format(date)[0],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : (isToday ? Colors.blue[700] : Colors.grey[600]),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date.day.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : (isToday ? Colors.blue[700] : Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final tasks = _groupedTasks[dateStr] ?? [];

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks for this day',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _navigateToAddTask,
              icon: Icon(Icons.add, color: Colors.blue[700]),
              label: Text(
                'Add Task',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final data = tasks[index].data() as Map<String, dynamic>;
        return _buildTaskCard(data, tasks[index].id);
      },
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> data, String taskId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showTaskDetails(data, taskId),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[100]!),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(data['category']),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      data['category'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(data['priority']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.flag,
                      size: 16,
                      color: _getPriorityColor(data['priority']),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                data['title'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  decoration: data['completed'] == true
                      ? TextDecoration.lineThrough
                      : null,
                  color: data['completed'] == true
                      ? Colors.grey[500]
                      : Colors.black,
                ),
              ),
              if (data['description']?.isNotEmpty ?? false) ...[
                const SizedBox(height: 8),
                Text(
                  data['description'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    data['time'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Transform.scale(
                    scale: 0.9,
                    child: Checkbox(
                      value: data['completed'] ?? false,
                      onChanged: (value) async {
                        await _firestore
                            .collection('tasks')
                            .doc(taskId)
                            .update({'completed': value});
                        _fetchTasks();
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchTasks,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red[700],
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildIndexingWarning(),
        _buildWeekHeader(),
        Expanded(
          child: _buildTaskList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTask,
        backgroundColor: Colors.blue[700],
        child: const Icon(Icons.add),
        elevation: 2,
      ),
    );
  }
}

// Extension methods
extension DateTimeExtension on DateTime {
  DateTime get startOfDay => DateTime(year, month, day);
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);
}