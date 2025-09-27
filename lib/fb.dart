// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';

// class FFHomePage extends StatefulWidget {
//   const FFHomePage({super.key});

//   @override
//   State<FFHomePage> createState() => _FFHomePageState();
// }

// class _FFHomePageState extends State<FFHomePage> {
//   List allUsers = [];

//   getUsers() async {
//     var getData = await FirebaseFirestore.instance.collection("Users").get();

//     if (getData != null) {
//       for (var item in getData.docs) {
//         allUsers.add(item.data());
//       }
//     }
//     setState(() {});
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Firebase Add")),
//       body: Center(
//         child: Column(
//           children: [
//             ElevatedButton(
//               onPressed: () {
//                 FirebaseFirestore.instance
//                     .collection("Users")
//                     .add({"name": "sana", "age": "25"})
//                     .then((v) {
//                       print("successfully");
//                       print(v);
//                     });
//                 print("User Added!");
//               },

//               child: const Text("Add User"),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 getUsers();
//               },
//               child: const Text("get User"),
//             ),
//             Divider(),
//             Text("users list -> $allUsers"),
//             Divider(),
//             Text("single user-> ${allUsers[2]['name']}"),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

// 🔹 CRUD Page ek StatefulWidget banaya (kyunki hume data add/update/delete karna hai)
class CrudPage extends StatefulWidget {
  const CrudPage({super.key}); // ✅ Constructor

  @override
  State<CrudPage> createState() => _CrudPageState(); // ✅ State create ki
}

// 🔹 Is class ke andar saari CRUD logic hogi
class _CrudPageState extends State<CrudPage> {
  // 🔹 Firestore collection ka reference "users"
  // Yahi pe sab user records save honge
  final CollectionReference users = FirebaseFirestore.instance.collection(
    'users',
  );

  // 🔹 Input field ka controller (jo naam hum TextField me dalenge)
  final TextEditingController nameController = TextEditingController();

  // 🔹 Function: Firestore me ek naya user add karega
  Future<void> addUser() async {
    if (nameController.text.isNotEmpty) {
      await users.add({
        'name': nameController.text, // ✅ User ka naam save
        'createdAt': DateTime.now(), // ✅ Timestamp save
      });

      nameController.clear(); // ✅ TextField empty kar diya
      setState(
        () {},
      ); // ✅ UI refresh kiya (FutureBuilder ko reload karne ke liye)
    }
  }

  // 🔹 Function: Update user (dialog box open hoga edit ke liye)
  Future<void> updateUser(String id, String currentName) async {
    // ✅ Ek controller banaya jo already user ka current name hold karega
    final TextEditingController updateController = TextEditingController(
      text: currentName,
    );

    // ✅ Dialog show kiya update karne ke liye
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Update User"), // Dialog title
          content: TextField(
            controller: updateController, // ✅ Input me purana naam
            decoration: const InputDecoration(
              labelText: "Enter New Name", // Placeholder
            ),
          ),
          actions: [
            // ❌ Cancel button (dialog band kar dega)
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),

            // ✅ Update button (Firestore me update karega)
            ElevatedButton(
              onPressed: () async {
                if (updateController.text.isNotEmpty) {
                  await users.doc(id).update({
                    'name': updateController.text, // ✅ Naya naam update
                  });
                  Navigator.pop(ctx); // ✅ Dialog close
                  setState(() {}); // ✅ List refresh
                }
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  // 🔹 Function: Firestore se ek user delete karega
  Future<void> deleteUser(String id) async {
    await users.doc(id).delete(); // ✅ Record delete kiya
    setState(() {}); // ✅ List refresh
  }

  // 🔹 Function: Firestore se ek dafa data fetch karega (Future ke liye)
  Future<List<QueryDocumentSnapshot>> fetchUsers() async {
    // ✅ Firestore se "users" collection ka snapshot fetch kiya
    final snapshot = await users.orderBy("createdAt", descending: true).get();

    return snapshot.docs; // ✅ Sabhi documents return kiye
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🔹 AppBar banaya
      appBar: AppBar(title: const Text("Firebase CRUD (FutureBuilder)")),

      // 🔹 Body
      body: Padding(
        padding: const EdgeInsets.all(16.0), // ✅ Thoda spacing diya
        child: Column(
          children: [
            // 🔹 TextField jahan user apna naam enter karega
            TextField(
              controller: nameController, // ✅ Controller attach kiya
              decoration: const InputDecoration(
                labelText: "Enter Name", // Placeholder
                border: OutlineInputBorder(), // ✅ Border banaya
              ),
            ),

            const SizedBox(height: 20), // ✅ Gap diya
            // 🔹 Add User button
            ElevatedButton(
              onPressed: addUser, // ✅ Add function call karega
              child: const Text("Add User"),
            ),

            const SizedBox(height: 20), // ✅ Gap diya
            // 🔹 FutureBuilder (sirf ek dafa data fetch karega)
            Expanded(
              child: FutureBuilder<List<QueryDocumentSnapshot>>(
                future: fetchUsers(), // ✅ Users fetch kiye
                builder: (context, snapshot) {
                  // ✅ Jab tak data load ho raha hai
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // ✅ Agar error aaya
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }

                  // ✅ Agar data empty hai
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No users found"));
                  }

                  // ✅ Agar data mil gaya
                  final docs = snapshot.data!;
                  return ListView.builder(
                    itemCount: docs.length, // ✅ Kitne items hain
                    itemBuilder: (context, index) {
                      final doc = docs[index]; // ✅ Current document
                      final data = doc.data() as Map<String, dynamic>;
                      final name = data['name'] ?? ''; // ✅ Naam nikala

                      return ListTile(
                        title: Text(name), // ✅ User ka naam
                        subtitle: Text(doc.id), // ✅ Document ID
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 🔹 Edit button
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => updateUser(doc.id, name),
                            ),
                            // 🔹 Delete button
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
