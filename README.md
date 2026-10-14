🏢 SUROKKHA WORKFORCE

Smart Employee Attendance Management System

A modern, location-aware employee attendance management system built with Flutter and Firebase to simplify employee check-in/check-out, QR-based attendance verification, team management, and HR reporting.

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-Framework-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-Language-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"/>
  <img src="https://img.shields.io/badge/Firebase-Backend-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase"/>
  <img src="https://img.shields.io/badge/Cloud-Firestore-FF6F00?style=for-the-badge&logo=firebase&logoColor=white" alt="Cloud Firestore"/>
</p>

⸻

📌 Table of Contents

* Overview
* Project Objectives
* Key Features
* User Roles
* Technology Stack
* System Architecture
* Attendance Workflow
* Project Structure
* Database Design
* Prerequisites
* Installation and Setup
* Firebase Configuration
* Running the Application
* Attendance Reports and Excel Export
* Security Considerations
* Future Enhancements
* Troubleshooting
* Contributing
* License
* Contact

⸻

📖 Overview

SUROKKHA WORKFORCE is an employee attendance management portal designed for organizations with multiple teams, team leaders, field executives, and HR administrators.

The system aims to replace manual attendance registers and spreadsheets with a centralized digital platform.

Team leaders can generate time-limited QR codes for attendance verification. Employees can scan valid QR codes to check in or check out, subject to configured attendance rules. Location information can be recorded to support field attendance verification.

The application uses Firebase Authentication for user authentication and Cloud Firestore for cloud-based data storage.

The system is designed for organizations managing approximately 11–50 employees, with the flexibility to support larger teams as the application evolves.

🎯 Primary Use Cases

* Daily employee attendance management.
* Field employee attendance tracking.
* Team-based attendance supervision.
* QR-based check-in and check-out.
* HR attendance monitoring and approval.
* Monthly attendance reporting and Excel exports.

⸻

🎯 Project Objectives

1. Digitize employee attendance and reduce manual recordkeeping.
2. Enable team leaders to manage attendance for their assigned teams.
3. Introduce QR-based attendance verification.
4. Record attendance timestamps and, where permitted, location information.
5. Provide HR and management with centralized attendance records.
6. Simplify monthly attendance calculations and reporting.
7. Improve transparency, accountability, and operational efficiency.

⸻

✨ Key Features

1. 🔐 Authentication and Access Control

* Firebase Email/Password authentication.
* Secure sign-in and sign-out.
* Role-based access for employees, team leaders, and HR administrators.
* User profile and employee identification.
* Access restrictions based on user roles.


2. 📍 Location-Aware Attendance

* Capture the employee’s device location when submitting attendance, subject to permission.
* Store latitude and longitude with attendance records when enabled.
* Record location accuracy when available.
* Support field-team attendance verification.
* Allow authorized HR personnel to review recorded attendance information.

Note: GPS coordinates alone do not guarantee that an employee is physically present at a claimed location. Additional verification and server-side validation may be required.

3. 👥 Employee and Team Management

* Maintain employee profiles and employee IDs.
* Organize employees into teams and departments.
* Assign team leaders.
* Associate attendance sessions with the appropriate teams.
* Manage employee account status and role permissions.

4. 📊 Attendance Dashboard

The dashboard is intended to provide an overview of:

* Total employees.
* Present employees.
* Absent employees.
* Late arrivals.
* Check-in and check-out times.
* Team-wise attendance.
* Daily and monthly attendance summaries.

Dashboard figures depend on the attendance records and calculation rules configured in the application.

5. 🗓️ Attendance History

* View daily attendance records.
* Filter records by date, employee, or team.
* Review check-in and check-out timestamps.
* Identify incomplete attendance records.
* Maintain historical attendance data for reporting.

6. 📥 Excel Attendance Reports

* Export attendance records to Excel.
* Generate date-wise and employee-wise reports.
* Support monthly attendance summaries.
* Include employee ID, name, designation, reporting time, checkout time, attendance status, and team leader where available.
* Preserve historical attendance records for administrative reference.

Excel export availability depends on the implementation of the reporting module.

7. 🧑‍💼 HR and Management Controls

* Review attendance records.
* Monitor team attendance.
* Handle attendance correction requests where supported.
* Review exceptional or incomplete records.
* Maintain centralized reporting for management.

8. ☁️ Cloud-Based Data Management

* Firebase Authentication for identity management.
* Cloud Firestore for application data.
* Shared backend for supported Android and web clients.
* Cloud-hosted data accessible to authorized users.

