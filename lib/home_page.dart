import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CrudPage extends StatefulWidget {
  const CrudPage({super.key});

  @override
  State<CrudPage> createState() => _CrudPageState();
}

class _CrudPageState extends State<CrudPage> {
  final CollectionReference users = FirebaseFirestore.instance.collection(
    'users',
  );

  final TextEditingController nameController = TextEditingController();

  Future<void> addUser() async {
    if (nameController.text.isNotEmpty) {
      await users.add({
        'name': nameController.text,
        'createdAt': DateTime.now(),
      });

      nameController.clear();
      setState(() {});
    }
  }

  Future<void> updateUser(String id, String currentName) async {
    final TextEditingController updateController = TextEditingController(
      text: currentName,
    );

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Update User"),
          content: TextField(
            controller: updateController,
            decoration: const InputDecoration(labelText: "Enter New Name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (updateController.text.isNotEmpty) {
                  await users.doc(id).update({'name': updateController.text});
                  Navigator.pop(ctx);
                  setState(() {});
                }
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteUser(String id) async {
    await users.doc(id).delete();
    setState(() {});
  }

  Future<List<QueryDocumentSnapshot>> fetchUsers() async {
    final snapshot = await users.orderBy("createdAt", descending: true).get();
    return snapshot.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Firebase CRUD (FutureBuilder)")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Enter Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: addUser, child: const Text("Add User")),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<QueryDocumentSnapshot>>(
                future: fetchUsers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No users found"));
                  }

                  final docs = snapshot.data!;
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final name = data['name'] ?? '';

                      return ListTile(
                        title: Text(name),
                        subtitle: Text(doc.id),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => updateUser(doc.id, name),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteUser(doc.id),
                            ),
                          ],
                        ),
                      );
                    },
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
