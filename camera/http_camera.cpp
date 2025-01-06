#include <Arduino.h>
#include <WiFi.h>
#include "http_camera.h"
#include "camera_pins.h"

// Constructor for HTTPCamera class
HTTPCamera::HTTPCamera() {}

// Method to begin camera and server setup
void HTTPCamera::begin(httpd_handle_t server) {
    Serial.begin(115200);
    Serial.setDebugOutput(true);
    Serial.println();

    // Cấu hình camera
    camera_config_t config;
    config.ledc_channel = LEDC_CHANNEL_0;
    config.ledc_timer = LEDC_TIMER_0;
    config.pin_d0 = Y2_GPIO_NUM;
    config.pin_d1 = Y3_GPIO_NUM;
    config.pin_d2 = Y4_GPIO_NUM;
    config.pin_d3 = Y5_GPIO_NUM;
    config.pin_d4 = Y6_GPIO_NUM;
    config.pin_d5 = Y7_GPIO_NUM;
    config.pin_d6 = Y8_GPIO_NUM;
    config.pin_d7 = Y9_GPIO_NUM;
    config.pin_xclk = XCLK_GPIO_NUM;
    config.pin_pclk = PCLK_GPIO_NUM;
    config.pin_vsync = VSYNC_GPIO_NUM;
    config.pin_href = HREF_GPIO_NUM;
    config.pin_sccb_sda = SIOD_GPIO_NUM;
    config.pin_sccb_scl = SIOC_GPIO_NUM;
    config.pin_pwdn = PWDN_GPIO_NUM;
    config.pin_reset = RESET_GPIO_NUM;
    config.xclk_freq_hz = 20000000;

    config.pixel_format = PIXFORMAT_JPEG;
    config.frame_size = FRAMESIZE_VGA;
    config.jpeg_quality = 12;
    config.fb_count = 1;

    // Khởi động camera
    esp_err_t err = esp_camera_init(&config);
    if (err != ESP_OK) {
        Serial.printf("Camera init failed with error 0x%x", err);
        return;
    }

    // Initialize the flash GPIO pin
    pinMode(FLASH_GPIO_NUM, OUTPUT);
    digitalWrite(FLASH_GPIO_NUM, LOW);

    // Bắt đầu server camera
    startCameraServer(server);

    Serial.print("Camera Stream Ready! Go to: http://");
    Serial.print(WiFi.localIP());
    Serial.println("/stream");
}

// Method to start the camera server and define routes
void HTTPCamera::startCameraServer(httpd_handle_t server) {
    httpd_uri_t stream_uri = {
        .uri = "/stream",
        .method = HTTP_GET,
        .handler = stream_handler,
        .user_ctx = NULL
    };

    if (httpd_register_uri_handler(server, &stream_uri) != ESP_OK) {
        Serial.println("Failed to register stream URI");
    }

    // Register the toggle-light URI
    httpd_uri_t toggle_light_uri = {
        .uri = "/toggle-light",
        .method = HTTP_GET,
        .handler = toggle_light_handler,
        .user_ctx = NULL
    };

    if (httpd_register_uri_handler(server, &toggle_light_uri) != ESP_OK) {
        Serial.println("Failed to register toggle-light URI");
    }
}

// Stream handler function
esp_err_t HTTPCamera::stream_handler(httpd_req_t *req) {
    camera_fb_t *fb = NULL;
    esp_err_t res = ESP_OK;
    size_t _jpg_buf_len = 0;
    uint8_t *_jpg_buf = NULL;
    char part_buf[64];

    res = httpd_resp_set_type(req, "multipart/x-mixed-replace;boundary=frame");
    if (res != ESP_OK) {
        return res;
    }

    while (true) {
        fb = esp_camera_fb_get();
        if (!fb) {
            Serial.println("Camera capture failed");
            res = ESP_FAIL;
        } else {
            if (fb->format != PIXFORMAT_JPEG) {
                bool jpeg_converted = frame2jpg(fb, 80, &_jpg_buf, &_jpg_buf_len);
                esp_camera_fb_return(fb);
                fb = NULL;
                if (!jpeg_converted) {
                    Serial.println("JPEG compression failed");
                    res = ESP_FAIL;
                }
            } else {
                _jpg_buf_len = fb->len;
                _jpg_buf = fb->buf;
            }
        }
            if (res == ESP_OK) {
                size_t hlen = snprintf((char *)part_buf, 64, "Content-Type: image/jpeg\r\nContent-Length: %u\r\n\r\n", _jpg_buf_len);
                res = httpd_resp_send_chunk(req, (const char *)part_buf, hlen);
            }
            if (res == ESP_OK) {
                res = httpd_resp_send_chunk(req, (const char *)_jpg_buf, _jpg_buf_len);
            }
            if (res == ESP_OK) {
                res = httpd_resp_send_chunk(req, "\r\n--frame\r\n", 12);
            }
            if (fb) {
                esp_camera_fb_return(fb);
                fb = NULL;
                _jpg_buf = NULL;
            } else if (_jpg_buf) {
                free(_jpg_buf);
                _jpg_buf = NULL;
            }
            if (res != ESP_OK) {
                break;
            }
            delay(10); // Đợi để giảm tốc độ khung hình
        }
    return res;
}

// Handler function for toggling the light
esp_err_t HTTPCamera::toggle_light_handler(httpd_req_t *req) {
    static bool is_light_on = false; // Track the state of the light

    // Toggle the light state
    is_light_on = !is_light_on;
    digitalWrite(FLASH_GPIO_NUM, is_light_on ? HIGH : LOW);

    // Send response
    String response = is_light_on ? "Light is ON" : "Light is OFF";
    httpd_resp_sendstr(req, response.c_str());

    return ESP_OK;
}