⸻

👤 User Roles

Role	Responsibilities
Employee / Executive	Sign in, scan attendance QR codes, submit check-in/check-out, and view permitted personal attendance records.
Team Leader (TL)	Manage assigned team attendance sessions, generate QR codes, and monitor team attendance.
HR Administrator	Manage employee records, review attendance, and access authorized reports.
Management	Review organization-wide attendance summaries and management reports.

Role permissions must be enforced by the application and Firebase Security Rules, not merely by hiding buttons in the user interface.

⸻

🛠️ Technology Stack

Technology	Purpose
Flutter	Cross-platform application development
Dart	Application programming language
Firebase Authentication	User authentication
Cloud Firestore	NoSQL cloud database
Provider	State management
GoRouter	Application navigation and routing
Geolocator	Device location access
QR code generation/scanning packages	QR-based attendance
Excel package	Spreadsheet export
Intl	Date and time formatting
UUID	Unique identifiers where needed
Fluttertoast	User feedback messages

Additional packages may be required depending on the implemented QR generation, scanning, and reporting features.

⸻

🏗️ System Architecture

The application follows a Flutter client and Firebase backend architecture.

                 ┌───────────────────────┐
                 │   Flutter Application │
                 │   Android / Web       │
                 └───────────┬───────────┘
                             │
                ┌────────────┴────────────┐
                │                         │
       ┌────────▼────────┐      ┌─────────▼────────┐
       │ Firebase Auth   │      │ Application UI   │
       │ User Identity   │      │ Provider/GoRouter│
       └─────────────────┘      └─────────┬────────┘
                                          │
                               ┌──────────▼──────────┐
                               │ Attendance Services │
                               │ QR / Location / Data│
                               └──────────┬──────────┘
                                          │
                               ┌──────────▼──────────┐
                               │   Cloud Firestore   │
                               │ Employees / Teams / │
                               │ Attendance / Config │
                               └─────────────────────┘

Important: Sensitive attendance operations, QR validation, and permission checks should be enforced through trusted backend logic or appropriately secured Firestore operations. A client-side diagram does not imply that a separate backend service has already been implemented.

⸻

🔄 Attendance Workflow

Employee Check-In

1. The employee signs in to the application.
2. The team leader generates an attendance QR code for an authorized session.
3. The employee scans the QR code.
4. The application validates the session and its validity period.
5. The application requests location permission if location verification is enabled.
6. The attendance submission is validated against the employee’s identity and attendance rules.
7. The check-in timestamp and permitted location information are recorded.
8. The attendance status is displayed to the employee and authorized administrators.

Employee Check-Out

1. The employee scans the appropriate valid QR code or follows the configured checkout process.
2. The system verifies the employee’s existing attendance record.
3. The checkout timestamp is recorded.
4. Working hours are calculated according to the configured rules.
5. The updated record becomes available to authorized reporting users.

HR Review

1. HR opens the attendance dashboard.
2. Attendance is filtered by date, team, or employee.
3. Exceptional or incomplete records are reviewed.
4. Corrections or approvals are handled through the available administrative workflow.
5. Reports are exported when required.

⸻

📂 Project Structure

The following is a recommended structure. Adjust the names to match the actual files in your repository.

surokkha_workforce/
│
├── android/
├── ios/
├── web/
├── windows/
│
├── assets/
│   ├── images/
│   ├── icons/
│   └── fonts/
│
├── lib/
│   ├── main.dart
│   ├── firebase_options.dart
│   │
│   ├── models/
│   │   ├── employee_model.dart
│   │   ├── team_model.dart
│   │   └── attendance_model.dart
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
│   │   ├── hr/
│   │   └── dashboard/
│   │
│   ├── routes/
│   │   └── app_router.dart
│   │
│   ├── widgets/
│   │
│   └── utils/
│
├── test/
├── .gitignore
├── pubspec.yaml
├── pubspec.lock
└── README.md

⸻

🗄️ Database Design

Cloud Firestore is used as the primary database.

The following collections represent a recommended logical data model. Actual collection names and fields may differ according to the implementation.

1. users

Stores account information and access roles.

{
  "uid": "firebase-auth-user-id",
  "employeeId": "EMP001",
  "name": "Employee Name",
  "email": "employee@example.com",
  "role": "employee",
  "teamId": "TEAM001",
  "isActive": true
}

2. employees

Stores employee profile information.

{
  "employeeId": "EMP001",
  "name": "Employee Name",
  "designation": "Executive",
  "teamId": "TEAM001",
  "teamLeadId": "TL001",
  "isActive": true
}

