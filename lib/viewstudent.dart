import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewStudentsScreen extends StatefulWidget {
  const ViewStudentsScreen({super.key});

  @override
  State<ViewStudentsScreen> createState() => _ViewStudentsScreenState();
}

class _ViewStudentsScreenState extends State<ViewStudentsScreen> {
  final CollectionReference students = FirebaseFirestore.instance.collection(
    'students',
  );

  final TextEditingController searchController = TextEditingController();

  String searchText = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Students")),

      body: Column(
        children: [
          // 🔍 SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search by ID or Class",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value.toLowerCase().trim();
                });
              },
            ),
          ),

          // 📋 STUDENT LIST
          Expanded(
            child: StreamBuilder(
              stream: students
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data!.docs;

                // 🔎 FILTER LOGIC
                var filteredDocs = docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;

                  String id = (data['id'] ?? '').toString().toLowerCase();
                  String className = (data['class'] ?? '')
                      .toString()
                      .toLowerCase();

                  return id.contains(searchText) ||
                      className.contains(searchText);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text("No matching students"));
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var data =
                        filteredDocs[index].data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(data['name'] ?? ''),
                        subtitle: Text(
                          "ID: ${data['id']} | Age: ${data['age']} | Class: ${data['class']}",
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
