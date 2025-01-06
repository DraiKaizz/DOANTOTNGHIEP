import cv2
import numpy as np
import time
from ultralytics import YOLO
import os
import logging
import json

import urllib.request
import urllib.error

# Đặt giá mặc định cho các sản phẩm trong tempcart nếu không có giá
DEFAULT_PRICES = {
    "Coca-Cola": 0.47,  
    "Wet Wipes": 1.19, 
    "Toppo Chocolate": 0.79  
}

# Tắt tất cả các log không phải lỗi
logging.basicConfig(level=logging.ERROR)

# Tắt log của YOLO
os.environ['PYTHONWARNINGS'] = "ignore"  # Tắt cảnh báo
logging.getLogger("ultralytics").setLevel(logging.WARNING)


# Tải mô hình YOLO
model = YOLO(f"{os.getcwd()}/runs/detect/train2/weights/best.pt")

# Địa chỉ camera máy tính
#camera_index = 0  # Sử dụng camera mặc định (0 là camera đầu tiên)
url = "http://192.168.137.101/stream"

# Hàm đọc giỏ hàng tạm thời từ file

def load_temp_cart():
    try:
        with open("tempcart.json", "r") as file:
            data = json.load(file)
            print("Loaded temp cart:", data)
            if not isinstance(data, dict):  # Ensure it's a dictionary
                raise ValueError("Invalid temp cart format. Expected a dictionary.")
            return data
    except Exception as e:
        print(f"Error loading tempcart.json: {e}")
        return {}

# Hàm lưu giỏ hàng thực tế vào file
def save_real_cart(real_cart):
    try:

        with open("realcart.json", "w") as file:
            json.dump(real_cart, file, indent=4)
            print("Real cart updated:", real_cart)
    except Exception as e:
        print(f"Error saving realcart.json: {e}")

def save_temp_cart(temp_cart):
    try:
        with open("tempcart.json", "w") as file:
            json.dump(temp_cart, file, indent=4)
            print("Temp cart updated:", temp_cart)
    except Exception as e:
        print(f"Error saving tempcart.json: {e}")

def save_total_price(total_price):
    try:
        # Format the total price as a string with a dollar sign at the end
        formatted_price = f"{total_price:.2f}$"
        with open("total_price.json", "w") as file:
            json.dump({"total": formatted_price}, file, indent=4)
            print("Total price saved:", formatted_price)
    except Exception as e:
        print(f"Error saving total_price.json: {e}")

def save_info(info):
    try:
        data_to_save = {"infor": info}
        with open("info.json", "w") as file:
            json.dump(data_to_save, file, indent=4)
            print("Info saved:", info)
    except Exception as e:
        print(f"Error saving info.json: {e}")

