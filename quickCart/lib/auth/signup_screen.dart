import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/home_page.dart';
import '../widgets/button.dart';
import '../widgets/textfield.dart';
import 'auth_service.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _auth = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _cccd = TextEditingController(); // Controller cho CCCD
  final _dob = TextEditingController(); // Controller cho ngày sinh

  bool _isLoading = false; // Biến trạng thái để theo dõi quá trình đăng ký
  String? _errorMessage; // Biến để lưu thông báo lỗi

  @override
  void dispose() {
    super.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _cccd.dispose(); // Giải phóng tài nguyên cho CCCD
    _dob.dispose(); // Giải phóng tài nguyên cho ngày sinh
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlue.shade300, Colors.white], // Chuyển từ xanh da trời sang trắng
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView( // Sử dụng ListView để cho phép cuộn
          padding: const EdgeInsets.symmetric(horizontal: 25),
          children: [
            const SizedBox(height: 50),
            const Text("Signup",
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: Colors.black)),
            const SizedBox(height: 20),
            const Text("Create your account",
                style: TextStyle(fontSize: 18, color: Colors.black54)),
            const SizedBox(height: 50),
            CustomTextField(
              hint: "Enter Name",
              label: "Name",
              controller: _name,
              icon: Icons.person, // Thêm biểu tượng cho trường tên
            ),
            const SizedBox(height: 20),
            CustomTextField(
              hint: "Enter Email",
              label: "Email",
              controller: _email,
              icon: Icons.email, // Thêm biểu tượng cho trường email
            ),
            const SizedBox(height: 20),
            CustomTextField(
              hint: "Enter  Citizen ID cards",
              label: " Citizen ID cards",
              controller: _cccd,
              icon: Icons.credit_card, // Thêm biểu tượng cho trường CCCD
            ),
            const SizedBox(height: 20),
            CustomTextField(
              hint: "Enter Date of Birth (DD/MM/YYYY)",
              label: "Date of Birth",
              controller: _dob,
              icon: Icons.calendar_today, // Thêm biểu tượng cho trường ngày sinh
            ),
            const SizedBox(height: 20),
            CustomTextField(
              hint: "Enter Password",
              label: "Password",
              isPassword: true,
              controller: _password,
              icon: Icons.lock, // Thêm biểu tượng cho trường mật khẩu
            ),
            const SizedBox(height: 30),
            _isLoading // Hiển thị vòng tròn xoay nếu đang xử lý
                ? Center(child: CircularProgressIndicator())
                : CustomButton(
              label: "Signup",
              onPressed: _signup,
            ),
            const SizedBox(height: 20),
            // Hiển thị thông báo lỗi nếu có
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            const SizedBox(height: 30),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text("Already have an account? ", style: TextStyle(color: Colors.black)),
              InkWell(
                onTap: () => goToLogin(context),
                child: const Text("Login",
                    style: TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 20)),
              )
            ]),
            const SizedBox(height: 50), // Thêm khoảng cách dưới cùng
          ],
        ),
      ),
    );
  }

  goToLogin(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const LoginScreen()),
  );

  goToHome(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const HomePage()),
  );

  _signup() async {
    // Ẩn bàn phím khi nhấn nút Signup
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true; // Bắt đầu quá trình đăng ký
      _errorMessage = null; // Đặt lại thông báo lỗi
    });

    // Kiểm tra các trường nhập liệu
    if (_name.text.isEmpty || _email.text.isEmpty || _password.text.isEmpty || _cccd.text.isEmpty || _dob.text.isEmpty) {
      setState(() {
        _errorMessage = "Please fill in all fields.";
      });
      setState(() {
        _isLoading = false; // Kết thúc quá trình đăng ký
      });
      return; // Dừng lại nếu có trường còn trống
    }

    // Kiểm tra định dạng ngày sinh
    if (!_isValidDate(_dob.text)) {
      setState(() {
        _errorMessage = "Date of Birth must be in the format DD/MM/YYYY.";
      });
      setState(() {
        _isLoading = false; // Kết thúc quá trình đăng ký
      });
      return; // Dừng lại nếu định dạng không hợp lệ
    }

    try {
      final user = await _auth.createUserWithEmailAndPassword(
        _email.text,
        _password.text,
            (String message) {
          setState(() {
            _errorMessage = message; // Cập nhật thông báo lỗi
          });
        },
      );

      if (user != null) {
        log("User Created Successfully");

        // Ghi dữ liệu vào Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'name': _name.text,
          'email': _email.text,
          'cccd': _cccd.text,
          'dob': _dob.text,
        });

        // Hiển thị hộp thoại thông báo thành công
        _showSuccessDialog(context);
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          message = 'The account already exists for that email. Please try logging in.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        case 'operation-not-allowed':
          message = 'Email/password accounts are not enabled.';
          break;
        case 'too-many-requests':
          message = 'Too many requests. Please try again later.';
          break;
        case 'user-disabled':
          message = 'The user corresponding to the given email has been disabled.';
          break;
        default:
          message = 'Signup failed: ${e.message}';
      }
      log(message); // Log thông báo lỗi
      setState(() {
        _errorMessage = message; // Cập nhật thông báo lỗi
      });
    } catch (e) {
      log("Signup failed: $e"); // Log bất kỳ lỗi nào khác
      setState(() {
        _errorMessage = "Signup failed: ${e.toString()}"; // Cập nhật thông báo lỗi
      });
    } finally {
      setState(() {
        _isLoading = false; // Kết thúc quá trình đăng ký
      });
    }
  }

  bool _isValidDate(String date) {
    // Kiểm tra định dạng ngày sinh
    RegExp regExp = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    return regExp.hasMatch(date);
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Success"),
          content: const Text("Your account has been created successfully!"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng dialog
                goToHome(context); // Chuyển đến trang chính
              },
              child: const Text("Go to Home"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng dialog
                goToLogin(context); // Quay lại trang đăng nhập
              },
              child: const Text("Back to Login"),
            ),
          ],
        );
      },
    );
  }
}