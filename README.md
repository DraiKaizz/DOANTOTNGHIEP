**Project Title**: Design of a Convenient Supermarket Shopping Cart

**Description** 
This project combines software development, application design, and hardware integration. The key components are organized into various directories, as described below:

**1 QR Code**: 
This module contains the source code for scanning and reading codes from the QR code module, sending data to the ESP32 for processing, and updating the shopping cart information to Firebase Firestore. It includes functions to retrieve data from Firestore and process product information, creating an efficient cart management system.

**2 ReadNUID**: 
This code enables the ESP32 to scan RFID cards, update their status, and manage payment records on Firebase Firestore. It incorporates functions to fetch and process card information, facilitating an effective card management system.

**3 Vison1**:
This directory contains the source code for an application or module related to computer vision, potentially used for recognizing images or videos from the ESP32 camera.

**4 Camera**: 
This module allows the ESP32 to launch an HTTP camera, providing a web interface for users to view video streams. It uses functions to configure Wi-Fi and the camera, creating an accessible remote video streaming system.

**5 QuickCart**: 
The QuickCart application serves as an e-commerce platform, enabling users to efficiently manage and purchase products. The app offers key functionalities such as:

 - User Authentication: Allows users to register, log in, and manage personal accounts through intuitive interfaces.
 - Cart Management: Enables users to view product lists and manage their cart.
 - QR Code Scanning: Facilitates QR code scanning for bill payments and user login, saving time.
 - Shopping History: Users can view transaction history and past orders.
 - Personalization: Manages user profiles for a tailored experience.
 - Settings: Allows users to adjust application preferences.
This component leverages the Waveshare ESP32-S3 4.3-inch LCD for its user interface (UI).

**6 UI**: 
This directory contains source code for the user interface, including UI components and elements for enhancing user experience.

**Key Interfaces in the Mobile Application**:

<img src="https://github.com/user-attachments/assets/30f4c2f7-0e29-41db-bae7-95991300cab4" alt="ALI GIF" width="350">
