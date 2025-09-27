import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  // Firestore collection ka reference
  final CollectionReference users = FirebaseFirestore.instance.collection('');

  // Add User
  Future<void> addUser(String name) async {
    await users.add({'name': name, 'createdAt': DateTime.now()});
  }

  // Get All Users (Future)
  Future<List<QueryDocumentSnapshot>> fetchUsers() async {
    final myUsers = await users.orderBy('createdAt', descending: true).get();
    return myUsers.docs;
  }

  // Update User
  Future<void> updateUser(String id, String newName) async {
    await users.doc(id).update({'name': newName});
  }

  // Delete User
  Future<void> deleteUser(String id) async {
    await users.doc(id).delete();
  }
}
