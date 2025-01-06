#include <WiFi.h>
#include <WebServer.h>
#include <Arduino.h>
#include <ESP_Panel_Library.h>
#include <Firebase_ESP_Client.h>
#include <lvgl.h>
#include "lvgl_port_v8.h"
#include <ui.h>
#include <ArduinoJson.h>

// Thông tin Wi-Fi
const char* ssid = "Liu";           // Tên Wi-Fi
const char* password = "1234567899";      // Mật khẩu Wi-Fi

String emailtem;
String passwordtem;
String uidtem;
String uidcarttem;

// Thông tin Firebase
#define API_KEY "AIzaSyCXmDZWnYTLqEAupa5L-EhGoDX1mfd7420" // API Key từ Firebase Console
#define FIREBASE_PROJECT_ID "cartsup-dca38" // Project ID từ Firebase Console

FirebaseData fbdo;            // Đối tượng dữ liệu Firebase
FirebaseAuth auth;            // Xác thực Firebase
FirebaseConfig config;        // Cấu hình Firebase

// Khởi tạo server tại cổng 80
WebServer server(80);
  // Subnet Mask


lv_obj_t * qrCode = NULL;
lv_obj_t * qrCodepay = NULL;

unsigned long qrCreateTime = 0;
unsigned long qrpayCreateTime = 0;

String vehicleUid = "937B2528";
String cocaColaSl;
String topChocoSl;
String wetWipesSl;
String total;

void crea_qrcode(lv_event_t * e)
{
    if (qrCode != NULL) {
        lv_obj_del(qrCode);  // Xóa mã QR cũ nếu tồn tại
    }

    // Lấy địa chỉ IP hiện tại
    String ipAddress = WiFi.localIP().toString();

    // Tạo mã QR mới
    qrCode = lv_qrcode_create(lv_scr_act(), 150, lv_palette_darken(LV_PALETTE_BLUE, 4), lv_palette_lighten(LV_PALETTE_LIGHT_BLUE, 5));
    String qrData = "http://" + ipAddress + "/sendCredentials";
    lv_qrcode_update(qrCode, qrData.c_str(), qrData.length());

    lv_obj_set_pos(qrCode, 550, 100);  // Đặt vị trí mã QR
    qrCreateTime = millis();  // Ghi nhận thời gian tạo mã QR
}






void setup() {
  // Setup Serial and LED
  Serial.begin(115200);

  // Connect to Wi-Fi
  Serial.println("Connecting to WiFi...");
  WiFi.begin(ssid, password);

  // Wait for Wi-Fi connection
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.print(".");
  }

  Serial.println("\nConnected to WiFi");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP()); // Display the IP address

  
  // Setup WebServer POST endpoint for receiving UID
  server.on("/sendCredentials", HTTP_POST, []() {
    if (server.hasArg("email") && server.hasArg("password") && server.hasArg("uid")) {
      String email = server.arg("email");
      String password = server.arg("password");
      String uid = server.arg("uid");

      emailtem = email;
      passwordtem = password;
      uidtem = uid;

      Serial.println("Received Credentials:");
      Serial.print("Email: ");
      Serial.println(email);
      Serial.print("Password: ");
      Serial.println(password);
      Serial.print("UID: ");
      Serial.println(uid);

      // Configure Firebase
      config.api_key = API_KEY;
      auth.user.email = email;
      auth.user.password = password;

      // Start Firebase
      Firebase.begin(&config, &auth);
      Serial.println("Firebase initialized.");

      // Send response back to the client
      server.send(200, "text/plain", 
        "Credentials received: Email = " + email + 
        ", Password = " + password + 
        ", Vehicle UID = " + vehicleUid);
    } else {
      server.send(400, "text/plain", "Missing email, password, or uid.");
    }
  });
    

  // Cấu hình bộ đệm cho FirebaseData
  fbdo.setBSSLBufferSize(4096, 1024);
  fbdo.setResponseSize(2048);

  // Start the server
  server.begin();
  Serial.println("HTTP server started");

  // Initialize Panel Device and LVGL
  Serial.println("Initialize panel device");
  ESP_Panel *panel = new ESP_Panel();
  panel->init();
