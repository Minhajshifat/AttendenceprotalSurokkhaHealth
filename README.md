SUROKKHA ATTENDANCE PORTAL

Employee Attendance Management System

A location-aware employee attendance management system built with Flutter and Firebase for SUROKKHA HEALTH. The application enables employees and Team Leads to submit attendance, record GPS coordinates and timestamps, monitor team attendance, and manage attendance approvals through an HR/Admin workflow.

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"/>
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase"/>
  <img src="https://img.shields.io/badge/Cloud_Firestore-FF6F00?style=for-the-badge&logo=firebase&logoColor=white" alt="Cloud Firestore"/>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20Web-4CAF50?style=for-the-badge" alt="Android and Web"/>
</p>

⸻

📑 Table of Contents

* Overview
* Project Objectives
* Key Features
* User Roles
* Attendance Workflow
* Technology Stack
* System Architecture
* Project Structure
* Firebase and Database
* Installation and Setup
* Firebase Configuration
* Running the Application
* Attendance Records and Reporting
* Security and Data Integrity
* Testing
* Troubleshooting
* Future Enhancements
* Contributing
* License
* Contact

⸻

📖 Overview

SUROKKHA Attendance Portal is an employee attendance management application developed for SUROKKHA HEALTH to digitize workforce attendance and simplify team-level monitoring.

The system is designed for an organization with office staff, field executives, and Team Leads working across different locations. Employees can sign in, submit attendance, and provide their device location for attendance verification. Attendance submissions can then be reviewed by authorized HR or administrative personnel.

The application uses Flutter for cross-platform development and Firebase for authentication and cloud data storage.

The web version allows employees using iPhones and other supported devices to access the application through a web browser, while Android devices can use the Android application.

Project Information

Item	Details
Project Name	SUROKKHA Attendance Portal
Organization	SUROKKHA HEALTH
Project Type	Employee Attendance Management System
Frontend	Flutter
Programming Language	Dart
Backend Services	Firebase
Database	Cloud Firestore
Supported Platforms	Android and Web
Primary Users	Employees, Team Leads, HR/Admin

⸻

🎯 Project Objectives

* Digitize employee check-in and attendance management.
* Record attendance timestamps and GPS location information.
* Support attendance management for field executives and office employees.
* Allow Team Leads to monitor attendance within their assigned teams.
* Enable HR/Admin to review, approve, or reject attendance submissions.
* Maintain centralized attendance history in the cloud.
* Improve attendance transparency and administrative efficiency.
* Reduce dependence on manual attendance registers and spreadsheets.

⸻

✨ Key Features

1. 🔐 User Authentication

* Firebase Authentication for user sign-in.
* Authenticated access to the attendance application.
* User identification through employee account information.
* Role-based application interfaces for different user types.

2. 📍 Location-Based Attendance

* Employees submit attendance through the application.
* Device GPS coordinates can be captured during attendance submission.
* Attendance timestamps are recorded with the submission.
* Location information can be reviewed by authorized personnel.
* Recorded coordinates can be opened in Google Maps for location inspection.

Location capture depends on device permissions, GPS availability, and network conditions. GPS information should be treated as supporting evidence rather than conclusive proof of physical presence.

3. 🕒 Check-In and Attendance Submission

* Employees sign in and access their attendance dashboard.
* Employees submit their attendance through the check-in workflow.
* The application captures available location and time information.
* Attendance submissions enter the configured review workflow.
* Submission status can be displayed to the employee.

4. 👥 Team Lead Attendance

* Team Leads can submit their own attendance.
* Team Leads can monitor attendance information for their assigned teams.
* Team-level attendance information supports workforce supervision.
* Team Leads can review relevant attendance records through their dashboard.

5. 🧑‍💼 HR/Admin Attendance Approval

* Review submitted attendance records.
* Approve or reject attendance submissions.
* Monitor employee and team attendance.
* Inspect recorded timestamps and location information.
* Maintain oversight of attendance submissions.

Administrative access and approval permissions must be enforced through appropriate authorization controls.

6. 📊 Attendance Dashboard

The dashboard supports attendance monitoring through information such as:

* Employee attendance status.
* Check-in time.
* Team-wise attendance information.
* Pending attendance submissions.
* Approved and rejected attendance records, where available.
* Recorded employee location information.

