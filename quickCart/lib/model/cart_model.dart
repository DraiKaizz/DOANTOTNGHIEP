import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import for Shared Preferences
import 'dart:convert'; // Import for JSON encoding/decoding

class CartItem {
  final String name;
  final double price;
  final String imagePath; // Required parameter
  int quantity;

  CartItem({
    required this.name,
    required this.price,
    required this.imagePath,
    this.quantity = 1,
  });

  // Convert CartItem to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'imagePath': imagePath,
      'quantity': quantity,
    };
  }

  // Create CartItem from JSON
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      name: json['name'],
      price: json['price'],
      imagePath: json['imagePath'],
      quantity: json['quantity'],
    );
  }
}

class CartModel extends ChangeNotifier {
  final List<CartItem> _shopItems = [
    CartItem(name: 'Toppo Chocolate', price: 0.79, imagePath: 'lib/Images/chocolate.png'),
    CartItem(name: 'Coca Cola', price: 0.47, imagePath: 'lib/Images/cocacola.png'),
    CartItem(name: 'Wet Wipes', price: 1.19, imagePath: 'lib/Images/khangiay.png'),
  ];

  List<CartItem> _cartItems = []; // Changeable variable

  List<CartItem> get shopItems => _shopItems;
  List<CartItem> get cartItems => _cartItems;

  int get cartItemCount => _cartItems.length;

  // Load cart items from Shared Preferences
  Future<void> loadCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cartData = prefs.getString('cartItems');
    if (cartData != null) {
      final List<dynamic> jsonList = json.decode(cartData);
      _cartItems = jsonList.map((item) => CartItem.fromJson(item)).toList();
      notifyListeners();
    }
  }

  // Save cart items to Shared Preferences
  Future<void> saveCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String cartData = json.encode(_cartItems.map((item) => item.toJson()).toList());
    await prefs.setString('cartItems', cartData);
  }

  void addItemToCart(int index) {
    final existingItem = _cartItems.firstWhere(
          (item) => item.name == _shopItems[index].name,
      orElse: () => CartItem(name: '', price: 0, imagePath: '', quantity: 0),
    );

    if (existingItem.quantity == 0) {  // Ensure item exists or needs to be added
      _cartItems.add(CartItem(
        name: _shopItems[index].name,
        price: _shopItems[index].price,
        imagePath: _shopItems[index].imagePath,
        quantity: 1,
      ));
    } else {
      existingItem.quantity++;  // Increase quantity if item exists
    }
    saveCartItems(); // Save cart after adding item
    notifyListeners();
  }

  void removeItemFromCart(int index) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems.removeAt(index);
      saveCartItems(); // Save cart after removing item
      notifyListeners();
    }
  }

  double calculateTotal() {
    return _cartItems.fold(0.0, (total, item) => total + (item.price * item.quantity));
  }

  void increaseItemQuantity(int index) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems[index].quantity++;
      saveCartItems(); // Save cart after increasing quantity
      notifyListeners();
    }
  }

  void decreaseItemQuantity(int index) {
    if (index >= 0 && index < _cartItems.length) {
      if (_cartItems[index].quantity > 1) {
        _cartItems[index].quantity--;
      } else {
        _cartItems.removeAt(index);
      }
      saveCartItems(); // Save cart after decreasing quantity
      notifyListeners();
    }
  }

  // New method to add a specific item to the cart
  void addSpecificItemToCart(CartItem item) {
    final existingItem = _cartItems.firstWhere(
          (cartItem) => cartItem.name == item.name,
      orElse: () => CartItem(name: '', price: 0, imagePath: '', quantity: 0),
    );

    if (existingItem.quantity == 0) { // Check if item already exists
      _cartItems.add(item); // Add new item to the cart
    } else {
      existingItem.quantity += item.quantity; // Increase quantity if it already exists
    }
    saveCartItems(); // Save cart after adding item
    notifyListeners();
  }

  // Clear the cart
  void clearCart() {
    _cartItems.clear();
    saveCartItems(); // Save cart after clearing
    notifyListeners();
  }
}