3. teams

Stores team information and team leader assignments.

{
  "teamId": "TEAM001",
  "teamName": "Sales Team A",
  "teamLeadId": "TL001",
  "isActive": true
}

4. attendance

Stores daily attendance records.

{
  "employeeId": "EMP001",
  "teamId": "TEAM001",
  "date": "2026-10-14",
  "checkIn": "Firestore Timestamp",
  "checkOut": null,
  "status": "present",
  "isLate": false,
  "workingHours": null,
  "latitude": 23.8103,
  "longitude": 90.4125,
  "locationAccuracy": 15.0
}

The example coordinates are illustrative only. Use actual location data only with appropriate permission.

In a production implementation, store timestamps using Firestore Timestamp values rather than the descriptive placeholder above. Store location fields only when enabled and authorized.

5. attendance_sessions

Recommended collection for QR attendance sessions.

{
  "sessionId": "SESSION001",
  "teamId": "TEAM001",
  "createdBy": "team-leader-user-id",
  "sessionType": "check_in",
  "createdAt": "Firestore Timestamp",
  "expiresAt": "Firestore Timestamp",
  "isActive": true
}

A production QR code should use a validated session identifier or securely generated token. Do not rely on an employee-editable QR payload as proof of valid attendance.

6. departments

Stores department information.

7. leave_requests

Stores leave requests and approval status, if leave management is implemented.

8. settings

Stores configurable attendance rules, working hours, grace periods, and other system settings where appropriate.

Database design note: Use stable document IDs, validate all client-submitted fields, enforce role-based Firestore Security Rules, and prevent employees from modifying their own attendance timestamps or approval status without authorization.

⸻

💻 Prerequisites

Before running the project, install:

* Flutter SDK
* Dart SDK compatible with the installed Flutter version
* Android Studio or another supported development environment
* Android SDK for Android development
* Visual Studio with the required C++ workload if building a Windows desktop application
* Git
* A Firebase project with the required services enabled

Check your Flutter environment:

flutter doctor

Check the installed Flutter version:

flutter --version

⸻

🚀 Installation and Setup

Step 1: Clone the Repository

git clone <YOUR_GITHUB_REPOSITORY_URL>
cd surokkha_workforce

Replace <YOUR_GITHUB_REPOSITORY_URL> with your actual repository URL.

Step 2: Install Dependencies

flutter pub get

Step 3: Configure Firebase

Configure the Firebase project as described in the Firebase Configuration section below.

Step 4: Verify the Configuration

flutter doctor
flutter pub get

Step 5: Run the Application

Connect an Android device or start an emulator, then run:

flutter run

To list available devices:

flutter devices

Step 6: Run the Web Application

If the web target is configured:

flutter run -d chrome

Step 7: Build the Android APK

flutter build apk --release

The generated APK is normally available at:

build/app/outputs/flutter-apk/app-release.apk

Step 8: Build for the Web

flutter build web --release

The generated web files are normally available in:

build/web/

⸻

🔥 Firebase Configuration

1. Create or Select a Firebase Project

Open the Firebase Console and select the Firebase project associated with the application.

2. Enable Authentication

1. Open Authentication.
2. Select Sign-in method.
3. Enable Email/Password authentication.

3. Create the Firestore Database

1. Open Firestore Database.
2. Create or select the database.
3. Configure the database for the intended environment.
4. Apply restrictive Firestore Security Rules before production use.

4. Configure FlutterFire

Install the Firebase CLI and FlutterFire CLI if they are not already installed.

firebase login
dart pub global activate flutterfire_cli

From the project directory, run:

flutterfire configure

Select the correct Firebase project and register the required platforms.

This command generates or updates lib/firebase_options.dart for the selected configuration.

5. Initialize Firebase

Initialize Firebase in main.dart before using Firebase services. A typical setup is:

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

Replace MyApp with the actual root widget in your application.

6. Firebase Security

* Use Firebase Authentication to identify users.
* Apply Firestore Security Rules that validate user identity, role, and team membership.
* Restrict employee, team leader, and HR permissions appropriately.
* Do not expose service-account private keys or privileged credentials in the Flutter application.
* Never deploy production data with unrestricted Firestore read/write rules.
* Validate sensitive attendance operations on a trusted backend where necessary.

⸻

📊 Attendance Reports and Excel Export

The attendance reporting module is intended to support monthly and date-wise reporting.

Recommended report columns:

