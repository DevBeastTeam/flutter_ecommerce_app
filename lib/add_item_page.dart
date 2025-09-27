import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddItemPage extends StatefulWidget {
  final String? itemId; // agar edit karna ho toh ID milegi
  final Map<String, dynamic>? itemData; // agar edit karna ho toh data milega

  const AddItemPage({super.key, this.itemId, this.itemData});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // agar edit ho raha ho toh purana data fill kar dena
    if (widget.itemData != null) {
      titleController.text = widget.itemData!["title"];
      priceController.text = widget.itemData!["price"].toString();
    }
  }

  Future<void> saveItem() async {
    final title = titleController.text.trim();
    final price = priceController.text.trim();

    if (title.isEmpty || price.isEmpty) return;

    if (widget.itemId == null) {
      // 🟢 New Item Add
      await _firestore.collection("items").add({
        "title": title,
        "price": price,
        "createdAt": DateTime.now(),
      });
    } else {
      // 🟡 Update Existing Item
      await _firestore.collection("items").doc(widget.itemId).update({
        "title": title,
        "price": price,
        "updatedAt": DateTime.now(),
      });
    }

    Navigator.pop(context); // page close after save
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemId == null ? "Add Item" : "Edit Item"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Item Title"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Item Price"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveItem,
              child: Text(widget.itemId == null ? "Add" : "Update"),
            ),
          ],
        ),
      ),
    );
  }
}
