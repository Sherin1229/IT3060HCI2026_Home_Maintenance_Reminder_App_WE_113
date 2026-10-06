# HomiQ – Home Maintenance Application

HomiQ is a mobile application developed to help users manage household appliances, warranties, maintenance records, reminders, and related documents in one place.

## Technologies Used

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Cloudinary
- Provider
- go_router
- SharedPreferences

## Prerequisites

Before running the application, make sure the following are installed:

- Flutter SDK
- Dart SDK
- Android Studio or Visual Studio Code
- Android SDK
- Android Emulator or a physical Android device

## Setup and Run Instructions

### 1. Clone the Repository

Open a terminal and run:

```bash
git clone https://github.com/Sherin1229/IT3060HCI2026_Home_Maintenance_Reminder_App_WE_113.git
```

Move into the project folder:

```bash
cd homiq
```

### 2. Install Dependencies

Install the required Flutter packages:

```bash
flutter pub get
```

### 3. Check Flutter Setup

Check that Flutter and the required development tools are configured correctly:

```bash
flutter doctor
```

Resolve any required setup issues shown by Flutter Doctor before continuing.

### 4. Connect a Device

Start an Android emulator or connect a physical Android device with USB debugging enabled.

Check the available devices:

```bash
flutter devices
```

### 5. Run the Application

Run the application using:

```bash
flutter run
```

The HomiQ application will launch on the selected Android emulator or connected physical device.

## Backend Services

HomiQ uses the following services:

- Firebase Authentication for user registration, login, and authentication.
- Cloud Firestore for storing application data.
- Cloudinary for storing uploaded images and warranty documents.
- SharedPreferences for storing local theme preferences.

## Main Features

- User registration and login
- Appliance management
- Warranty and document management
- Maintenance record and history management
- Reminder management
- In-app notifications
- User profile management
- Light, Dark, and System theme support

## Academic Project

HomiQ was developed as part of the IT3060 Human Computer Interaction module at SLIIT.