#if LVGL_PORT_AVOID_TEAR
  // When avoid tearing function is enabled, configure the RGB bus according to LVGL configuration
  ESP_PanelBus_RGB *rgb_bus = static_cast<ESP_PanelBus_RGB *>(panel->getLcd()->getBus());
  rgb_bus->configRgbFrameBufferNumber(LVGL_PORT_DISP_BUFFER_NUM);
  rgb_bus->configRgbBounceBufferSize(LVGL_PORT_RGB_BOUNCE_BUFFER_SIZE);
#endif
  panel->begin();

  Serial.println("Initialize LVGL");

  lvgl_port_init(panel->getLcd(), panel->getTouch());

  Serial.println("Create UI");
  /* Lock the mutex due to the LVGL APIs being not thread-safe */
  lvgl_port_lock(-1);

  ui_init();
  lv_timer_handler();

  /* Release the mutex */
  lvgl_port_unlock();

  Serial.println("Startup complete");
}

void getDocument() {
    // Đường dẫn tài liệu cần đọc
    String documentPath = "/users/" + uidtem; // Sử dụng UID của người dùng đã đăng nhập

    Serial.print("Reading document... ");
    if (Firebase.Firestore.getDocument(&fbdo, FIREBASE_PROJECT_ID, "", documentPath.c_str())) {
         // Hiển thị nội dung tài liệu

                DynamicJsonDocument doc(1024); // Tạo một đối tượng JSON
                DeserializationError error = deserializeJson(doc, fbdo.payload());
                // Giả sử tài liệu có các trường "name", "email", và "id"
                // Cập nhật giao diện người dùng với dữ liệu từ tài liệu
                // Lấy dữ liệu từ các trường
          if (!error) {
                String email = doc["fields"]["email"]["stringValue"];
                String name = doc["fields"]["name"]["stringValue"];

                Serial.println("Email: " + email);
                Serial.println("Tên: " + name);

                // Đặt vị trí và kích thước cho nhãn ui_dataName
                lv_obj_set_x(ui_dataEmail, -65);
                lv_obj_set_y(ui_dataEmail, -35);

                lv_obj_set_x(ui_dataName, -190);
                lv_obj_set_y(ui_dataName, -100);


                // Cập nhật nội dung
                lv_label_set_text(ui_dataName, name.c_str());
                lv_label_set_text(ui_dataEmail, email.c_str());
         } else {
                          // Trường hợp không có dữ liệu hoặc lỗi
                lv_label_set_text(ui_dataName, "Error");
                lv_label_set_text(ui_dataEmail, "Error");
         }


    } else {
        Serial.print("Error: ");
        Serial.println(fbdo.errorReason()); // Hiển thị lỗi nếu không đọc được
    }
}

// Hàm ẩn thông báo lỗi
static void hide_error_message(lv_timer_t *timer) {
    lv_obj_t *label = (lv_obj_t *)timer->user_data;
    lv_label_set_text(label, ""); // Xóa nội dung
    lv_obj_add_flag(label, LV_OBJ_FLAG_HIDDEN); // Ẩn đối tượng
}

String createPaymentData() {
    // Tạo chuỗi dữ liệu thanh toán từ thông tin giỏ hàng và tổng tiền
    String paymentData = "Payment Successful\n";
    paymentData += "Coca-Cola: " + String(cocaColaSl) + "\n";
    paymentData += "Toppo Chocolate: " + String(topChocoSl) + "\n";
    paymentData += "Wet Wipes: " + String(wetWipesSl) + "\n";
    paymentData += "Total: " + String(total) + "\n";

    return paymentData;
}

