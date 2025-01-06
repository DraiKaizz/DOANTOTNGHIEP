import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        toolbarHeight: 50,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          padding: const EdgeInsets.only(top: 40),
          child: Center(
            child: Text(
              'Checkout History',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.blueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _fetchCheckoutHistory(), // Sử dụng stream
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(fontSize: 18, color: Colors.red),
                      ),
                    );
                  }

                  final data = snapshot.data?.docs;

                  if (data == null || data.isEmpty) {
                    return const Center(
                      child: Text(
                        'No checkout history available.',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: data.length,
                    padding: const EdgeInsets.all(8.0),
                    itemBuilder: (context, index) {
                      final checkout = data[index].data();
                      final docId = data[index].id;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        elevation: 5,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blueAccent,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                          title: Text(
                            'Result: ${checkout['scanResult']}', // Hiển thị kết quả quét
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Timestamp: ${checkout['timestamp']?.toDate().toString() ?? ''}', // Hiển thị thời gian
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteCheckoutHistory(context, docId),
                          ),
                          onTap: () => _showCheckoutDetails(context, checkout['items']),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _fetchCheckoutHistory() async* {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    yield* FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('history') // Truy cập vào bộ sưu tập 'history'
        .orderBy('timestamp', descending: true) // Sắp xếp theo thời gian
        .snapshots(); // Sử dụng snapshots để lắng nghe thay đổi
  }

  void _showCheckoutDetails(BuildContext context, List<dynamic> items) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Checkout Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text('${item['name']}'),
                      subtitle: Text('\$${item['price']} x ${item['quantity']}'),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteCheckoutHistory(BuildContext context, String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in!')),
      );
      return;
    }

    // Xóa tài liệu khỏi Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('history') // Xóa mục khỏi bộ sưu tập 'history'
        .doc(docId)
        .delete();

    // Cập nhật giao diện người dùng
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item has been deleted!')),
    );
  }
}