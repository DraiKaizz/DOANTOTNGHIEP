import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:quickcart/auth/signup_screen.dart';
import '../pages/home_page.dart';
import '../widgets/button.dart';
import '../widgets/textfield.dart';
import 'auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _errorMessage; // Biến để lưu thông báo lỗi
  bool _isLoading = false; // Biến để theo dõi trạng thái loading
  bool _rememberMe = false; // Biến để theo dõi trạng thái "Remember Me"

  @override
  void initState() {
    super.initState();
    _loadCredentials(); // Tải thông tin đăng nhập đã lưu
  }

  Future<void> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _email.text = prefs.getString('email') ?? '';
      _password.text = prefs.getString('password') ?? '';
      _rememberMe = prefs.getBool('rememberMe') ?? false; // Tải trạng thái "Remember Me"
    });
  }

  @override
  void dispose() {
    super.dispose();
    _email.dispose();
    _password.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlue.shade300, Colors.white], // Nền chuyển màu
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Căn giữa các phần tử
          children: [
            const Text(
              "Login",
              style: TextStyle(
                fontSize: 50, // Tăng kích thước chữ
                fontWeight: FontWeight.bold, // Đậm hơn
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 30), // Khoảng cách giữa tiêu đề và trường nhập
            CustomTextField(
              hint: "Enter Email",
              label: "Email",
              controller: _email,
              icon: Icons.email, // Thêm biểu tượng cho trường email
              borderColor: Colors.blue, // Thay đổi màu viền
            ),
            const SizedBox(height: 20), // Khoảng cách giữa trường email và mật khẩu
            CustomTextField(
              hint: "Enter Password",
              label: "Password",
              controller: _password,
              isPassword: true, // Đặt trường mật khẩu
              icon: Icons.lock, // Thêm biểu tượng cho trường mật khẩu
              borderColor: Colors.blue, // Thay đổi màu viền
            ),
            const SizedBox(height: 20), // Khoảng cách giữa trường mật khẩu và checkbox
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                ),
                const Text("Remember Me"),
              ],
            ),
            const SizedBox(height: 15), // Khoảng cách giữa checkbox và thông báo lỗi
            if (_errorMessage != null) // Hiển thị thông báo lỗi nếu có
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 15), // Khoảng cách giữa thông báo lỗi và nút "Forgot Password?"
            // Thêm phần "Forgot Password?" ở bên phải
            Row(
              mainAxisAlignment: MainAxisAlignment.end, // Căn phải
              children: [
                TextButton(
                  onPressed: _forgotPassword,
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30), // Khoảng cách giữa "Forgot Password?" và nút Login
            _isLoading // Hiển thị vòng xoay nếu đang xử lý
                ? CircularProgressIndicator() // Vòng xoay chờ
                : CustomButton(
              label: "Login",
              onPressed: _login,
            ),
            const SizedBox(height: 30), // Khoảng cách giữa nút Login và phần đăng ký
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? "),
                InkWell(
                  onTap: () => goToSignup(context),
                  child: const Text(
                    "Signup",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  goToSignup(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const SignupScreen()),
  );

  goToHome(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const HomePage()),
  );

  _login() async {
    // Ẩn bàn phím khi nhấn nút Login
    FocusScope.of(context).unfocus();

    // Kiểm tra các trường nhập liệu
    if (_email.text.isEmpty || _password.text.isEmpty) {
      setState(() {
        _errorMessage = "Please fill in all fields."; // Cập nhật thông báo lỗi
      });
      return; // Dừng lại nếu có trường còn trống
    }

    setState(() {
      _isLoading = true; // Bắt đầu quá trình đăng nhập
      _errorMessage = null; // Đặt lại thông báo lỗi
    });

    final user = await _auth.loginUserWithEmailAndPassword(_email.text, _password.text);

    setState(() {
      _isLoading = false; // Kết thúc quá trình đăng nhập
    });

    if (user != null) {
      log("User Logged In");
      if (_rememberMe) {
        // Lưu thông tin đăng nhập nếu "Remember Me" được chọn
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', _email.text);
        await prefs.setString('password', _password.text);
        await prefs.setBool('rememberMe', true);
      }
      goToHome(context);
    } else {
      setState(() {
        _errorMessage = "Login failed. Please check your credentials."; // Cập nhật thông báo lỗi
      });
    }
  }

  void _forgotPassword() {
    // Hiển thị hộp thoại để người dùng nhập email
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController emailController = TextEditingController();
        return Dialog( // Sử dụng Dialog
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // Bo tròn góc hoàn toàn
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.lightBlue.shade200], // Nền chuyển màu
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0), // Thêm khoảng cách xung quanh nội dung
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Forgot Password",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 24, // Tăng kích thước chữ tiêu đề
                    ),
                  ),
                  const SizedBox(height: 20), // Khoảng cách giữa tiêu đề và văn bản
                  const Text(
                    "Enter your email to receive a password reset link.",
                    style: TextStyle(fontSize: 16, color: Colors.black54), // Màu sắc văn bản
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20), // Khoảng cách giữa văn bản và trường nhập
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      labelStyle: TextStyle(color: Colors.blueAccent), // Màu sắc nhãn
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blueAccent), // Màu viền khi focus
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey), // Màu viền khi không focus
                      ),
                    ),
                  ),
                  const SizedBox(height: 20), // Khoảng cách giữa trường nhập và nút
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Căn giữa các nút
                    children: [
                      TextButton(
                        onPressed: () async {
                          try {
                            await _auth.sendPasswordResetEmail(emailController.text);
                            Navigator.of(context).pop(); // Đóng hộp thoại
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Password reset email has been sent.")),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        },
                        child: const Text("Send", style: TextStyle(color: Colors.blueAccent)), // Màu sắc nút gửi
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(), // Đóng hộp thoại
                        child: const Text("Cancel", style: TextStyle(color: Colors.red)), // Màu sắc nút hủy
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}