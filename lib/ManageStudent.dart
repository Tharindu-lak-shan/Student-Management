import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageStudent extends StatefulWidget {
  const ManageStudent({super.key});

  @override
  State<ManageStudent> createState() => _ManageStudentState();
}

class _ManageStudentState extends State<ManageStudent> {
  final CollectionReference students = FirebaseFirestore.instance.collection(
    'students',
  );

  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController courseController = TextEditingController();

  // 🔹 Add Student
  Future<void> addStudent() async {
    if (nameController.text.isEmpty ||
        ageController.text.isEmpty ||
        courseController.text.isEmpty)
      return;

    await students.add({
      'name': nameController.text,
      'age': ageController.text,
      'course': courseController.text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    clearFields();
    Navigator.pop(context);
  }

  // 🔹 Update Student
  Future<void> updateStudent(String docId) async {
    await students.doc(docId).update({
      'name': nameController.text,
      'age': ageController.text,
      'course': courseController.text,
    });

    clearFields();
    Navigator.pop(context);
  }

  // 🔹 Delete Student
  Future<void> deleteStudent(String docId) async {
    await students.doc(docId).delete();
  }

  // 🔹 Clear input fields
  void clearFields() {
    nameController.clear();
    ageController.clear();
    courseController.clear();
  }

  // 🔹 Show Add / Update Dialog
  void showStudentDialog({String? docId, Map<String, dynamic>? data}) {
    if (data != null) {
      nameController.text = data['name'];
      ageController.text = data['age'];
      courseController.text = data['course'];
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(docId == null ? "Add Student" : "Update Student"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: ageController,
                decoration: const InputDecoration(labelText: "Age"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: courseController,
                decoration: const InputDecoration(labelText: "Course"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              clearFields();
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (docId == null) {
                addStudent();
              } else {
                updateStudent(docId);
              }
            },
            child: Text(docId == null ? "Add" : "Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Students")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showStudentDialog(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder(
        stream: students.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var studentList = snapshot.data!.docs;

          if (studentList.isEmpty) {
            return const Center(child: Text("No Students Found"));
          }

          return ListView.builder(
            itemCount: studentList.length,
            itemBuilder: (context, index) {
              var data = studentList[index].data() as Map<String, dynamic>;
              var docId = studentList[index].id;

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(data['name'] ?? ''),
                  subtitle: Text(
                    "Age: ${data['age']} | Course: ${data['course']}",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ✏️ Edit
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () =>
                            showStudentDialog(docId: docId, data: data),
                      ),

                      // ❌ Delete
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteStudent(docId),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
