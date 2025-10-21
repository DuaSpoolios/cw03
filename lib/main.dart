import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const TaskApp());
}

class TaskApp extends StatefulWidget {
  const TaskApp({super.key});

  @override
  State<TaskApp> createState()=> _TaskAppState();
}

class _TaskAppState extends State<TaskApp> {
  bool isDarkMode= false;

  void toggleTheme(bool value) {
    setState(() {
      isDarkMode= value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      darkTheme: ThemeData.dark(),
      theme: ThemeData(
        primarySwatch: Colors.orange,
        brightness: Brightness.light,
      ),
      home: TaskListScreen(onThemeToggle: toggleTheme, isDarkMode: isDarkMode),
    );
  }
}
class Task {
  String name;
  bool completed;
  String priority;

  Task({required this.name, this.completed = false, this.priority = 'Low'});

  Map<String, dynamic> toJson() =>
      {'name': name, 'completed': completed,'priority': priority};

  static Task fromJson(Map<String, dynamic> json) {
    return Task(
      name: json['name'],
      completed: json['completed'],
      priority: json['priority'],
    );
  }
}

class TaskListScreen extends StatefulWidget {
  final Function(bool) onThemeToggle;
  final bool isDarkMode;

  const TaskListScreen(
      {super.key, required this.onThemeToggle, required this.isDarkMode});

  @override
  State<TaskListScreen> createState()=> _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Task> _tasks = [];
  String _selectedPriority = 'Low';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('tasks');
    if (savedData != null) {
      final List decoded= jsonDecode(savedData);
      setState(() {
        _tasks.clear();
        _tasks.addAll(decoded.map((e)=> Task.fromJson(e)).toList());
        _sortTasks();
      });
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('tasks', jsonEncode(_tasks));
  }

  void _sortTasks() {
    const priorityOrder = {'High': 0, 'Medium': 1, 'Low': 2};
    _tasks.sort((a, b)=>
        priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!));
  }

  void _addTask() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _tasks.add(Task(name: _controller.text.trim(), priority: _selectedPriority));
      _controller.clear();
      _sortTasks();
      _saveTasks();
    });
  }

  void _toggleCompletion(int index) {
    setState(() {
      _tasks[index].completed = !_tasks[index].completed;
      _saveTasks();
    });
  }

  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
      _saveTasks();
    });
  }

  void _changePriority(int index, String newPriority) {
    setState(() {
      _tasks[index].priority = newPriority;
      _sortTasks();
      _saveTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager'),
        actions: [
          Row(
            children: [
              const Icon(Icons.light_mode),
              Switch(
                value: widget.isDarkMode,
                onChanged: (val) => widget.onThemeToggle(val),
              ),
              const Icon(Icons.dark_mode),
              const SizedBox(width: 8),
            ],
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Enter Task',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _selectedPriority,
                  items: ['Low', 'Medium', 'High']
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(p),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPriority = value!;
                    });
                  },
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addTask,
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Expanded(
              child: _tasks.isEmpty
                  ? const Center(child: Text('No tasks yet.'))
                  : ListView.builder(
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        final task = _tasks[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: Checkbox(
                              value: task.completed,
                              onChanged: (_) => _toggleCompletion(index),
                            ),
                            title: Text(
                              task.name,
                              style: TextStyle(
                                decoration: task.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            subtitle: Text(
                              'Priority: ${task.priority}',
                              style: TextStyle(
                                  color: task.priority == 'High'
                                      ? Colors.red
                                      : task.priority == 'Medium'
                                          ? Colors.orange
                                          : Colors.green),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                DropdownButton<String>(
                                  value: task.priority,
                                  underline: const SizedBox(),
                                  items: ['Low', 'Medium', 'High']
                                      .map((p) => DropdownMenuItem(
                                            value: p,
                                            child: Text(p),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val!= null) {
                                      _changePriority(index, val);
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.redAccent),
                                  onPressed: ()=> _deleteTask(index),
                                ),
                              ],
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
}