import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

// 📦 UserService file import ki (jisme CRUD logic rakha gaya hai)
import 'user_service.dart';

// 🔹 CRUD Page ek StatefulWidget banaya (kyunki UI + state change dono chahiye)
class CrudPage extends StatefulWidget {
  const CrudPage({super.key}); // ✅ Constructor

  @override
  State<CrudPage> createState() => _CrudPageState(); // ✅ State create ki
}

// 🔹 Ye class ke andar UI aur button actions likhe gaye hain
class _CrudPageState extends State<CrudPage> {
  // 🔹 TextField ka controller (input hold karega)
  final TextEditingController nameController = TextEditingController();

  // 🔹 UserService ka object banaya (taake CRUD functions call kar saken)
  final UserService userService = UserService();

  // 🟢 Add User Function
  Future<void> addUser() async {
    if (nameController.text.isNotEmpty) {
      // Service se addUser call kiya aur text bheja
      await userService.addUser(nameController.text);

      // TextField clear kar diya
      nameController.clear();

      // UI refresh kiya (taake FutureBuilder dubara load ho)
      setState(() {});
    }
  }

  // 🟡 Update User Function
  Future<void> updateUser(String id, String currentName) async {
    // Ek controller banaya jisme current name set kar diya
    final TextEditingController updateController = TextEditingController(
      text: currentName,
    );

    // Dialog open kiya update karne ke liye
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Update User"), // Dialog ka title
          content: TextField(
            controller: updateController, // Purana naam textfield me show hoga
            decoration: const InputDecoration(labelText: "Enter New Name"),
          ),
          actions: [
            // ❌ Cancel button (dialog band kar dega)
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            // ✅ Update button
            ElevatedButton(
              onPressed: () async {
                if (updateController.text.isNotEmpty) {
                  // Service se updateUser call kiya
                  await userService.updateUser(id, updateController.text);

                  // Dialog band
                  Navigator.pop(ctx);

                  // UI refresh
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

  // 🔴 Delete User Function
  Future<void> deleteUser(String id) async {
    // Service se deleteUser call kiya
    await userService.deleteUser(id);

    // UI refresh kiya
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🔹 AppBar banaya
      appBar: AppBar(title: const Text("Firebase CRUD (Service Separated)")),

      // 🔹 Body ke andar UI
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Thoda space diya
        child: Column(
          children: [
            // 📝 Input field
            TextField(
              controller: nameController, // Controller attach kiya
              decoration: const InputDecoration(
                labelText: "Enter Name", // Placeholder text
                border: OutlineInputBorder(), // Box border
              ),
            ),
            const SizedBox(height: 20), // Space
            // ➕ Add button
            ElevatedButton(onPressed: addUser, child: const Text("Add User")),
            const SizedBox(height: 20),

            // 📥 FutureBuilder -> ek dafa data fetch karega
            Expanded(
              child: FutureBuilder<List<QueryDocumentSnapshot>>(
                future: userService.fetchUsers(), // Service se users fetch kiye
                builder: (context, snapshot) {
                  // Jab tak data load ho raha hai, spinner dikhayenge
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Agar error aaya
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }

                  // Agar data empty hai
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No users found"));
                  }

                  // ✅ Agar data mil gaya
                  final docs = snapshot.data!; // Users list
                  return ListView.builder(
                    itemCount: docs.length, // Kitne users hain
                    itemBuilder: (context, index) {
                      final doc = docs[index]; // Current user
                      final data = doc.data() as Map<String, dynamic>;
                      final name = data['name'] ?? ''; // User ka naam

                      return ListTile(
                        title: Text(name), // Naam show
                        subtitle: Text(doc.id), // Firestore ka ID show
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ✏️ Edit button
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => updateUser(doc.id, name),
                            ),
                            // 🗑️ Delete button
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