void ui_event_paymentBtn(lv_event_t * e) {
    lv_event_code_t event_code = lv_event_get_code(e);

    if (event_code == LV_EVENT_PRESSED) {
        // Giả sử dữ liệu đã được lấy và lưu trong các biến sau:
        // cocaColaSl, topChocoSl, wetWipesSl, total
        // Giờ chỉ cần ghi dữ liệu vào Firestore

        if (cocaColaSl.toInt() > 0 || topChocoSl.toInt() > 0 || wetWipesSl.toInt() > 0) {
            // Tạo mã QR thanh toán mới
            paymentt(e);
            lv_obj_set_x(qrCodepay, 600);
            lv_obj_set_y(qrCodepay, 60);


            qrpayCreateTime = millis();  // Ghi nhận thời gian tạo mã QR thanh toán
        } else {
            // Nếu không có sản phẩm nào có số lượng > 0, xóa mã QR nếu đã tồn tại
            if (qrCodepay != NULL) {
                lv_obj_del(qrCodepay);  // Xóa mã QR
                qrCodepay = NULL;  // Đặt lại biến mã QR
                Serial.println("No product with quantity > 0. QR code removed.");
            }
        }
    }
}

void paymentt(lv_event_t * e)
{

    String paymentData = createPaymentData();

    // Xóa mã QR cũ nếu đã tồn tại
    if (qrCodepay != NULL) {
        lv_obj_del(qrCodepay);
    }


    // Tạo mã QR mới và cập nhật dữ liệu
    qrCodepay = lv_qrcode_create(ui_shopTabV, 150, lv_palette_darken(LV_PALETTE_BLUE, 4), lv_palette_lighten(LV_PALETTE_LIGHT_BLUE, 5));
    lv_qrcode_update(qrCodepay, paymentData.c_str(), paymentData.length());

    lv_obj_set_x(qrCodepay, 600);
    lv_obj_set_y(qrCodepay, 60);

    qrpayCreateTime = millis();  // Ghi nhận thời gian tạo mã QR thanh toán
}


void getCartData() {
    // Đường dẫn tới tài liệu giỏ hàng (cart)
    String cartPath = "/carts/" + vehicleUid;

    Serial.print("Reading cart data... ");
    if (Firebase.Firestore.getDocument(&fbdo, FIREBASE_PROJECT_ID, "", cartPath.c_str())) {
        Serial.println("Cart data retrieved successfully.");

        DynamicJsonDocument doc(4096);  // JSON Document để lưu dữ liệu
        DeserializationError error = deserializeJson(doc, fbdo.payload());

        if (!error) {
            // Lấy trạng thái payment
            String paymentStatus = doc["fields"]["payment"]["stringValue"];


            // Kiểm tra trạng thái "reset"
            if (paymentStatus == "reset") {
                Serial.println("Payment status is reset. Clearing cart data...");

                // Xử lý xóa/reset cart nếu trạng thái là reset
                lv_label_set_text(ui_sldata1, "0");
                lv_label_set_text(ui_sldata2, "0");
                lv_label_set_text(ui_sldata, "0");
                lv_label_set_text(ui_gia, "0");


            } else if(paymentStatus == "shopping"){
                // Đọc dữ liệu từ realCart
                cocaColaSl = doc["fields"]["realCart"]["mapValue"]["fields"]["Coca-Cola"]["mapValue"]["fields"]["sl"]["stringValue"].as<String>();
                topChocoSl = doc["fields"]["realCart"]["mapValue"]["fields"]["Toppo Chocolate"]["mapValue"]["fields"]["sl"]["stringValue"].as<String>();
                wetWipesSl = doc["fields"]["realCart"]["mapValue"]["fields"]["Wet Wipes"]["mapValue"]["fields"]["sl"]["stringValue"].as<String>();
                total = doc["fields"]["realCart"]["mapValue"]["fields"]["total"]["stringValue"].as<String>();
                String inforStatus = doc["fields"]["infor"]["stringValue"]; // Lấy trạng thái infor


                int cocaColaQuantity = cocaColaSl.toInt();
                int topChocoQuantity = topChocoSl.toInt();
                int wetWipesQuantity = wetWipesSl.toInt();

                // Cập nhật giao diện người dùng
                lv_label_set_text(ui_sldata1, cocaColaSl.c_str());
                lv_label_set_text(ui_sldata2, topChocoSl.c_str());
                lv_label_set_text(ui_sldata, wetWipesSl.c_str());
                lv_label_set_text(ui_gia, total.c_str());


                // Kiểm tra infor và cập nhật màn hình
                if (inforStatus == "0") {
                    // Không có lỗi, không hiển thị gì
                    lv_obj_add_flag(ui_errorMessage, LV_OBJ_FLAG_HIDDEN); // Ẩn thông báo lỗi
                } else if (inforStatus == "1") {
                    // Lỗi: Đã quét nhưng chưa nhận diện
                    lv_label_set_text(ui_errorMessage, "Product not scanned yet.\nPlease scan the correct one.");
                    lv_obj_clear_flag(ui_errorMessage, LV_OBJ_FLAG_HIDDEN); // Hiển thị thông báo

                    // Tạo timer để tự động ẩn thông báo sau 3 giây
                    lv_timer_t *timer = lv_timer_create(hide_error_message, 3000, ui_errorMessage);
                    lv_timer_set_repeat_count(timer, 1); // Chỉ chạy một lần
                } else if (inforStatus == "2") {
                    // Lỗi: Sản phẩm chưa quét nhưng lại có trong giỏ hàng
                    lv_label_set_text(ui_errorMessage, "Product detected but not scanned.\nPlease scan the product.");
                    lv_obj_clear_flag(ui_errorMessage, LV_OBJ_FLAG_HIDDEN); // Hiển thị thông báo

                    // Tạo timer để tự động ẩn thông báo sau 3 giây
                    lv_timer_t *timer = lv_timer_create(hide_error_message, 3000, ui_errorMessage);
                    lv_timer_set_repeat_count(timer, 1); // Chỉ chạy một lần
                }
            }
        } else {
            Serial.println("Error parsing cart data: " + String(error.c_str()));
        }
    } else {
        Serial.print("Error: ");
        Serial.println(fbdo.errorReason());  // Hiển thị lỗi nếu không đọc được
    }
}


