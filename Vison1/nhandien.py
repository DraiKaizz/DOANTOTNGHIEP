import firebase_admin
from firebase_admin import credentials, firestore
import json
import time
import os
# Sử dụng Service Account Key để xác thực
cred = credentials.Certificate("serviceAccountKey.json")  # Đảm bảo rằng đây là tệp JSON tải từ Firebase Console
firebase_admin.initialize_app(cred)

# Khởi tạo tham chiếu đến Firestore
db = firestore.client()

# Đường dẫn đến file JSON
temp_cart_file = "tempCart.json"
real_cart_file = "realCart.json"
total_price_file = "total_price.json"
info_file = "info.json"

# Hàm xử lý thay đổi từ Firestore và đồng bộ với JSON
def on_snapshot(doc_snapshot, changes, read_time):
    for doc in doc_snapshot:
        print(f"Nhận được thay đổi trong document: {doc.id}")
        data = doc.to_dict()
        temp_cart = data.get("tempCart", None)

        if temp_cart:
            print("Đã đọc dữ liệu tempCart từ Firestore:")
            print(temp_cart)
            
            # Lưu dữ liệu tempCart vào file JSON
            try:
                with open(temp_cart_file, "w", encoding="utf-8") as json_file:
                    json.dump(temp_cart, json_file, ensure_ascii=False, indent=4)
                print(f"Dữ liệu tempCart đã được lưu vào file '{temp_cart_file}'")
            except Exception as e:
                print(f"Lỗi khi lưu dữ liệu vào file JSON: {e}")

            # Ghi trường "processedAt" vào Firestore
            new_data = {"processedAt":None}
            try:
                doc_ref = db.collection("carts").document(doc.id)
                doc_ref.update(new_data)
                print("Đã ghi processedAt vào Firestore.")
            except Exception as e:
                print(f"Lỗi khi cập nhật Firestore: {e}")

# Hàm đồng bộ dữ liệu từ file JSON lên Firestore
def sync_json_to_firestore():
    try:
        # Kiểm tra xem file JSON có tồn tại không
        if os.path.exists(temp_cart_file):
            with open(temp_cart_file, "r", encoding="utf-8") as json_file:
                temp_cart = json.load(json_file)

            if temp_cart:
                # Cập nhật Firestore với dữ liệu từ file JSON
                doc_ref = db.collection("carts").document("937B2528")
                doc_ref.update({"tempCart": temp_cart})
                print(f"Dữ liệu từ file '{temp_cart_file}' đã được ghi vào Firestore.")
            else:
                print(f"File '{temp_cart_file}' không chứa dữ liệu hợp lệ.")
        else:
            print(f"File '{temp_cart_file}' không tồn tại.")
    except Exception as e:
        print(f"Lỗi khi ghi dữ liệu vào Firestore từ file JSON: {e}")

# Đăng ký lắng nghe thay đổi từ Firestore
doc_ref = db.collection("carts").document("937B2528")
doc_watch = doc_ref.on_snapshot(on_snapshot)

print("Đang lắng nghe thay đổi dữ liệu từ Firestore...")


# Hàm đọc dữ liệu từ file JSON và ghi vào Firestore
def write_data_to_firestore():
    try:
        # Đọc dữ liệu từ file realCart.json
        with open(real_cart_file, "r", encoding="utf-8") as json_file:
            real_cart_data = json.load(json_file)


        if real_cart_data:

            # Tạo dữ liệu để ghi vào Firestore
            # Tạo dữ liệu để ghi vào Firestore
            data_to_update = {"realCart": real_cart_data}

            # Đọc dữ liệu từ file info.json
            try:
                with open(info_file, "r", encoding="utf-8") as info_json_file:
                    info_data = json.load(info_json_file)
                    if "infor" in info_data:
                        data_to_update["infor"] = info_data["infor"]  # Ghi trường 'infor' vào Firestore
            except FileNotFoundError:
                print(f"File '{info_file}' không tồn tại.")
            except Exception as e:
                print(f"Lỗi khi đọc dữ liệu từ file '{info_file}': {e}")
                
            # Đọc dữ liệu từ file total_price.json
            try:
                with open(total_price_file, "r", encoding="utf-8") as total_json_file:
                    total_data = json.load(total_json_file)
                    if "total" in total_data:
                        data_to_update["realCart"]["total"] = total_data["total"]  # Ghi trường 'total' vào Firestore
            except FileNotFoundError:
                print(f"File '{total_price_file}' không tồn tại.")
            except Exception as e:
                print(f"Lỗi khi đọc dữ liệu từ file '{total_price_file}': {e}")



            # Cập nhật vào Firestore
            doc_ref = db.collection("carts").document("937B2528")
            doc_ref.update(data_to_update)
            print(f"Dữ liệu từ '{real_cart_file}' đã được ghi vào Firestore.")
        else:
            print(f"File '{real_cart_file}' không chứa dữ liệu hợp lệ.")
    except FileNotFoundError:
        print(f"File '{real_cart_file}' không tồn tại.")
    except Exception as e:
        print(f"Lỗi khi ghi dữ liệu vào Firestore: {e}")



# Vòng lặp chính để chạy liên tục
while True:
    try:
        # Gọi hàm để ghi dữ liệu từ file JSON vào Firestore
        write_data_to_firestore()
        sync_json_to_firestore()
        # Delay trước lần lặp tiếp theo
        time.sleep(1)  # Thời gian delay, tùy chỉnh theo nhu cầu (đơn vị: giây)
    except Exception as e:
        print(f"Lỗi xảy ra trong vòng lặp chính: {e}")
        time.sleep(3)  # Delay 5 giây nếu có lỗi
