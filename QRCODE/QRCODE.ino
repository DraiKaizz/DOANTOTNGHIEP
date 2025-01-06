#include <Arduino.h>
#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <ArduinoJson.h>

/* 1. Cấu hình Wi-Fi */
#define WIFI_SSID "Liu"
#define WIFI_PASSWORD "1234567899"

/* 2. Cấu hình Firebase */
#define API_KEY "AIzaSyCXmDZWnYTLqEAupa5L-EhGoDX1mfd7420"
#define FIREBASE_PROJECT_ID "cartsup-dca38"


// Định nghĩa đối tượng Firebase
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

int states = 0; // Mặc định giá trị states là 0 (không cho phép gửi dữ liệu)
String payment = ""; 


// Định nghĩa cấu trúc sản phẩm
struct Product {
  String barcode; // Mã vạch sản phẩm
  String name;    // Tên sản phẩm
  float price;    // Giá sản phẩm
  int quantity;   // Số lượng sản phẩm
};

// Danh sách sản phẩm
Product products[] = {
  {"8852008510492", "Toppo Chocolate", 0.79, 0},
  {"8935049501503", "Coca-Cola", 0.47, 0},
  {"8936221250097", "Wet Wipes", 1.19, 0},
};

int productCount = sizeof(products) / sizeof(products[0]); // Số lượng sản phẩm trong danh sách

void updateFirestore() {
  FirebaseJson tempCartJson;

  // Lặp qua tất cả các sản phẩm và cập nhật thông tin của chúng
  for (int i = 0; i < productCount; i++) {
    // Cập nhật giá trị của mỗi sản phẩm trong giỏ hàng
    tempCartJson.set("fields/" + products[i].name + "/mapValue/fields/price/stringValue", String(products[i].price) + "$");
    tempCartJson.set("fields/" + products[i].name + "/mapValue/fields/sl/stringValue", String(products[i].quantity));
  }

  FirebaseJson data;
  data.set("fields/tempCart/mapValue", tempCartJson);

  // Đường dẫn tài liệu cần cập nhật
  String documentPath = "carts/937B2528"; // Đường dẫn tài liệu giỏ hàng

  // Mask chỉ định trường cần cập nhật
  String updateMask = "tempCart";

  Serial.print("Đang cập nhật dữ liệu lên Firestore... ");
  if (Firebase.Firestore.patchDocument(&fbdo, FIREBASE_PROJECT_ID, "", documentPath.c_str(), data.raw(), updateMask.c_str())) {
    Serial.println("Cập nhật thành công!");
  } else {
    Serial.print("Lỗi Firestore: ");
    Serial.println(fbdo.errorReason());
  }
}

void updateProductListFromFirestore() {
  String documentPath = "carts/937B2528"; // Đường dẫn tài liệu trong Firestore

  // Lấy tài liệu từ Firestore
  if (Firebase.Firestore.getDocument(&fbdo, FIREBASE_PROJECT_ID, "", documentPath.c_str())) {
    FirebaseJson data;
    data.setJsonData(fbdo.payload());  // Lấy dữ liệu JSON từ Firestore

    // Cập nhật thông tin giỏ hàng trong Arduino từ Firestore
    for (int i = 0; i < productCount; i++) {
      String productName = products[i].name;

      // Xây dựng đường dẫn cho giá trị sản phẩm và số lượng trong Firestore
      String priceField = "fields/tempCart/mapValue/fields/" + productName + "/mapValue/fields/price/stringValue";
      String quantityField = "fields/tempCart/mapValue/fields/" + productName + "/mapValue/fields/sl/stringValue";

      // Lấy giá trị từ Firestore
      FirebaseJsonData priceData;
      FirebaseJsonData quantityData;

      // Lấy giá trị của priceField
      if (data.get(priceData, priceField)) {
        String priceStr = priceData.stringValue;
        priceStr.replace("$", "");  // Loại bỏ ký hiệu "$" nếu có
        products[i].price = priceStr.toFloat(); // Cập nhật giá sản phẩm
      }

      // Lấy giá trị của quantityField
      if (data.get(quantityData, quantityField)) {
        products[i].quantity = quantityData.intValue; // Cập nhật số lượng sản phẩm
      }
    }

    // Hiển thị giỏ hàng đã được cập nhật
    Serial.println("Giỏ hàng đã được cập nhật từ Firestore:");
    for (int i = 0; i < productCount; i++) {
      Serial.print("Sản phẩm: ");
      Serial.print(products[i].name);
      Serial.print(" - Giá: ");
      Serial.print(products[i].price, 2);
      Serial.print(" - Số lượng: ");
      Serial.println(products[i].quantity);
    }

  } else {
    // Xử lý lỗi nếu không lấy được tài liệu từ Firestore
    Serial.print("Lỗi khi lấy dữ liệu từ Firestore: ");
    Serial.println(fbdo.errorReason());
  }
}