The exact dashboard metrics depend on the current implementation.

7. 🗂️ Attendance History

* Maintain attendance records in Cloud Firestore.
* Retrieve attendance history for review.
* Support team and employee attendance monitoring.
* Preserve historical attendance information when employee accounts are deactivated, subject to the application’s data-retention rules.

8. 📥 Attendance Reporting

The project includes work on attendance reporting and Excel-based record management.

Reporting requirements include:

* Employee name and ID.
* Designation.
* Check-in and check-out time, where recorded.
* Attendance status.
* Team name.
* Team Lead name.
* Date-wise and monthly attendance summaries.

Automated reports and complete Excel export functionality should be considered available only to the extent implemented in the current codebase.

⸻

👤 User Roles

Role	Responsibilities
Employee / Executive	Sign in, submit attendance, provide location permission, and access permitted attendance information.
Team Lead (TL)	Submit personal attendance and monitor attendance for the assigned team.
HR / Admin	Review attendance submissions, approve or reject records, and monitor employee attendance.
Super Admin	Manage system-wide administration and access permissions, where implemented.

Each role should have access only to the functions and records authorized for that role.

⸻

🔄 Attendance Workflow

The attendance process follows a direct application-based workflow without QR-code scanning.

Employee Attendance Submission

1. The employee opens the SUROKKHA Attendance Portal.
2. The employee signs in using their registered account.
3. The employee opens the attendance dashboard.
4. The employee initiates the attendance check-in process.
5. The application captures the available timestamp and GPS coordinates, subject to device permissions.
6. The attendance submission is saved to the Firebase-backed system.
7. The submission appears as pending review when approval is required.
8. HR/Admin reviews the submitted attendance.
9. HR/Admin approves or rejects the submission.
10. The resulting status is reflected in the attendance records.

Team Lead Workflow

1. The Team Lead signs in to the application.
2. The Team Lead submits their own attendance.
3. The Team Lead views attendance information for the assigned team.
4. The Team Lead monitors relevant attendance submissions.

HR/Admin Workflow

1. HR/Admin signs in using an authorized account.
2. The administrator opens the attendance management dashboard.
3. The administrator reviews pending submissions.
4. The administrator checks available timestamps and location information.
5. The administrator approves or rejects submissions.
6. Attendance records remain available for authorized monitoring and reporting.

⸻

🛠️ Technology Stack

Technology / Package	Purpose
Flutter	Cross-platform user interface
Dart	Application programming language
Firebase Authentication	User authentication
Cloud Firestore	Cloud database
Provider	State management
GoRouter	Navigation and routing
Geolocator	GPS and device location access
Intl	Date and time formatting
Excel	Spreadsheet processing and export
FlutterFire CLI	Firebase configuration for Flutter

⸻

🏗️ System Architecture

The application uses a Flutter client connected to Firebase services.

                 ┌─────────────────────────┐
                 │   SUROKKHA Attendance   │
                 │        Portal            │
                 └────────────┬────────────┘
                              │
                   ┌──────────┴──────────┐
                   │                     │
          ┌────────▼────────┐   ┌────────▼────────┐
          │ Android App     │   │ Flutter Web     │
          │ Employees / TL  │   │ Employees / HR  │
          └────────┬────────┘   └────────┬────────┘
                   │                     │
                   └──────────┬──────────┘
                              │
                   ┌──────────▼──────────┐
                   │ Firebase Services   │
                   ├─────────────────────┤
                   │ Authentication      │
                   │ Cloud Firestore     │
                   └──────────┬──────────┘
                              │
                   ┌──────────▼──────────┐
                   │ Attendance Records  │
                   │ Employee / Team Data│
                   │ Review Status        │
                   └─────────────────────┘

The architecture diagram describes the intended logical flow. Sensitive authorization and attendance-integrity checks must be enforced by Firebase Security Rules and trusted backend logic where required.

⸻

📂 Project Structure

The following is a recommended Flutter project structure. The exact directory and file names should match the actual repository.

