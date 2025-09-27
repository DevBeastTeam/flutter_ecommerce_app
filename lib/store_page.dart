// 📂 lib/store_page.dart
import 'dart:io';
import 'package:firebase/orders_page.dart';
import 'package:firebase/profile_page.dart';
import 'package:firebase/services/FileUploadService.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorePage extends StatefulWidget {
  final String uid;

  const StorePage({super.key, required this.uid});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TextEditingController _searchController = TextEditingController();

  String searchQuery = "";
  String sortOption = "none"; // none, lowToHigh, highToLow

  Future<List<DocumentSnapshot>> _fetchItems() async {
    QuerySnapshot snapshot = await _firestore.collection("items").get();
    return snapshot.docs;
  }

  // 📸 Pick image from gallery
  Future<String?> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;

    File file = File(picked.path);
    final fileName = "items/${DateTime.now().millisecondsSinceEpoch}.jpg";

    UploadTask uploadTask = _storage.ref(fileName).putFile(file);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // 🔹 Add or Update Item Dialog
  Future<void> _showItemDialog({
    String? itemId,
    Map<String, dynamic>? item,
  }) async {
    final TextEditingController titleController = TextEditingController(
      text: item?["title"] ?? "",
    );
    final TextEditingController priceController = TextEditingController(
      text: item?["price"]?.toString() ?? "",
    );

    String choosedImagePath = "";

    await showDialog(
      context: context,

      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(itemId == null ? "Add Item" : "Edit Item"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 📸 Image Preview
                GestureDetector(
                  onTap: () async {
                    final pickedImage = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                    );
                    if (pickedImage != null) {
                      setDialogState(() {
                        choosedImagePath = pickedImage.path;
                      });
                    }
                  },
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color.fromARGB(255, 14, 13, 13),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: choosedImagePath.isNotEmpty
                        ? Image.file(File(choosedImagePath)!, fit: BoxFit.cover)
                        : const Center(child: Text("Tap to upload image")),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Item Title"),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: "Item Price"),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final price = double.tryParse(priceController.text) ?? 0;

                if (title.isEmpty || price <= 0 || choosedImagePath.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please fill all fields and add image!"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                var downoadLink = await FileUploadService.uploadFile(
                  file: File(choosedImagePath),
                  folderName: "items",
                  isSecret: true,
                  fromDeviceName: "itel",
                  onSendProgress: (uploading, totoalSize) {
                    debugPrint(
                      "👉 uploading: $uploading, total Size: $totoalSize",
                    );
                  },
                );

                debugPrint("👉 downoadLink:$downoadLink");

                // return;
                if (itemId == null) {
                  // ➕ New Item
                  await _firestore.collection("items").add({
                    "title": title,
                    "price": price,
                    "imageUrl": downoadLink,
                    "sellerId": widget.uid,
                    "createdAt": DateTime.now(),
                  });
                } else {
                  // ✏️ Update Item
                  await _firestore.collection("items").doc(itemId).update({
                    "title": title,
                    "price": price,
                    "imageUrl": downoadLink,
                  });
                }

                Navigator.pop(ctx);
                setState(() {});
              },
              child: Text(itemId == null ? "Add" : "Update"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🛍 My Store"),
        centerTitle: true,
        backgroundColor: Colors.orange,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => OrdersPage(uid: widget.uid)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfilePage(userId: widget.uid),
                ),
              );
            },
          ),
        ],
      ),

      // 🔍 Search + Sort
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search items...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.orange.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort, color: Colors.orange),
                  onSelected: (value) {
                    setState(() {
                      sortOption = value;
                    });
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: "lowToHigh",
                      child: Text("Price: Low to High"),
                    ),
                    const PopupMenuItem(
                      value: "highToLow",
                      child: Text("Price: High to Low"),
                    ),
                    const PopupMenuItem(
                      value: "none",
                      child: Text("No Sorting"),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 🔄 Items Grid
          Expanded(
            child: FutureBuilder<List<DocumentSnapshot>>(
              future: _fetchItems(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      "No items found.\nTry adding or searching again!",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                List<DocumentSnapshot> docs = snapshot.data!;

                // 🔍 Search filter
                if (searchQuery.isNotEmpty) {
                  docs = docs.where((doc) {
                    final item = doc.data() as Map<String, dynamic>;
                    final title = (item["title"] ?? "")
                        .toString()
                        .toLowerCase();
                    return title.contains(searchQuery);
                  }).toList();
                }

                // 🔄 Sorting
                if (sortOption == "lowToHigh") {
                  docs.sort((a, b) {
                    final itemA = a.data() as Map<String, dynamic>;
                    final itemB = b.data() as Map<String, dynamic>;
                    return (itemA["price"] ?? 0).compareTo(itemB["price"] ?? 0);
                  });
                } else if (sortOption == "highToLow") {
                  docs.sort((a, b) {
                    final itemA = a.data() as Map<String, dynamic>;
                    final itemB = b.data() as Map<String, dynamic>;
                    return (itemB["price"] ?? 0).compareTo(itemA["price"] ?? 0);
                  });
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 items per row
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8, // height/width ratio
                  ),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final item = docs[i].data() as Map<String, dynamic>;
                    final itemId = docs[i].id;

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: item["imageUrl"] != null
                                ? ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                    child: Image.network(
                                      item["imageUrl"],
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.shopping_bag,
                                      size: 40,
                                      color: Colors.orange,
                                    ),
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item["title"] ?? "No Title",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "💲 ${item["price"] ?? 0}",
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 13,
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == "order") {
                                        await _firestore
                                            .collection("orders")
                                            .add({
                                              "itemId": itemId,
                                              "title": item["title"],
                                              "price": item["price"],
                                              "imageUrl": item["imageUrl"],
                                              "buyerId": widget.uid,
                                              "sellerId": item["sellerId"],
                                              "status": "pending",
                                              "orderedAt": DateTime.now(),
                                            });

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "${item["title"]} Ordered Successfully",
                                            ),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                      } else if (value == "edit") {
                                        _showItemDialog(
                                          itemId: itemId,
                                          item: item,
                                        );
                                      } else if (value == "delete") {
                                        await _firestore
                                            .collection("items")
                                            .doc(itemId)
                                            .delete();

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text("Item Deleted"),
                                          ),
                                        );
                                        setState(() {});
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: "order",
                                        child: Text("🛒 Order"),
                                      ),
                                      const PopupMenuItem(
                                        value: "edit",
                                        child: Text("✏️ Edit"),
                                      ),
                                      const PopupMenuItem(
                                        value: "delete",
                                        child: Text("🗑 Delete"),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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

      // ➕ Floating Button
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () => _showItemDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
