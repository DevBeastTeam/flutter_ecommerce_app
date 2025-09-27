import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditItemPage extends StatefulWidget {
  final String itemId;
  final Map<String, dynamic> itemData;

  const EditItemPage({super.key, required this.itemId, required this.itemData});

  @override
  State<EditItemPage> createState() => _EditItemPageState();
}

class _EditItemPageState extends State<EditItemPage> {
  late TextEditingController titleCtrl;
  late TextEditingController priceCtrl;
  late TextEditingController descCtrl;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(text: widget.itemData["title"]);
    priceCtrl = TextEditingController(
      text: widget.itemData["price"].toString(),
    );
    descCtrl = TextEditingController(text: widget.itemData["description"]);
  }

  Future<void> updateItem() async {
    await _firestore.collection("items").doc(widget.itemId).update({
      "title": titleCtrl.text,
      "price": int.tryParse(priceCtrl.text) ?? 0,
      "description": descCtrl.text,
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Item Updated")));
    Navigator.pop(context);
  }

  Future<void> deleteItem() async {
    await _firestore.collection("items").doc(widget.itemId).delete();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Item Deleted")));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Item")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: "Item Title"),
            ),
            TextField(
              controller: priceCtrl,
              decoration: const InputDecoration(labelText: "Price"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: updateItem,
              child: const Text("Update Item"),
            ),
            TextButton(
              onPressed: deleteItem,
              child: const Text(
                "Delete Item",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
