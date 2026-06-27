# 📱 QR-Based Attendance Management System

A modern **QR-Based Attendance Management System** built for **Tuition Classes, Coaching Institutes, and Educational Organizations**. The application simplifies attendance tracking using unique QR Codes and automatically notifies parents via WhatsApp after attendance is submitted.

---

## 📖 Project Overview

The QR-Based Attendance Management System is a mobile application with a secure Spring Boot backend that enables teachers to record attendance by scanning students' QR codes.

Each student receives a unique QR Code during registration. Teachers simply scan the QR code, and the system automatically records attendance. Once attendance is submitted, all scanned students are marked **Present**, while students who were not scanned are automatically marked **Absent**.

Parents receive instant WhatsApp notifications informing them about their child's attendance status.

---

## ✨ Key Features

### 🔐 Authentication
- JWT Authentication
- Secure Login
- Role-Based Access Control
- Admin & Teacher Roles

### 👨‍🎓 Student Management
- Add Student
- Update Student
- Delete Student
- Student Profile
- Parent Details
- Student Photo Upload
- QR Code Generation

### 👨‍🏫 Teacher Management
- Teacher Login
- Batch Management
- Attendance History
- Dashboard

### 📚 Batch Management
- Create Batch
- Assign Teacher
- Add Students to Batch
- Batch-wise Reports

### 📷 QR-Based Attendance
- Unique QR Code for Every Student
- QR Scanner
- Duplicate Scan Prevention
- Instant Attendance Recording

### 📅 Attendance Management
- Mark Present via QR Scan
- Automatic Absent Marking
- Attendance History
- Attendance Percentage

### 📢 WhatsApp Notifications
- Present Notification
- Absent Notification
- Attendance Alerts
- Parent Communication

### 📊 Reports
- Daily Report
- Weekly Report
- Monthly Report
- Student-wise Report
- Batch-wise Report
- Attendance Percentage

### 📄 Export
- Excel Export
- PDF Export

---

# 🔄 Attendance Workflow

```
Admin Registers Student
          │
          ▼
QR Code Generated
          │
          ▼
Teacher Login
          │
          ▼
Select Batch
          │
          ▼
Scan Student QR
          │
          ▼
Student Verified
          │
          ▼
Attendance Marked Present
          │
          ▼
Repeat Until All Present Students Are Scanned
          │
          ▼
Submit Attendance
          │
          ▼
Remaining Students Automatically Marked Absent
          │
          ▼
WhatsApp Notifications Sent
          │
          ▼
Attendance Reports Generated
```

---

# 🏗️ System Architecture

```
Flutter Mobile App
        │
        ▼
Spring Boot REST API
        │
        ▼
MySQL Database
        │
 ┌──────┼─────────┐
 │      │         │
 ▼      ▼         ▼
 QR     Reports   Notifications
 Code   Excel     WhatsApp
```

---

# 🛠️ Tech Stack

## Mobile Application
- Flutter
- Dart
- Provider
- Dio
- Mobile Scanner

## Backend
- Java 21
- Spring Boot 3
- Spring Security
- JWT Authentication
- Spring Data JPA
- Maven

## Database
- MySQL

## QR Code
- ZXing Library

## Reports
- Apache POI
- OpenPDF

## Notifications
- WhatsApp Business API

---

# 📂 Project Structure

```
attendance-management-system/

│

├── attendance-backend/

│

├── attendance-mobile/

│

├── database/

│

├── documentation/

│

└── README.md
```

---

# 📦 Backend Structure

```
src/main/java/com/genxcraft/attendance

├── config
├── controller
├── dto
├── entity
├── enums
├── exception
├── repository
├── security
├── service
├── serviceImpl
├── util
└── AttendanceApplication.java
```

---

# 📱 Mobile Structure

```
lib/

├── core
├── models
├── providers
├── repositories
├── routes
├── screens
├── services
├── widgets
└── main.dart
```

---

# 👥 User Roles

## 👑 Admin

- Manage Teachers
- Manage Students
- Create Batches
- Generate QR Codes
- View Reports
- Export Reports
- Dashboard Analytics

---

## 👨‍🏫 Teacher

- Login
- Select Batch
- Scan Student QR
- Submit Attendance
- View Attendance History
- Generate Reports

---

## 👨‍👩‍👧 Parent

- Receive WhatsApp Notifications
- Attendance Updates
- Attendance Alerts

---

# 📋 Modules

- Authentication
- Student Management
- Teacher Management
- Batch Management
- QR Code Management
- Attendance Management
- WhatsApp Notifications
- Reports
- Dashboard
- Settings

---

# 🚀 Future Enhancements

- Parent Mobile App
- Student Mobile App
- Fee Management
- Homework Management
- Online Test Module
- Push Notifications
- Attendance Analytics
- Face Recognition Attendance
- Cloud Backup
- Multi-Institute Support

---

# 📅 Development Roadmap

- ✅ Project Setup
- 🔄 Authentication Module
- ⏳ Student Module
- ⏳ Teacher Module
- ⏳ Batch Module
- ⏳ QR Code Module
- ⏳ Attendance Module
- ⏳ WhatsApp Integration
- ⏳ Reports & Analytics
- ⏳ Flutter UI
- ⏳ Testing & Deployment

---

# 🤝 Contributing

Contributions are welcome!

1. Fork the repository.
2. Create a new feature branch.
3. Commit your changes.
4. Push the branch.
5. Open a Pull Request.

---

# 📜 License

This project is licensed under the MIT License.

---

# 👨‍💻 Developed By

**GenXcraft Solutions**

Building Smart Software Solutions for Education, Businesses, and Startups.
