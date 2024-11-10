import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  runApp(MaterialApp(
    title: 'Eisenhower Matrix Task Manager',
    theme: ThemeData(
      primarySwatch: Colors.blue,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.blue;
          }
          return Colors.grey;
        }),
      ),
    ),
    home: ActivityPrioritizationScreen(),
  ));
}

class ActivityPrioritizationScreen extends StatefulWidget {
  @override
  _ActivityPrioritizationScreenState createState() =>
      _ActivityPrioritizationScreenState();
}

class _ActivityPrioritizationScreenState extends State<ActivityPrioritizationScreen> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _showCompletedTasks = false;
  bool _isUrgent = false;
  bool _isImportant = false;
  String _selectedCategory = 'Work';
  bool _showAddTaskForm = false;

  final List<String> categories = ['Work', 'Personal', 'Health', 'Education', 'Other'];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _scheduleNotification(String task, DateTime dateTime) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.schedule(
      DateTime.now().millisecond,
      'Task Reminder',
      'Time for task: $task',
      dateTime,
      platformChannelSpecifics,
    );
  }

  String _getEisenhowerQuadrant(bool isUrgent, bool isImportant) {
    if (isImportant && isUrgent) return 'Do First';
    if (isImportant && !isUrgent) return 'Schedule';
    if (!isImportant && isUrgent) return 'Delegate';
    return 'Don\'t Do';
  }

  Future<void> _addTask() async {
    if (_taskController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }

    DateTime taskDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    String quadrant = _getEisenhowerQuadrant(_isUrgent, _isImportant);
    String formattedTime = DateFormat('HH:mm').format(taskDateTime);

    try {
      await _firestore.collection('tasks').add({
        'title': _taskController.text,
        'description': _descriptionController.text,
        'date': Timestamp.fromDate(_selectedDate),
        'time': formattedTime,
        'quadrant': quadrant,
        'isUrgent': _isUrgent,
        'isImportant': _isImportant,
        'category': _selectedCategory,
        'completed': false,
        'createdAt': Timestamp.now(),
      });

      await _scheduleNotification(_taskController.text, taskDateTime);

      _taskController.clear();
      _descriptionController.clear();
      setState(() {
        _isUrgent = false;
        _isImportant = false;
        _selectedCategory = 'Work';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding task: $e')),
      );
    }
  }

  Color _getQuadrantColor(String quadrant) {
    switch (quadrant) {
      case 'Do First':
        return Colors.red.shade100;
      case 'Schedule':
        return Colors.blue.shade100;
      case 'Delegate':
        return Colors.yellow.shade100;
      case 'Don\'t Do':
        return Colors.grey.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Eisenhower Matrix",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showCompletedTasks ? Icons.check_circle : Icons.check_circle_outline,
            ),
            onPressed: () => setState(() => _showCompletedTasks = !_showCompletedTasks),
          ),
        ],
      ),
      body: _showAddTaskForm ? _buildAddTaskForm() : _buildMatrix(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _showAddTaskForm = !_showAddTaskForm),
        child: Icon(_showAddTaskForm ? Icons.close : Icons.add),
      ),
    );
  }

  Widget _buildAddTaskForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'New Task',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _taskController,
                    decoration: InputDecoration(
                      labelText: 'Task Title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _buildDateTimePickers(),
                  const SizedBox(height: 16),
                  _buildTaskProperties(),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      _addTask();
                      setState(() => _showAddTaskForm = false);
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Add Task'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimePickers() {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(
                DateFormat('MMM dd, yyyy').format(_selectedDate),
                style: const TextStyle(fontSize: 14),
              ),
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Card(
            child: ListTile(
              leading: const Icon(Icons.access_time),
              title: Text(
                _selectedTime.format(context),
                style: const TextStyle(fontSize: 14),
              ),
              onTap: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (picked != null) {
                  setState(() => _selectedTime = picked);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskProperties() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
          ),
          items: categories.map((category) => DropdownMenuItem(
            value: category,
            child: Text(category),
          )).toList(),
          onChanged: (value) => setState(() => _selectedCategory = value!),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Important'),
          subtitle: const Text('This task is crucial for achieving goals'),
          value: _isImportant,
          onChanged: (value) => setState(() => _isImportant = value),
        ),
        SwitchListTile(
          title: const Text('Urgent'),
          subtitle: const Text('This task requires immediate attention'),
          value: _isUrgent,
          onChanged: (value) => setState(() => _isUrgent = value),
        ),
      ],
    );
  }

  Widget _buildMatrix() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('tasks').orderBy('date').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasks = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _showCompletedTasks || !data['completed'];
        }).toList();

        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  _buildQuadrantCard(
                    tasks,
                    'Do First',
                    'Important & Urgent',
                    Colors.red.shade100,
                  ),
                  _buildQuadrantCard(
                    tasks,
                    'Schedule',
                    'Important & Not Urgent',
                    Colors.blue.shade100,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  _buildQuadrantCard(
                    tasks,
                    'Delegate',
                    'Not Important & Urgent',
                    Colors.yellow.shade100,
                  ),
                  _buildQuadrantCard(
                    tasks,
                    'Don\'t Do',
                    'Not Important & Not Urgent',
                    Colors.grey.shade100,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuadrantCard(
      List<QueryDocumentSnapshot> tasks,
      String quadrant,
      String description,
      Color color,
      ) {
    final quadrantTasks = tasks.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['quadrant'] == quadrant;
    }).toList();

    return Expanded(
      child: Card(
        margin: const EdgeInsets.all(8),
        color: color,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(
                    quadrant,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: quadrantTasks.length,
                itemBuilder: (context, index) {
                  final doc = quadrantTasks[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final date = (data['date'] as Timestamp).toDate();

                  return Dismissible(
                    key: Key(doc.id),
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) async {
                      await _firestore.collection('tasks').doc(doc.id).delete();
                    },
                    child: Card(
                      child: ListTile(
                        leading: IconButton(
                          icon: Icon(
                            data['completed']
                                ? Icons.check_circle
                                : Icons.check_circle_outline,
                            color: data['completed'] ? Colors.green : Colors.grey,
                          ),
                          onPressed: () async {
                            await _firestore
                                .collection('tasks')
                                .doc(doc.id)
                                .update({'completed': !data['completed']});
                          },
                        ),
                        title: Text(
                          data['title'],
                          style: TextStyle(
                            decoration: data['completed']
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: Text(
                          '${DateFormat('MMM dd, yyyy').format(date)} ${data['time']}',
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _taskController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

extension on FlutterLocalNotificationsPlugin {
  Future<void> schedule(
      int millisecond,
      String title,
      String body,
      DateTime scheduledDate,
      NotificationDetails notificationDetails,
      ) async {
    final Int64List vibrationPattern = Int64List(4);
    vibrationPattern[0] = 0;
    vibrationPattern[1] = 1000;
    vibrationPattern[2] = 5000;
    vibrationPattern[3] = 2000;

    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      icon: '@mipmap/ic_launcher',
      importance: Importance.max,
      priority: Priority.high,
      enableLights: true,
      color: const Color.fromARGB(255, 255, 0, 0),
      ledColor: const Color.fromARGB(255, 255, 0, 0),
      ledOnMs: 1000,
      ledOffMs: 500,
      enableVibration: true,
      vibrationPattern: vibrationPattern,
    );

    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await zonedSchedule(
      millisecond,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
