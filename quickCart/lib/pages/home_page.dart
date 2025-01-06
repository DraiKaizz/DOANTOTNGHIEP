import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickcart/pages/profile_page.dart';
import 'package:quickcart/pages/qr_page.dart';
import 'package:quickcart/pages/settings_page.dart';
import 'package:quickcart/pages/history_page.dart';  // Import HistoryPage
import 'package:provider/provider.dart';
import '../components/grocery_item_tile.dart';
import '../model/cart_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // Current tab index

  // Danh sách các trang, bao gồm cả HistoryPage
  final List<Widget> _pages = [
    HomePageContent(), // Nội dung trang Home
    const HistoryPage(),  // Keep the HistoryPage
    const QrScanScreen(),
    const ProfilePage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex, // Chỉ số của trang hiện tại
        children: _pages, // Danh sách các trang
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      items: <BottomNavigationBarItem>[
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.history), // History icon
          label: 'History', // Label for the History section
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.qr_code), // QR code icon
          label: 'QR Code', // Label for the QR Code section
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person), // Profile icon
          label: 'Profile', // Label for the Profile section
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.blueAccent, // Change selected item color
      unselectedItemColor: Colors.grey, // Change unselected item color
      backgroundColor: Colors.white, // Background color of the bottom nav
      onTap: (index) {
        setState(() {
          _selectedIndex = index; // Cập nhật chỉ số trang hiện tại
        });
      },
    );
  }
}

class HomePageContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white, // Màu trắng
            Colors.lightBlueAccent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildGreeting(),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              _buildFreshItemsHeader(),
              const SizedBox(height: 16),
              _buildItemGrid(context), // Truyền context vào đây
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'QuickCart,',
            style: GoogleFonts.lobster(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Bites, Drinks & Supplies',
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueGrey[800],
                  ),
                ),
                const TextSpan(text: ' | ', style: TextStyle(color: Colors.black)),
                TextSpan(
                  text: 'Let’s Order Now',
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6CEBF6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFreshItemsHeader() {
    return Center(
      child: Text(
        'All Products',
        style: GoogleFonts.notoSerif(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildItemGrid(BuildContext context) { // Nhận context
    return Expanded(
      child: Consumer<CartModel>( // Lắng nghe CartModel để có sản phẩm
        builder: (context, cartModel, child) {
          return GridView.builder(
            itemCount: cartModel.shopItems.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1 / 1.3,
            ),
            itemBuilder: (context, index) {
              final item = cartModel.shopItems[index];
              return _buildGroceryItem(item, index, context); // Truyền context vào đây
            },
          );
        },
      ),
    );
  }

  Widget _buildGroceryItem(CartItem item, int index, BuildContext context) { // Nhận context
    Color itemColor;

    switch (item.name.toLowerCase()) {
      case 'chocolate':
        itemColor = const Color(0xFFE0B0FF);
        break;
      case 'cocacola':
        itemColor = const Color(0xFFFFC107);
        break;
      case 'khangiay':
        itemColor = const Color(0xFF81D4FA);
        break;
      default:
        itemColor = const Color(0xFFCCE2EF);
    }

    return Card(
      elevation: 8,
      margin: const EdgeInsets.all(8.0),
      color: itemColor,
      child: GroceryItemTile(
        itemName: item.name,
        itemPrice: '\$${item.price}',
        imagePath: item.imagePath,
        color: Colors.transparent,
        onPressed: () {
          // Disable the "Add to Cart" functionality by leaving this empty or removing the callback
        },
      ),
    );
  }
}
