import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ActivityMonitoringScreen extends StatefulWidget {
  @override
  _ActivityMonitoringScreenState createState() => _ActivityMonitoringScreenState();
}

class _ActivityMonitoringScreenState extends State<ActivityMonitoringScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedTimeRange = 'Today';
  String _selectedCategory = 'All';
  String _selectedQuadrant = 'All';

  final List<String> timeRanges = ['Today', 'This Week', 'This Month', 'All Time'];
  final List<String> categories = ['All', 'Work', 'Personal', 'Health', 'Education', 'Other'];
  final List<String> quadrants = ['All', 'Do First', 'Schedule', 'Delegate', "Don't Do"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          "Activity Monitor",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          _buildTimeRangeSelector(),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildCategoryFilter(),
                  _buildQuadrantFilter(),
                  _buildActivityStats(),
                ],
              ),
            ),
            _buildActivityList(),
          ],
        ),
      ),
    );
  }
  Widget _buildTimeRangeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: PopupMenuButton<String>(
        offset: const Offset(0, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (String value) {
          setState(() {
            _selectedTimeRange = value;
          });
        },
        child: Container(
          constraints: const BoxConstraints(maxWidth: 120),
          child: Chip(
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _selectedTimeRange,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_drop_down, size: 16),
              ],
            ),
            backgroundColor: Colors.grey[200],
            visualDensity: VisualDensity.compact,
          ),
        ),
        itemBuilder: (context) => timeRanges
            .map((range) => PopupMenuItem(
          value: range,
          child: Text(range),
        ))
            .toList(),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategory == categories[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                categories[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = selected ? categories[index] : 'All';
                });
              },
              backgroundColor: Colors.white,
              selectedColor: Theme.of(context).primaryColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuadrantFilter() {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: quadrants.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedQuadrant == quadrants[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                quadrants[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedQuadrant = selected ? quadrants[index] : 'All';
                });
              },
              backgroundColor: Colors.white,
              selectedColor: _getQuadrantColor(quadrants[index]),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredTasksStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Something went wrong');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasks = snapshot.data!.docs;
        final completedTasks = tasks.where((doc) =>
        (doc.data() as Map<String, dynamic>)['completed'] == true).length;
        final importantTasks = tasks.where((doc) =>
        (doc.data() as Map<String, dynamic>)['isImportant'] == true).length;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Total', tasks.length, Colors.blue),
                      _buildStatItem('Done', completedTasks, Colors.green),
                      _buildStatItem('Important', importantTasks, Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: tasks.isEmpty ? 0 : completedTasks / tasks.length,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredTasksStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: Center(child: Text('Something went wrong')),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final tasks = snapshot.data!.docs;

        if (tasks.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No activities found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              final task = tasks[index].data() as Map<String, dynamic>;

              // Handle null values with defaults
              final title = task['title'] as String? ?? 'Untitled Task';
              final description = task['description'] as String? ?? '';
              final category = task['category'] as String? ?? 'Uncategorized';
              final quadrant = task['quadrant'] as String? ?? 'Unspecified';
              final completed = task['completed'] as bool? ?? false;
              final time = task['time'] as String? ?? '';
              final date = (task['date'] as Timestamp?)?.toDate() ?? DateTime.now();

              return Container(
                margin: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getQuadrantColor(quadrant)
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  quadrant,
                                  style: TextStyle(
                                    color: _getQuadrantColor(quadrant),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                completed
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: completed
                                    ? Colors.green
                                    : Colors.grey[400],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              decoration: completed
                                  ? TextDecoration.lineThrough
                                  : null,
                              color:
                              completed ? Colors.grey : Colors.black87,
                            ),
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.folder_outlined,
                                  size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                category,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(Icons.access_time,
                                  size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                '${DateFormat('MMM dd').format(date)} $time',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
            childCount: tasks.length,
          ),
        );
      },
    );
  }
  Stream<QuerySnapshot> _getFilteredTasksStream() {
    Query query = _firestore.collection('tasks');

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    switch (_selectedTimeRange) {
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

    if (_selectedCategory != 'All') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    if (_selectedQuadrant != 'All') {
      query = query.where('quadrant', isEqualTo: _selectedQuadrant);
    }

    return query.orderBy('date', descending: true).snapshots();
  }

  Color _getQuadrantColor(String quadrant) {
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
        return Theme.of(context).primaryColor;
    }
  }
}