surokkha_attendance/
│
├── android/
├── ios/
├── web/
├── windows/
│
├── assets/
│   ├── images/
│   └── icons/
│
├── lib/
│   ├── main.dart
│   ├── firebase_options.dart
│   │
│   ├── models/
│   │   ├── employee_model.dart
│   │   ├── attendance_model.dart
│   │   └── team_model.dart
│   │
│   ├── services/
│   │   ├── attendance_service.dart
│   │   ├── location_service.dart
│   │   └── authentication_service.dart
│   │
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   └── attendance_provider.dart
│   │
│   ├── screens/
│   │   ├── auth/
│   │   ├── employee/
│   │   ├── team_leader/
│   │   ├── admin/
│   │   └── dashboard/
│   │
│   ├── routes/
│   │   └── app_router.dart
│   │
│   ├── widgets/
│   └── utils/
│
├── test/
├── pubspec.yaml
├── pubspec.lock
├── .gitignore
└── README.md

⸻

🔥 Firebase and Database

The application uses Firebase Authentication and Cloud Firestore for authentication and cloud-based attendance data management.

Firebase Authentication

Firebase Authentication manages user sign-in and identity.

Cloud Firestore

Cloud Firestore stores application data, including employee information, team assignments, and attendance records.

The following examples illustrate possible data structures. They are documentation examples, not a guarantee that every field or collection exists in the current database.

Users Collection

{
  "uid": "firebase-auth-user-id",
  "employeeId": "EMP001",
  "name": "Employee Name",
  "email": "employee@example.com",
  "role": "employee",
  "teamId": "TEAM001",
  "isActive": true
}

Attendance Record

{
  "employeeId": "EMP001",
  "teamId": "TEAM001",
  "date": "2026-10-14",
  "checkIn": "Firestore Timestamp",
  "status": "pending",
  "latitude": 23.8103,
  "longitude": 90.4125,
  "locationAccuracy": 15.0
}

The example coordinates are illustrative and must not be interpreted as actual employee location data.

In production, use Firestore Timestamp values for timestamps and validate all fields. Include location information only when permitted and needed.

Teams Collection

{
  "teamId": "TEAM001",
  "teamName": "Sales Team A",
  "teamLeadId": "TL001"
}

Recommended Data Practices

* Use stable document identifiers.
* Associate attendance records with the correct authenticated employee.
* Keep employee identity and authorization information consistent.
* Preserve historical attendance records when accounts are deactivated.
* Restrict attendance approval and modification to authorized users.
* Avoid storing unnecessary personal information.

⸻

💻 Installation and Setup

Prerequisites

Install the following tools:

* Flutter SDK
* Dart SDK compatible with Flutter
* Android Studio or another supported IDE
* Android SDK for Android builds
* Git
* A Firebase project with Authentication and Cloud Firestore configured

Verify your environment:

flutter doctor

Check the installed Flutter version:

flutter --version

Step 1: Clone the Repository

git clone <YOUR_GITHUB_REPOSITORY_URL>
cd surokkha_attendance

Replace the placeholder with the actual repository URL.

Step 2: Install Dependencies

flutter pub get

Step 3: Configure Firebase

Configure the project using the Firebase Console and FlutterFire CLI.

Step 4: Run the Application

For Android:

flutter run

List available devices:

flutter devices

For web:

flutter run -d chrome

The web build requires the web platform to be configured correctly.

⸻

🔧 Firebase Configuration

1. Select the Firebase Project

Open the Firebase Console and select the Firebase project associated with SUROKKHA Attendance.

2. Enable Authentication

Enable the authentication method used by the application. For Email/Password authentication:

1. Open Firebase Authentication.
2. Select Sign-in method.
3. Enable Email/Password.

3. Configure Cloud Firestore

Verify that the intended Firestore database exists and that the application is configured to use the correct Firebase project.

4. Configure FlutterFire

If Firebase configuration needs to be generated or updated, run:

firebase login
dart pub global activate flutterfire_cli
flutterfire configure

Select the correct Firebase project and the platforms used by the application.

5. Initialize Firebase

A typical Firebase initialization in lib/main.dart looks like this:

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

Replace MyApp with the actual root widget if it has a different name.

Do not overwrite a working Firebase configuration without checking the current project setup.

⸻

📱 Building the Application

Build Android APK

flutter build apk --release

The APK is normally generated at:

build/app/outputs/flutter-apk/app-release.apk

Build Flutter Web

flutter build web --release

The generated web files are normally available in:

build/web/

Deploy the web build through the configured hosting service. For production deployment, use HTTPS and restrict access to authorized users and data.

