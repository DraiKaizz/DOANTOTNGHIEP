import 'package:flutter/material.dart';

class GroceryItemTile extends StatelessWidget {
  final String itemName;
  final String itemPrice;
  final String imagePath;
  final Color color;
  final VoidCallback onPressed;

  const GroceryItemTile({
    required this.itemName,
    required this.itemPrice,
    required this.imagePath,
    required this.color,
    required this.onPressed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3), // Đổ bóng xuống dưới
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Căn giữa theo chiều dọc
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15), // Bo tròn hình ảnh
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                height: 120, // Chiều cao hình ảnh
                width: 120, // Chiều rộng hình ảnh
              ),
            ),
            const SizedBox(height: 8), // Khoảng cách giữa hình ảnh và tên
            Text(
              itemName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16, // Kích thước chữ tên sản phẩm
              ),
              textAlign: TextAlign.center, // Căn giữa tên sản phẩm
            ),
            const SizedBox(height: 4), // Khoảng cách giữa tên và giá
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.green[700], // Màu nền cho giá
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                itemPrice,
                style: const TextStyle(
                  color: Colors.white, // Màu chữ giá
                  fontSize: 14, // Kích thước chữ giá
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}