void checkProduct(String scannedBarcode) {
  bool found = false;

  scannedBarcode.trim(); // Loại bỏ khoảng trắng

  // Lặp qua tất cả các sản phẩm
  for (int i = 0; i < productCount; i++) {
    if (products[i].barcode == scannedBarcode) { // Tìm thấy sản phẩm
      Serial.print("Sản phẩm: ");
      Serial.print(products[i].name);
      Serial.print(" - Giá: ");
      Serial.print(products[i].price, 2);
      products[i].quantity++; // Tăng số lượng
      Serial.print(" - Số lượng: ");
      Serial.println(products[i].quantity);

      // Cập nhật Firestore cho tất cả các sản phẩm trong giỏ hàng
      updateFirestore(); // Cập nhật toàn bộ giỏ hàng lên Firestore

      found = true;
      break;
    }
  }

  if (!found) {
    Serial.println("Không tìm thấy sản phẩm.");
  }

  // Hiển thị tất cả các sản phẩm trong giỏ hàng
  Serial.println("\nTất cả sản phẩm trong giỏ hàng:");
  for (int i = 0; i < productCount; i++) {
    Serial.print("Sản phẩm: ");
    Serial.print(products[i].name);
    Serial.print(" - Giá: ");
    Serial.print(products[i].price, 2);
    Serial.print(" - Số lượng: ");
    Serial.println(products[i].quantity); // Số lượng có thể là 0 hoặc tăng lên tùy vào việc có quét hay không
  }
}

// Hàm reset giỏ hàng sau thanh toán
void resetCart() {
  for (int i = 0; i < productCount; i++) {
    products[i].quantity = 0;
  }

  // Xóa dữ liệu giỏ hàng trên Firestore
  FirebaseJson data;
  data.set("fields/tempCart/mapValue", FirebaseJson());
  String documentPath = "carts/937B2528";
  String updateMask = "tempCart";

  if (Firebase.Firestore.patchDocument(&fbdo, FIREBASE_PROJECT_ID, "", documentPath.c_str(), data.raw(), updateMask.c_str())) {
    Serial.println("Giỏ hàng đã reset trên Firestore!");
  } else {
    Serial.print("Lỗi khi reset giỏ hàng: ");
    Serial.println(fbdo.errorReason());
  }

  Serial.println("Giỏ hàng đã được reset.");
}

void getStatesField() {
    // Đường dẫn tài liệu cần đọc từ Firestore
    String documentPath = "carts/937B2528"; 
    Serial.print("Đang đọc giá trị của trường 'states'... ");
    
    // Chỉ lấy giá trị của trường 'states' từ Firebase Firestore
    if (Firebase.Firestore.getDocument(&fbdo, FIREBASE_PROJECT_ID, "", documentPath.c_str())) {
        // Khai báo FirebaseJson để xử lý dữ liệu JSON trả về
        FirebaseJson json;
        json.setJsonData(fbdo.payload());

        // Truy xuất giá trị của trường "states"
        FirebaseJsonData jsonData;
        if (json.get(jsonData, "fields/States/stringValue")) {
            states = jsonData.intValue; // Gán giá trị vào biến states
            Serial.printf("Giá trị của states: %d\n", states);
        } else {
            Serial.println("Không tìm thấy trường 'states'");
        }
    } else {
        // Hiển thị lý do lỗi chi tiết
        Serial.print("Lỗi: ");
        Serial.println(fbdo.errorReason());
    }
}