⸻

📊 Attendance Records and Reporting

The attendance system is intended to support centralized recordkeeping and administrative reporting.

Recommended report fields include:

Field	Description
Employee Name	Full employee name
Employee ID	Unique employee identifier
Designation	Employee job title
Date	Attendance date
Check-In Time	Recorded reporting time
Check-Out Time	Recorded checkout time, where available
Attendance Status	Pending, approved, rejected, or other configured statuses
Team Name	Assigned team
Team Lead	Assigned team leader
Location	Recorded coordinates or map link, where permitted

Reports should use consistent date and time formats. Monthly calculations should account for missing attendance events, incomplete records, approved corrections, and the organization’s attendance policy.

⸻

🔐 Security and Data Integrity

Employee attendance records must be protected against unauthorized access and modification.

* Require authentication for protected application functions.
* Apply role-based authorization for employees, Team Leads, and HR/Admin.
* Restrict users to the records they are authorized to access.
* Prevent employees from modifying their own approval status.
* Validate attendance submissions and timestamps.
* Prevent duplicate or invalid attendance submissions where applicable.
* Validate location data without treating GPS coordinates as definitive proof of physical presence.
* Maintain an audit trail for administrative corrections where supported.
* Never publish Firebase service-account credentials or other private secrets in the repository.
* Test Firebase Security Rules before deploying production changes.
* Preserve historical attendance records according to the organization’s retention requirements.

The presence of Firebase Authentication alone does not secure Firestore data. Proper Security Rules and trusted validation logic are also required.

⸻

🧪 Testing

Run static analysis:

flutter analyze

Run automated tests:

flutter test

Important scenarios to test include:

* Successful and unsuccessful authentication.
* Employee and Team Lead attendance submission.
* Location permission granted or denied.
* Missing or inaccurate GPS readings.
* Attendance approval and rejection.
* Unauthorized access to other employees’ records.
* Duplicate submissions.
* Network interruptions during attendance submission.
* Historical records for deactivated employees.
* Attendance reporting accuracy.

⸻

🛣️ Future Enhancements

Potential improvements include:

* [ ]	Complete HR/Admin and Super Admin management workflows.
* [ ]	Enhanced role-based security and Firestore Security Rules.
* [ ]	Advanced monthly Excel reporting.
* [ ]	Attendance correction requests and audit logs.
* [ ]	Automated attendance summaries.
* [ ]	Notifications for pending attendance reviews.
* [ ]	Improved GPS verification and location accuracy handling.
* [ ]	Automated backup and recovery procedures.
* [ ]	Expanded automated testing and production monitoring.

These items should be treated as future enhancements only if they are not already implemented.

⸻

🛠️ Troubleshooting

Firebase Initialization Error

Verify the Firebase project configuration and the presence of firebase_options.dart.

flutterfire configure
flutter pub get

Firestore Permission Denied

Check authentication status, user roles, team assignments, and Firestore Security Rules. Do not resolve permission errors by allowing unrestricted public access.

Location Not Available

Check device location settings, runtime permissions, GPS availability, and network connectivity.

Dependency Issues

Try:

flutter clean
flutter pub get

Web Application Issues

Verify Firebase web configuration, supported package versions, browser permissions, and HTTPS deployment settings.

⸻

🤝 Contributing

Contributions and bug reports should follow the project’s development and review process.

1. Fork or clone the repository with appropriate permission.
2. Create a separate feature branch.
3. Implement the changes.
4. Run static analysis and tests.
5. Submit a pull request with a clear description of the changes.

Example branch names:

feature/attendance-history
feature/excel-reporting
fix/location-validation

⸻

📄 License

This project is developed for SUROKKHA HEALTH.

The applicable license and redistribution permissions should be determined by the project owner. Do not redistribute proprietary source code or company data without authorization.

⸻

📞 Contact

Project: SUROKKHA Attendance Portal
Organization: SUROKKHA HEALTH
Technology: Flutter, Dart, Firebase
Purpose: Employee Attendance and Workforce Management

For project-related inquiries, contact the authorized project administrator or SUROKKHA HEALTH technical team.

⸻

<p align="center">
  <strong>SUROKKHA ATTENDANCE PORTAL</strong><br/>
  Simplifying Employee Attendance and Workforce Management
</p>
