import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final CollectionReference students = FirebaseFirestore.instance.collection(
    'students',
  );

  final CollectionReference attendance = FirebaseFirestore.instance.collection(
    'attendance',
  );

  String? selectedClass;
  Map<String, bool> attendanceMap = {};
  bool isLoadingClass = false;

  // Save all attendance in one document
  Future<void> saveAttendance(List<QueryDocumentSnapshot> studentsList) async {
    if (selectedClass == null) return;

    try {
      DateTime now = DateTime.now();
      String dateKey = "${now.year}-${now.month}-${now.day}";
      String docId = "${selectedClass}_$dateKey";

      Map<String, String> records = {};

      for (var student in studentsList) {
        String id = student.id;
        records[id] = (attendanceMap[id] ?? false) ? "Present" : "Absent";
      }

      await attendance.doc(docId).set({
        'class': selectedClass,
        'date': dateKey,
        'records': records,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Attendance Saved Successfully")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error saving attendance: $e")));
      }
    }
  }

  List<String> _getUniqueClasses(List<QueryDocumentSnapshot> docs) {
    final classes =
        docs
            .map((e) => (e['class'] ?? '').toString().trim())
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return classes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mark Attendance")),
      body: Column(
        children: [
          // Class selector
          StreamBuilder<QuerySnapshot>(
            stream: students.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(10),
                  child: LinearProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    "Error loading classes: ${snapshot.error}",
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(10),
                  child: Text("No classes found"),
                );
              }

              final docs = snapshot.data!.docs;
              final classes = _getUniqueClasses(docs);

              final dropdownValue =
                  (selectedClass != null && classes.contains(selectedClass))
                  ? selectedClass
                  : null;

              return Padding(
                padding: const EdgeInsets.all(10),
                child: DropdownButtonFormField<String>(
                  value: dropdownValue,
                  decoration: const InputDecoration(
                    labelText: "Select Class",
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text("Select Class"),
                  items: classes.map((c) {
                    return DropdownMenuItem<String>(value: c, child: Text(c));
                  }).toList(),
                  onChanged: (value) async {
                    if (value == null) return;

                    setState(() {
                      isLoadingClass = true;
                    });

                    await Future.delayed(const Duration(milliseconds: 100));

                    if (!mounted) return;

                    setState(() {
                      selectedClass = value.trim();
                      attendanceMap.clear();
                      isLoadingClass = false;
                    });
                  },
                ),
              );
            },
          ),

          // Student list
          Expanded(
            child: isLoadingClass
                ? const Center(child: CircularProgressIndicator())
                : selectedClass == null
                ? const Center(child: Text("Please select a class"))
                : StreamBuilder<QuerySnapshot>(
                    stream: students
                        .where('class', isEqualTo: selectedClass)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Error loading students: ${snapshot.error}",
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text("No Students Found"));
                      }

                      final studentList = snapshot.data!.docs;

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        itemCount: studentList.length,
                        itemBuilder: (context, index) {
                          final student = studentList[index];
                          final data = student.data() as Map<String, dynamic>;
                          final studentId = student.id;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text((data['name'] ?? '').toString()),
                              subtitle: Text(
                                "Class: ${(data['class'] ?? '').toString()}",
                              ),
                              trailing: Switch(
                                value: attendanceMap[studentId] ?? false,
                                onChanged: (value) {
                                  setState(() {
                                    attendanceMap[studentId] = value;
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),

          // Save button
          Padding(
            padding: const EdgeInsets.all(10),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedClass == null
                    ? null
                    : () async {
                        try {
                          final snapshot = await students
                              .where('class', isEqualTo: selectedClass)
                              .get();

                          await saveAttendance(snapshot.docs);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Error loading students for save: $e",
                                ),
                              ),
                            );
                          }
                        }
                      },
                child: const Text("Save Attendance"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
