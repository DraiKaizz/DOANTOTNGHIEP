import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String hint;
  final String label;
  final TextEditingController controller;
  final bool isPassword;
  final IconData? icon;
  final Color borderColor; // Thêm tham số borderColor

  const CustomTextField({
    Key? key,
    required this.hint,
    required this.label,
    required this.controller,
    this.isPassword = false,
    this.icon,
    this.borderColor = Colors.grey, // Mặc định là màu xám
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor), // Sử dụng borderColor
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor), // Sử dụng borderColor khi focus
        ),
      ),
    );
  }
}