// lib/pages/intro_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/login_screen.dart'; // Import the login page

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  // Giả lập trạng thái đăng nhập (thay thế bằng logic thực tế của bạn)
  final bool isLoggedIn = false; // Thay đổi giá trị này để kiểm tra

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlueAccent, Colors.white], // Chuyển từ màu xanh da trời sang màu trắng
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView( // Thêm SingleChildScrollView
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Căn giữa các phần tử
            children: [
              const SizedBox(height: 100), // Khoảng cách trên cùng

              // Tiêu đề chào mừng
              Text(
                'Welcome',
                style: GoogleFonts.pacifico(
                  color: Colors.deepPurple, // Màu chữ
                  fontSize: 48, // Kích thước chữ lớn hơn
                ),
              ),

              const SizedBox(height: 20), // Khoảng cách giữa tiêu đề và hình ảnh

              // Hình ảnh giới thiệu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20), // Thêm khoảng cách bên trái và bên phải
                child: Image.asset(
                  'lib/Images/app_intro.png',
                  height: 300,
                  width: 400,
                  fit: BoxFit.cover, // Đảm bảo hình ảnh không bị méo
                ),
              ),

              const SizedBox(height: 150), // Khoảng cách dưới hình ảnh

              // Nút "Get Started"
              GestureDetector(
                onTap: () {
                  if (isLoggedIn) {
                    // Nếu đã đăng nhập, hiển thị thông báo
                    _showAlreadyLoggedInDialog(context);
                  } else {
                    // Nếu chưa đăng nhập, điều hướng đến màn hình đăng nhập
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()), // Navigate to LoginPage
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4), // Đổ bóng
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20.0),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18, // Kích thước chữ lớn hơn
                      fontWeight: FontWeight.bold, // Chữ đậm
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50), // Khoảng cách dưới nút
            ],
          ),
        ),
      ),
    );
  }

  // Hàm hiển thị thông báo nếu đã đăng nhập
  void _showAlreadyLoggedInDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Welcome Back!"),
          content: const Text("You are already logged in."),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng dialog
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
}