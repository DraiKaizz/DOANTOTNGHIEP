import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  Future<User?> createUserWithEmailAndPassword(
      String email, String password, Function(String) onError) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return cred.user;
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          message = 'The account already exists for that email.';
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
      // Log thông báo lỗi cụ thể
      log("Signup failed: $message");
      onError(message); // Gọi callback để hiển thị thông báo lỗi
    } catch (e) {
      // Log bất kỳ lỗi nào khác
      log("Something went wrong: $e");
      onError("Something went wrong: ${e.toString()}"); // Gọi callback để hiển thị thông báo lỗi
    }
    return null;
  }

  Future<User?> loginUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return cred.user;
    } catch (e) {
      log("Something went wrong");
    }
    return null;
  }

  Future<void> signout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      log("Something went wrong");
    }
  }

  // Thêm phương thức gửi email đặt lại mật khẩu
  Future<void> sendPasswordResetEmail(String email) async {
    // Kiểm tra xem email có được nhập hay không
    if (email.isEmpty) {
      log("Email is empty"); // Ghi lại thông báo nếu email trống
      throw Exception("Please enter your email."); // Ném ra lỗi nếu email trống
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      log("Password reset email sent to $email"); // Ghi lại thông báo thành công
    } catch (e) {
      log("Something went wrong: $e"); // Ghi lại lỗi
      throw e; // Ném lại lỗi để xử lý ở nơi khác nếu cần
    }
  }


  Future<void> saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    await prefs.setString('password', password);
  }

  Future<Map<String, String?>> getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');
    String? password = prefs.getString('password');
    return {'email': email, 'password': password};
  }

  Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');
    await prefs.remove('password');
  }
}