def stream_video(url):
    temp_cart = load_temp_cart()
    real_cart = {}
    last_detected_time = {}
    info = "0" 
    last_update_time = None
    wait_interval = 15  # Thời gian chờ là 15 giây
    wait_interval1 = 7

    # Khởi tạo real_cart với tất cả các mặt hàng được thiết lập là 0 ban đầu
    for item, details in temp_cart.items():
        if item in DEFAULT_PRICES:
            real_cart[item] = {'sl': '0', 'price': f"{DEFAULT_PRICES[item]}$"}
        else:
            print(f"Price for {item} is not defined in DEFAULT_PRICES.")   # Thiết lập tất cả các mặt hàng là 0 ban đầu
        last_detected_time[item] = time.time()  # Khởi tạo thời gian nhận diện ban đầu

    label_mapping = {
        "khan_giay": "Wet Wipes",
        "coca_cola": "Coca-Cola",
        "banh_toppo_socola": "Toppo Chocolate"
    }

    bytes_stream = b""

    while True:
        try:
            with urllib.request.urlopen(url) as stream:
                while True:
                    bytes_stream += stream.read(1024)
                    a = bytes_stream.find(b"\xff\xd8")  # Start of JPEG
                    b = bytes_stream.find(b"\xff\xd9")  # End of JPEG

                    if a != -1 and b != -1:
                        jpg = bytes_stream[a : b + 2]
                        bytes_stream = bytes_stream[b + 2 :]

                        img_np = np.frombuffer(jpg, dtype=np.uint8)
                        img = cv2.imdecode(img_np, cv2.IMREAD_COLOR)

                        if img is not None:
                            # Lật hình ảnh
                            img = cv2.flip(img, 1)  # Lật ngang và dọc (xoay 180 độ)
                            img = cv2.resize(img, (640, 480))

                            # Phát hiện đối tượng bằng YOLO
                            results = model(img, conf=0.9)

                            count_in_image = {label: 0 for label in label_mapping.values()}
                            
                            detected_labels = []
                            temp_cart = load_temp_cart()
                            current_time = time.time()  # Lấy thời gian hiện tại
                            info_sum = 0
                            check = False
                             # Initialize as integer instead of string ""
                                        # Đoạn mã này nên nằm trong vòng lặp for để đảm bảo biến item có phạm vi hợp lệ
                            for item in real_cart:
                                if int(temp_cart[item]["sl"]) > 0:
                                    # Reset lại số lượng là 0 cho các mặt hàng cần theo dõi
                                    # Lấy giá từ bảng giá mặc định DEFAULT_PRICES
                                    if item in DEFAULT_PRICES:
                                        real_cart[item] = {'sl': '0', 'price': f"{DEFAULT_PRICES[item]}$"}
                                    else:
                                        print(f"Price for {item} is not defined in DEFAULT_PRICES.")


                                    # Lấy thời gian hiện tại
                                if int(temp_cart[item]['sl']) > int(real_cart[item]['sl']):
                                    info = "1"
                                    info_sum += int(info)
                                    if info_sum >= 1:
                                        info_sum = 1  #                                          

                                elif int(temp_cart[item]['sl']) == int(real_cart[item]['sl']): 
                                    info = "0"
                                    save_info(info)
                                        # Cập nhật thời gian cuối cùng ngay cả khi số lượng đúng

                                if info_sum == 1:
                                    current_time = time.time() 
                                    if last_update_time is None or (current_time - last_update_time) > wait_interval:
                                        print(f"Thiếu hàng cho {item}. Cần thêm.")
                                        temp_cart[item]['sl'] = '0'
                                        save_temp_cart(temp_cart)  # Lưu lại temp_cart sau khi cập nhật
                                        last_update_time = current_time  # Cập nhật thời gian cuối cùng
                                        info = "0"                                                                    
                                        
                            if info_sum >= 1:
                                info_sum = 1  # Set info to "1" if info_sum is greater than 1
                            # Kiểm tra thời gian đã trôi qua
                                            
                                    # Cập nhật biến tích lũy

                            # Sau khi hoàn thành vòng lặp, lưu tổng giá trị info
                            save_info(str(info_sum))  # Convert to string when saving
                    

                            if results:
                                for result in results:
                                    boxes = result.boxes
                                    if boxes:
                                        for box in boxes:
                                            x1, y1, x2, y2 = box.xyxy.tolist()[0]
                                            c = box.cls
                                            x1, y1, x2, y2 = int(x1), int(y1), int(x2), int(y2)
                                            label = model.names[int(c)]
                                            label_mapped = label_mapping.get(label, label)

                                            print(f"Detected: {label_mapped}")
                                            detected_labels.append(label_mapped)
                                            if label_mapped in count_in_image:
                                                count_in_image[label_mapped] += 1  # Increment the count for detected labels
                                            temp_cart = load_temp_cart()


                                            if label_mapped in temp_cart:
                                                if temp_cart[label_mapped]["sl"] != '0':  # Kiểm tra số lượng mong muốn khác '0'
                                                    # Cập nhật real_cart với số lượng từ count_in_image
                                                    real_cart[label_mapped]['sl'] = str(count_in_image[label_mapped])
                                                    # Cập nhật thời gian phát hiện cuối cùng cho sản phẩm này
                                                    last_detected_time[label_mapped] = current_time
                                                else:
                                                    print(f"{label_mapped} có số lượng mong muốn là '0', không cập nhật.")
                                            else:
                                                print(f"{label_mapped} không tìm thấy trong temp_cart, không cập nhật.")
                                            
                                            
                                            info_sum1 = 0 
                                            for product, detected_count in count_in_image.items():
                                                if product in temp_cart:
                                                    current_time = time.time()
                                                    # So sánh trực tiếp giữa số lượng phát hiện và số lượng mong muốn trong temp_cart
                                                    if detected_count > int(temp_cart[product]['sl']):
                                                        info = "2"
                                                        info_sum1 += int(info) 
                                                        
                                                    if 1 < info_sum1 > 3:
                                                        info_sum1 = 2  # Set info_sum1 to 2 if it is greater than 1 and less than 3

                                                    else:
                                                        info = "0"

                                            save_info(str(info_sum1))
                                            cv2.rectangle(img, (x1, y1), (x2, y2), (0, 0, 255), 2)
                                            cv2.putText(
                                                img,
                                                label_mapped,
                                                (x1, y1 - 10),
                                                cv2.FONT_HERSHEY_SIMPLEX,
                                                0.9,
                                                (0, 255, 0),
                                                2,
                                            )

                            total_price = sum(
                                int(details['sl']) * float(details['price'].replace('$', ''))  # Remove '$' before conversion
                                for item, details in real_cart.items() if item != "total"
                            )
                            print(f"Total price of detected items: {total_price}")
                            save_total_price(total_price)

                            save_real_cart(real_cart)
                            cv2.imshow("ESP32-CAM Stream", img)

                            if cv2.waitKey(1) & 0xFF == ord("q"):
                                print("Exiting...")
                                return
        except urllib.error.HTTPError as e:
            print(f"HTTP Error: {e.code} - {e.reason}")
            time.sleep(1)
        except Exception as e:
            print(f"Error: {e}")
            time.sleep(1)
        finally:
            cv2.destroyAllWindows()


if __name__ == "__main__":
    stream_video(url)