// Hàm lấy trường 'payment' từ Firestore
void getPaymentField() {
    String documentPath = "carts/937B2528"; // Đường dẫn tài liệu cần đọc từ Firestore
    Serial.print("Đang đọc giá trị của trường 'payment'... ");
    
    // Chỉ lấy giá trị của trường 'payment' từ Firebase Firestore
    if (Firebase.Firestore.getDocument(&fbdo, FIREBASE_PROJECT_ID, "", documentPath.c_str())) {
        // Khai báo FirebaseJson để xử lý dữ liệu JSON trả về
        FirebaseJson json;
        json.setJsonData(fbdo.payload());

        // Truy xuất giá trị của trường "payment"
        FirebaseJsonData jsonData;
        if (json.get(jsonData, "fields/payment/stringValue")) {
            payment = jsonData.stringValue; // Gán giá trị chuỗi vào biến payment
            Serial.print("Giá trị của payment: ");
            Serial.println(payment); // In ra giá trị thanh toán
        } else {
            Serial.println("Không tìm thấy trường 'payment' hoặc không phải là chuỗi.");
        }
    } else {
        // Hiển thị lý do lỗi chi tiết
        Serial.print("Lỗi: ");
        Serial.println(fbdo.errorReason());
    }
}


// Cài đặt ban đầu
void setup() {
  Serial.begin(9600);
  Serial.println("Hệ thống quét mã vạch đã sẵn sàng!");

  // Kết nối Wi-Fi
  Serial.print("Kết nối Wi-Fi");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(500);
  }
  Serial.println();
  Serial.print("Đã kết nối Wi-Fi với IP: ");
  Serial.println(WiFi.localIP());
  // Cấu hình Firebase
  Serial.printf("Firebase Client v%s\n\n", FIREBASE_CLIENT_VERSION);

  config.api_key = API_KEY;


  // Bắt đầu Firebase
  Firebase.begin(&config, &auth);
  Firebase.reconnectNetwork(true);

  // Kiểm tra đăng nhập
  if (auth.token.uid == "") {
    Serial.println("Lỗi đăng nhập Firebase.");
    // Kiểm tra lý do lỗi thông qua fbdo
    Serial.println(fbdo.errorReason());  // In ra lý do lỗi chi tiết
  } else {
    Serial.println("Đăng nhập thành công!");
  }

  // Cấu hình Firebase Data object
  fbdo.setBSSLBufferSize(4096, 1024);
  fbdo.setResponseSize(2048);
}

void loop() {
  // Lấy giá trị 'states' để kiểm tra trạng thái
  getStatesField();
  getPaymentField();
  updateProductListFromFirestore();

  // Kiểm tra nếu states == 1 và payment == "shopping" thì cho phép quét mã vạch
  if (states == 1 && payment == "shopping") {
    if (Serial.available() > 0) {
      String scannedBarcode = Serial.readString();
      scannedBarcode.trim();

      Serial.print("Mã vạch đã quét: ");
      Serial.println(scannedBarcode);

      // Kiểm tra mã vạch
      checkProduct(scannedBarcode);

      // Lệnh reset giỏ hàng
      if (scannedBarcode == "reset") {
        resetCart();
      }
    }
  } else {
    // Nếu states != 1 hoặc payment không phải là "shopping", không cho phép quét mã vạch
    Serial.println("Không được phép quét mã vạch. Trạng thái 'states' là 0 hoặc trạng thái thanh toán không đúng.");
  }

  
}
