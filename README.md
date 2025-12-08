Harvest Institute Mobile App 🎓

A hybrid Learning Management System (LMS) mobile application built with Flutter. This app bridges the gap between academic learning (powered by Moodle) and administrative operations (powered by Firebase), specifically tailored for the Harvest Institute with Mobile Money integration.

📱 Features
For Students
Secure Login: Direct authentication via Moodle credentials.

My Courses: View enrolled courses and completion progress (0-100%).

Academic Data: Access grades, view assignments, and submit work (via external links).

QR Attendance: Register class attendance by scanning dynamic QR codes.

Tuition Payments: Integrated Flutterwave gateway supporting MTN Mobile Money, Airtel Money, and Bank Cards (UGX).

For Instructors
Course Insights: View total enrolled students per course.

Attendance Logs: Real-time view of student attendance records filtered by date.

Assignment Tracking: View submission counts and status.

🏗 Architecture
This project uses a Hybrid Backend Architecture:

Moodle LMS (The "Brain"):

Source of Truth for: Users, Courses, Enrollments, Grades, and Assignments.

Communication: REST API (Token-based Auth).

Firebase Firestore (The "Ledger"):

Source of Truth for: Attendance Logs and Payment Receipts.

Reason: Faster read/write for real-time mobile features that Moodle plugins don't handle natively.

🛠 Tech Stack
Framework: Flutter (Dart)

State Management: Riverpod (flutter_riverpod)

Networking: Dio (HTTP client for Moodle API)

Database: Cloud Firestore

Payments: Flutterwave Standard SDK (flutterwave_standard)

Scanner: Mobile Scanner (mobile_scanner)

Storage: Flutter Secure Storage (For keeping tokens safe)

🚀 Getting Started
Prerequisites
Flutter SDK (3.x or higher)

Android Studio / VS Code

A Moodle Instance (v3.9+) with Web Services enabled.

A Firebase Project.