void handleFirebase() {
  
    static bool documentRead = false;

    if (Firebase.ready() && ui_homeScreen != NULL) {
        if (auth.token.uid.length() > 0) {
            // The user is logged in
    //        Serial.println("Login successful!");
            lv_disp_load_scr(ui_homeScreen); 
            getCartData();
            getDocument(); // Only load home screen if logged in
           
        } else {
            // The user is logged out
         //   Serial.println("Login failed.");
            lv_disp_load_scr(ui_mainScreen);  // Load login screen or a different screen
        }
    } else {
   //     Serial.println("Firebase not ready or ui_loginSucScreen is NULL");
    }
}

void handleQRCodeTimeout() {
    // Kiểm tra nếu mã QR tồn tại và đã hết hạn
    if (qrCode != NULL && millis() - qrCreateTime >= 60000) {  // QR code timeout check
        lv_obj_del(qrCode);  // Xóa mã QR
        qrCode = NULL;  
    }
    
    // Xử lý timeout cho mã QR thanh toán
    if (qrCodepay != NULL && millis() - qrpayCreateTime >= 60000) {  // Payment QR code timeout check
        lv_obj_del(qrCodepay);  // Xóa mã QR thanh toán
        qrCodepay = NULL;  
    }
}


void ui_event_outBtn(lv_event_t * e) {
    lv_event_code_t event_code = lv_event_get_code(e);
    
    if (event_code == LV_EVENT_PRESSED ) {
        // Clear Firebase UID and sensitive dat
        uidtem = "";          // Clear local UID

        // Optionally, clear other sensitive data
        emailtem = "";
        passwordtem = "";

        lv_obj_clean(lv_disp_get_scr_act(NULL));
        // Load the main screen after logging out
        lv_disp_load_scr(ui_mainScreen);

    }
}


void loop() {
  // Xử lý giao diện của LVGL
  lv_timer_handler();

  // Xử lý các yêu cầu HTTP từ server
  server.handleClient();


  // Kiểm tra trạng thái Firebase và thực hiện các hành động liên quan
  handleFirebase();

  // Kiểm tra và xóa mã QR nếu đã hết thời gian hiển thị
  handleQRCodeTimeout();
}


