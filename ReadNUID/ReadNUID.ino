#include <SPI.h>
#include <MFRC522.h>
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
#define USER_EMAIL "hao123@gmail.com"
#define USER_PASSWORD "1234567"

#define SS_PIN 21
#define RST_PIN 22
#define BUZZER_PIN 12         // Pin kết nối buzzer

MFRC522 rfid(SS_PIN, RST_PIN);  // Khởi tạo đối tượng MFRC522

FirebaseConfig config;
FirebaseAuth auth;
FirebaseData fbdo;

bool cardPresent = false;        // Biến theo dõi trạng thái thẻ
bool cardIn = false;             // Biến theo dõi trạng thái vào cổng


unsigned long lastScanTime = 0; // Thời điểm lần quét cuối
const unsigned long scanInterval = 1000; // Thời gian chờ giữa các lần quét (2 giây)


void setup() {
  Serial.begin(9600);
  pinMode(BUZZER_PIN, OUTPUT);

  // Khởi tạo SPI và RFID
  SPI.begin();
  rfid.PCD_Init();

  // Kết nối Wi-Fi
  Serial.print("Kết nối Wi-Fi");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(500);
  }
  Serial.println("\nĐã kết nối Wi-Fi với IP: ");
  Serial.println(WiFi.localIP());

  // Cấu hình Firebase
  Serial.printf("Firebase Client v%s\n\n", FIREBASE_CLIENT_VERSION);
  config.api_key = API_KEY;
  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;

  Firebase.begin(&config, &auth);
  Firebase.reconnectNetwork(true);

  // Kiểm tra đăng nhập
  if (auth.token.uid == "") {
    Serial.println("Lỗi đăng nhập Firebase.");
    Serial.println(fbdo.errorReason());
  } else {
    Serial.println("Đăng nhập thành công!");
  }

  Serial.println("Place your RFID card near the reader");
}

void updateFirestore(String cardID, String state) {
  FirebaseJson data;
  data.set("fields/States/stringValue", state);  // Sử dụng stringValue để lưu trữ trạng thái dưới dạng chuỗi

  String documentPath = "carts/" + cardID; // Đường dẫn tài liệu trong Firestore

  Serial.print("Đang cập nhật trạng thái vào Firestore... ");
  if (Firebase.Firestore.patchDocument(&fbdo, FIREBASE_PROJECT_ID, "", documentPath.c_str(), data.raw(), "States")) {
    Serial.println("Thành công!");
  } else {
    Serial.print("Lỗi: ");
    Serial.println(fbdo.errorReason());
  }
}

void updatePaymentStatus(String cardID, String paymentStatus) {
  FirebaseJson data;
  data.set("fields/payment/stringValue", paymentStatus);  // Sử dụng stringValue để lưu trữ trạng thái thanh toán

  String documentPath = "carts/" + cardID; // Đường dẫn tài liệu trong Firestore

  Serial.print("Đang cập nhật trạng thái thanh toán vào Firestore... ");
  if (Firebase.Firestore.patchDocument(&fbdo, FIREBASE_PROJECT_ID, "", documentPath.c_str(), data.raw(), "payment")) {
    Serial.println("Thành công!");
  } else {
    Serial.print("Lỗi: ");
    Serial.println(fbdo.errorReason());
  }
}

void checkResetAndUpdate(String cardID) {
    String documentPath = "carts/" + cardID;
    String mask = "payment"; // Chỉ truy vấn trường payment
    String currentState = "";

    // Truy vấn trạng thái hiện tại từ Firestore
    Serial.print("Đang lấy tài liệu từ Firestore... ");
    if (Firebase.Firestore.getDocument(&fbdo, FIREBASE_PROJECT_ID, "", documentPath.c_str(), mask.c_str())) {
        Serial.println("ok");
        Serial.printf("Dữ liệu trả về:\n%s\n", fbdo.payload().c_str());

        FirebaseJson content;

        if (currentState == "reset") {
            // Nếu trạng thái là "reset", chỉ cập nhật state về "0"
            content.set("fields/States/stringValue", "0");
            Serial.println("Reset trạng thái thành công!");
        } else {
            // Cập nhật cả state và payment nếu trạng thái khác reset
            content.set("fields/States/stringValue", "0");
            content.set("fields/payment/stringValue", "reset");
            Serial.println("Cập nhật trạng thái thanh toán reset.");
        }

        // Gửi cập nhật đến Firestore
        Serial.print("Đang cập nhật tài liệu... ");
        if (Firebase.Firestore.patchDocument(&fbdo, FIREBASE_PROJECT_ID, "", documentPath.c_str(), content.raw(), "States,payment")) {
            Serial.println("ok");
        } else {
            Serial.print("Lỗi: ");
            Serial.println(fbdo.errorReason());
        }
    } else {
        Serial.print("Lỗi khi lấy tài liệu: ");
        Serial.println(fbdo.errorReason());
    }
}


void loop() {
  if (millis() - lastScanTime >= scanInterval) { // Kiểm tra nếu đã đủ 2 giây
    lastScanTime = millis(); // Cập nhật thời gian lần quét cuối

    if (rfid.PICC_IsNewCardPresent() && rfid.PICC_ReadCardSerial()) {
      String cardID = getCardID(); // Lấy ID của thẻ

      if (!cardPresent) {
        cardPresent = true;

        if (!cardIn) {
          cardIn = true;           // Đánh dấu thẻ vào cổng
          Serial.println("Thẻ vào cổng: " + cardID);
          updateFirestore(cardID, "1"); // Cập nhật trạng thái vào Firestore
          updatePaymentStatus(cardID, "shopping"); // Cập nhật trạng thái thanh toán là chưa thanh toán
          triggerBuzzer();
        } else {
          cardIn = false;          // Đánh dấu thẻ ra cổng
          Serial.println("Thẻ ra cổng: " + cardID);
          // Kiểm tra trạng thái reset trước khi cập nhật
          checkResetAndUpdate(cardID);
          triggerBuzzer();
        }
      }
    } else {
      if (cardPresent) {
        cardPresent = false;       // Cập nhật lại trạng thái thẻ
      }
    }
  }
}

// Hàm lấy ID thẻ dưới dạng chuỗi
String getCardID() {
  String cardID = "";
  for (byte i = 0; i < rfid.uid.size; i++) {
    cardID += String(rfid.uid.uidByte[i], HEX);
  }
  cardID.toUpperCase();
  return cardID;
}

// Hàm bật buzzer
void triggerBuzzer() {
  digitalWrite(BUZZER_PIN, HIGH);
  delay(200);                  // Giữ buzzer trong 200ms
  digitalWrite(BUZZER_PIN, LOW);
}
