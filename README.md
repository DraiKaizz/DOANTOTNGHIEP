Mô tả Đề tài

Tên Đề tài: Thiết kế xe đẩy hàng siêu thị tiện lợi

Mô tả:
Đề tài này có thể là một dự án phát triển phần mềm, ứng dụng và phần cứng, với các thành phần chính được tổ chức trong các thư mục khác nhau. Dưới đây là một số thành phần có thể có trong dự án:

1. QR Code:
 Mã nguồn này quét và đọc CODE từ module QRCODE, sau đó gởi vào ESP32 để xử lý dữ liệu và cập nhật thông tin vào giỏ hàng tạm thời lên Firebase Firestore. Nó sử dụng các hàm để lấy dữ liệu từ Firestore và xử lý thông tin sản phẩm, giúp tạo ra một hệ thống quản lý giỏ hàng hiệu quả.

3. ReadNUID:
  Mã nguồn này cho phép ESP32 quét thẻ RFID, cập nhật trạng thái và thanh toán lên Firebase Firestore, và quản lý trạng thái của thẻ. Nó sử dụng các hàm để lấy dữ liệu từ Firestore và xử lý thông tin thẻ, giúp tạo ra một hệ thống quản lý thẻ hiệu quả.

4. Vison1:
   Thư mục chứa mã nguồn cho một ứng dụng hoặc một module liên quan đến thị giác máy tính (computer vision), có thể sử dụng để nhận diện hình ảnh từ video của esp32 camera.

5. Camera:
  Mã nguồn này cho phép ESP32 khởi động một camera HTTP và cung cấp giao diện web để người dùng có thể xem video từ camera. Nó sử dụng các hàm để cấu hình Wi-Fi và camera, tạo ra một hệ thống dễ dàng để truy cập video từ xa.

6. QuickCart:
  Ứng dụng quickCart là một nền tảng thương mại điện tử cho phép người dùng dễ dàng quản lý và mua sắm sản phẩm. Ứng dụng cung cấp các chức năng chính như:
    1. Xác thực Người dùng: Cho phép người dùng đăng ký, đăng nhập và quản lý tài khoản cá nhân thông qua các màn hình.
    2. Quản lý Giỏ hàng: Người dùng xem danh sách sản phẩm.
    3. Quét Mã QR: Ứng dụng hỗ trợ quét mã QR để thanh toán hóa đơn và đăng nhập tài khoản người dùng, giúp tiết kiệm thời gian cho người dùng.
    4. Lịch sử Mua sắm: Người dùng có thể xem lịch sử giao dịch và các đơn hàng đã thực hiện.
    5. Cá nhân hóa: Ứng dụng quản lý hồ sơ.
    6. Cài đặt: Người dùng có thể điều chỉnh các cài đặt ứng dụng.
       
7. UI:
  Thư mục này có thể chứa mã nguồn cho giao diện người dùng (UI), bao gồm các thành phần giao diện và trải nghiệm người dùng. Sử dụng Waveshara ESP32S3 LCD 4.3IN.

Mục tiêu
   Mục tiêu của đề tài là phát triển một ứng dụng tích hợp nhiều chức năng, bao gồm quét mã QR, xử lý hình ảnh, quản lý giỏ hàng, và cung cấp giao diện người dùng thân thiện. Dự án không chỉ tập trung vào phần mềm mà còn tích hợp phần cứng, như camera ESP32, để thu thập và xử lý dữ liệu hình ảnh, kết hợp module qrcode để đọc mã vạch quét được để xử lý dữ liệu giỏ hàng tạm thời. Điều này nhằm cải thiện trải nghiệm người dùng trong lĩnh vực thương mại điện tử hoặc ứng dụng di động, đồng thời tạo ra một hệ thống tự động hóa hiệu quả cho việc nhận diện sản phẩm và quản lý thông tin kết hợp sử dụng AI để phân tích hình ảnh và chống gian lận trong việc mua sắm.
