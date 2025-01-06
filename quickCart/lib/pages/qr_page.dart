import 'dart:async';
import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({Key? key}) : super(key: key);

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  String _scanResult = 'Unknown';

  Future<void> scanQR() async {
    try {
      final result = await BarcodeScanner.scan();
      setState(() {
        _scanResult = result.rawContent;
      });

      print('Scanned result: |$_scanResult|');

      // Delay dialog presentation to give time for UI to update
      await Future.delayed(Duration(milliseconds: 200));

      if (_scanResult == 'http://192.168.246.220/sendCredentials') {
        _showLoginConfirmationDialog();
      } else if (_scanResult.contains('Payment')) {
        // Parse payment information from QR code
        _handlePaymentQRCode(_scanResult);
      }
    } catch (e) {
      setState(() {
        _scanResult = 'Failed to get scan result: $e';
      });
      print('Error scanning: $e');
    }
  }

  Future<void> _saveToHistory(String scanResult) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('history')
            .add({
          'scanResult': scanResult,
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'payment'
        });
      }
    } catch (e) {
      print('Error saving to history: $e');
    }
  }

  void _showPaymentConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Payment Confirmation'),
          content: const Text('Do you confirm this payment?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();

                try {
                  // Save to history first
                  await _saveToHistory(_scanResult);

                  // Then update cart payment status
                  await FirebaseFirestore.instance
                      .collection('carts')
                      .doc('937B2528')
                      .update({'payment': 'reset'});

                  _showLoginResultDialog('Payment successful!');
                } catch (e) {
                  _showLoginResultDialog('Error processing payment: $e');
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _showLoginConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Login Confirmation'),
          content: const Text('Do you want to log in using this QR code?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                User? user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  try {
                    String email = user.email!;
                    String uid = user.uid;
                    final prefs = await SharedPreferences.getInstance();
                    String? password = prefs.getString('password');

                    if (password == null || password.isEmpty) {
                      _showLoginResultDialog('Password is missing.');
                      return;
                    }

                    sendLoginRequest(_scanResult, email, password, uid);
                  } catch (e) {
                    _showLoginResultDialog('Error retrieving credentials: $e');
                  }
                } else {
                  _showLoginResultDialog('No user is logged in.');
                }
                Navigator.of(context).pop();
              },
              child: const Text('Accept'),
            ),
          ],
        );
      },
    );
  }

  void sendLoginRequest(String url, String email, String password, String uid) async {
    try {
      String trimmedEmail = email.trim();
      String trimmedPassword = password.trim();

      print('Sending request to: $url');
      print('Request body: email=$trimmedEmail, password=$trimmedPassword, uid=$uid');

      final response = await http.post(
        Uri.parse(url),
        body: {
          'email': trimmedEmail,
          'password': trimmedPassword,
          'uid': uid,
        },
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      ).timeout(Duration(seconds: 20));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        String responseBody = response.body;
        String? vehicleUid = _extractVehicleUid(responseBody);

        if (vehicleUid != null) {
          _showLoginResultDialog('Login successful! Vehicle UID: $vehicleUid');
        } else {
          _showLoginResultDialog('Login successful, but vehicle UID not found.');
        }
      } else {
        _showLoginResultDialog('Failed to log in: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _showLoginResultDialog('Error sending credentials: $e');
    }
  }

  String? _extractVehicleUid(String response) {
    final regex = RegExp(r"Vehicle UID = (\w+)");
    final match = regex.firstMatch(response);
    return match?.group(1);
  }

  void _showLoginResultDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Login Result'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _handlePaymentQRCode(String qrData) {
    if (!qrData.startsWith('Payment Successful')) {
      _showLoginResultDialog('QR code không hợp lệ hoặc không phải QR code thanh toán.');
      return;
    }

    try {
      // Loại bỏ phần "Thanh toán thành công" và lấy thông tin còn lại
      String content = _extractPaymentDetails(qrData);

      // Danh sách sản phẩm và tổng tiền
      List<Map<String, String>> items = [];
      String total = '';

      // Xử lý các sản phẩm và tổng tiền
      _processAndShowPaymentDetails(content, items, total);


    } catch (e) {
      _showLoginResultDialog('Lỗi xử lý QR code: $e');
    }
  }

// Hàm tách thông tin thanh toán từ QR code
  String _extractPaymentDetails(String qrData) {
    return qrData.replaceAll('Payment Successful', '').trim();
  }

  void _processAndShowPaymentDetails(String content, List<Map<String, String>> items, String total) {
    // Tách nội dung thành các phần
    List<String> parts = content.split('\n');
    String total = '';
    // Xử lý nội dung thanh toán
    for (String part in parts) {
      if (part.contains('Total:')) {
        total = part.split(':')[1].trim();  // Lấy tổng tiền
        print('Total Amount: $total');  // In ra tổng tiền để kiểm tra
      } else {
        // Tách tên sản phẩm và số lượng
        final regex = RegExp(r'(.+?)\s+(\d+)$');
        final match = regex.firstMatch(part);
        if (match != null) {
          String productName = match.group(1)!.trim(); // Tên sản phẩm
          String quantity = match.group(2)!.trim(); // Số lượng
          items.add({
            'name': productName,
            'quantity': quantity,
          });
        }
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Payment Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Product List:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Hiển thị các sản phẩm trong Column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var item in items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item['name'] ?? '',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            const SizedBox(width: 10), // Khoảng cách giữa tên sản phẩm và số lượng
                            Text(
                              item['quantity'] ?? '',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),  // Khoảng cách giữa các sản phẩm
                  ],
                ),
                const Divider(height: 20, thickness: 1),
                // Hiển thị tổng tiền ở cuối danh sách sản phẩm
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: $total',  // Kiểm tra và kết hợp 'Tổng:' và giá trị của total
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showPaymentConfirmationDialog();
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'QR Code Scanner',
                style: GoogleFonts.lobster(
                  fontSize: 40,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: scanQR,
                child: const Text('Start QR Scan'),
              ),
              const SizedBox(height: 20),
              Text(
                _scanResult == 'Unknown'
                    ? 'Press the button to scan a QR code.'
                    : (_scanResult.contains('http') || _scanResult.contains('Payment Successful'))
                    ? ''
                    : 'Scan result: $_scanResult',
                textAlign: TextAlign.center,
              )
            ],
          ),
        ),
      ),
    );
  }
}