Column	Description
Employee Name	Full employee name
Employee ID	Unique employee identifier
Designation	Employee designation
Reporting Time	Check-in timestamp
Check-Out Time	Check-out timestamp
Attendance Status	Present, absent, late, or another configured status
Team Name	Assigned team
Team Leader Name	Assigned team leader
Working Hours	Calculated duration when available

Recommended reporting capabilities:

* Daily attendance report.
* Monthly attendance report.
* Team-wise attendance report.
* Employee-wise attendance history.
* Missing check-out report.
* Late arrival report.
* Excel export for administrative use.

Ensure that date filters, working-hour calculations, time zones, and attendance corrections follow consistent business rules.

⸻

🔒 Security Considerations

Employee attendance data is sensitive organizational information. The following safeguards should be implemented before production deployment.

* Authentication: Require authorized sign-in.
* Authorization: Enforce role-based access control.
* QR validation: Validate session authenticity, expiration, team membership, and permitted attendance actions.
* Replay protection: Prevent repeated use of the same attendance session or duplicate check-in requests where applicable.
* Location privacy: Request location access only when needed and explain its purpose.
* Data integrity: Prevent unauthorized edits to check-in/check-out times and attendance status.
* Auditability: Record authorized administrative corrections and relevant changes.
* Employee deactivation: Preserve historical attendance records when an employee account is deactivated.
* Data protection: Avoid exposing personal information in application logs or public repositories.
* Production rules: Test Firestore Security Rules using the Firebase Emulator Suite or an equivalent controlled test process.

A QR code and a GPS coordinate should not be treated as complete proof of identity or physical presence. Stronger verification may be needed depending on organizational requirements.

⸻

🛣️ Future Enhancements

Potential future improvements include:

* [ ]	Dedicated HR web dashboard.
* [ ]	Advanced employee and team management.
* [ ]	Configurable attendance schedules and grace periods.
* [ ]	Secure, expiring QR attendance sessions.
* [ ]	Server-side attendance validation.
* [ ]	Enhanced location verification.
* [ ]	Attendance correction and approval workflows.
* [ ]	Leave management.
* [ ]	Automated monthly Excel reports.
* [ ]	Notifications for missing check-out and attendance exceptions.
* [ ]	Audit logs for administrative actions.
* [ ]	Employee attendance analytics.
* [ ]	Automated backup and recovery procedures.
* [ ]	Comprehensive unit, integration, and security tests.

⸻

🧪 Testing

Run Flutter static analysis:

flutter analyze

Run automated tests:

flutter test

Before release, test the following scenarios:

* Valid and invalid login attempts.
* Employee, team leader, and HR access permissions.
* Expired and invalid QR sessions.
* Duplicate check-in attempts.
* Missing checkout records.
* Denied location permission.
* Network interruptions during attendance submission.
* Incorrect or unauthorized team assignments.
* Excel export accuracy.
* Employee deactivation and historical record preservation.

⸻

🛠️ Troubleshooting

Firebase initialization error

Check that Firebase is configured for the selected platform and that firebase_options.dart exists and matches the intended project.

flutterfire configure
flutter pub get

Dependency errors

Try:

flutter clean
flutter pub get

Location permission errors

Check Android and iOS permission declarations, device settings, and runtime permission handling.

QR scanner errors

Verify camera permissions, supported platform configuration, and the QR scanning package setup.

Firestore permission errors

Review Firebase Authentication status, document ownership, team assignments, and Firestore Security Rules. Do not solve permission errors by making the database publicly writable.

Web build errors

Confirm that the required web packages are compatible and that Firebase is configured for the web application.

⸻

🤝 Contributing

Contributions, bug reports, and suggestions are welcome.

1. Fork the repository.
2. Create a feature branch.
3. Implement and test your changes.
4. Run flutter analyze and flutter test.
5. Submit a pull request describing the changes.

Suggested branch naming:

feature/qr-attendance
feature/excel-export
fix/attendance-validation

⸻

📄 License

This project is developed for employee attendance management at SUROKKHA HEALTH.

The applicable license and redistribution permissions should be defined by the project owner before the source code is publicly distributed.

⸻

📞 Contact

Project: SUROKKHA WORKFORCE — Attendance Portal
Organization: SUROKKHA HEALTH
Technology: Flutter, Dart, Firebase
Purpose: Employee Attendance and Workforce Management

For project-related inquiries, contact the project administrator or the authorized SUROKKHA HEALTH technical team.

⸻

<p align="center">
  <strong>Built to make workforce attendance simpler, smarter, and more transparent.</strong>
</p>
