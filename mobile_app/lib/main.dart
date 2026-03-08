import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';

void main() => runApp(const MyApp());

class Student {
  final int id;
  final String name;
  final String course;
  final int age;

  Student({required this.id, required this.name, required this.course, required this.age});

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      name: json['name'],
      course: json['course'],
      age: json['age'],
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF3B82F6),
      ),
      home: const StudentPage(),
    );
  }
}

class StudentPage extends StatefulWidget {
  const StudentPage({super.key});

  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  late final String apiUrl;

  List<Student> students = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    apiUrl = _resolveApiUrl();
    fetchStudents();
  }

  String _resolveApiUrl() {
    if (kIsWeb) {
      return "http://127.0.0.1:8000/api/students/";
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return "http://10.0.2.2:8000/api/students/";
    }

    return "http://127.0.0.1:8000/api/students/";
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  // READ
  Future<void> fetchStudents() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (!mounted) return;
        setState(() => students = data.map((json) => Student.fromJson(json)).toList());
      } else {
        if (!mounted) return;
        setState(() => errorMessage = "Failed to load students (${response.statusCode}).");
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() => errorMessage = "Request timed out. Please try again.");
    } catch (_) {
      if (!mounted) return;
      setState(() => errorMessage = "Network error. Check API URL and server.");
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  // CREATE
  Future<void> createStudent(String name, String course, int age) async {
    try {
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {"Content-Type": "application/json"},
            body: json.encode({"name": name, "course": course, "age": age}),
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 201) {
        await fetchStudents();
        _showSnackBar("Student created");
      } else {
        _showSnackBar("Create failed (${response.statusCode})", isError: true);
      }
    } on TimeoutException {
      _showSnackBar("Request timed out", isError: true);
    } catch (_) {
      _showSnackBar("Network error", isError: true);
    }
  }

  // UPDATE
  Future<void> updateStudent(int id, String name, String course, int age) async {
    try {
      final response = await http
          .put(
            Uri.parse("$apiUrl$id/"),
            headers: {"Content-Type": "application/json"},
            body: json.encode({"name": name, "course": course, "age": age}),
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        await fetchStudents();
        _showSnackBar("Student updated");
      } else {
        _showSnackBar("Update failed (${response.statusCode})", isError: true);
      }
    } on TimeoutException {
      _showSnackBar("Request timed out", isError: true);
    } catch (_) {
      _showSnackBar("Network error", isError: true);
    }
  }

  // DELETE
  Future<void> deleteStudent(int id) async {
    try {
      final response = await http
          .delete(Uri.parse("$apiUrl$id/"))
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 204) {
        await fetchStudents();
        _showSnackBar("Student deleted");
      } else {
        _showSnackBar("Delete failed (${response.statusCode})", isError: true);
      }
    } on TimeoutException {
      _showSnackBar("Request timed out", isError: true);
    } catch (_) {
      _showSnackBar("Network error", isError: true);
    }
  }

  // SHOW FORM FOR CREATE / UPDATE
  void showStudentForm({Student? student}) {
    final nameController = TextEditingController(text: student?.name ?? "");
    final courseController = TextEditingController(text: student?.course ?? "");
    final ageController = TextEditingController(text: student?.age.toString() ?? "");
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(student == null ? "Add Student" : "Edit Student"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final v = value?.trim() ?? "";
                  if (v.isEmpty) return "Name is required";
                  if (v.length < 2) return "Name is too short";
                  return null;
                },
              ),
              TextFormField(
                controller: courseController,
                decoration: const InputDecoration(labelText: "Course"),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final v = value?.trim() ?? "";
                  if (v.isEmpty) return "Course is required";
                  return null;
                },
              ),
              TextFormField(
                controller: ageController,
                decoration: const InputDecoration(labelText: "Age"),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final v = value?.trim() ?? "";
                  final age = int.tryParse(v);
                  if (age == null) return "Enter a valid age";
                  if (age < 1 || age > 120) return "Age must be 1-120";
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              final name = nameController.text;
              final course = courseController.text;
              final age = int.tryParse(ageController.text) ?? 0;

              if (student == null) {
                createStudent(name, course, age);
              } else {
                updateStudent(student.id, name, course, age);
              }

              Navigator.pop(context);
            },
            child: Text(student == null ? "Create" : "Update"),
          )
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Student student) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete student?"),
        content: Text("This will permanently delete ${student.name}."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await deleteStudent(student.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget content;
    if (isLoading && students.isEmpty) {
      content = const Center(child: CircularProgressIndicator());
    } else if (errorMessage != null && students.isEmpty) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.error),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: fetchStudents,
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    } else if (students.isEmpty) {
      content = const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            "No students yet. Tap Add Student to create one.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      content = ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
        itemCount: students.length,
        itemBuilder: (context, index) {
          final student = students[index];
          return Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest,
            child: ListTile(
              title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text("${student.course} • Age ${student.age}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: "Edit",
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => showStudentForm(student: student),
                  ),
                  IconButton(
                    tooltip: "Delete",
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(student),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Students"),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "Refresh",
            onPressed: fetchStudents,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchStudents,
        child: content,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showStudentForm(),
        icon: const Icon(Icons.add),
        label: const Text("Add Student"),
      ),
    );
  }
}