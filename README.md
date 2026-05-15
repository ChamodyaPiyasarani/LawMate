# LawMate ⚖️

LawMate is a comprehensive legal management application designed to bridge the gap between legal professionals and clients. It provides a secure, efficient, and accessible platform for managing legal cases, documents, and communications.

## 🚀 Key Features

### 👨‍💼 For Lawyers
- **Case Management**: Organize and track legal cases, deadlines, and status updates.
- **Analytics Dashboard**: Gain insights into case loads, client engagement, and document statuses.
- **Document Hub**: Upload legal advisories and manage client documents with ease.
- **Secure Communication**: Communicate with clients through an encrypted messaging system.

### 👥 For Clients
- **Case Tracking**: Stay informed about the progress of your legal matters in real-time.
- **Document Access**: Securely view and download important legal documents.
- **Notification System**: Receive instant updates on case developments and appointments.
- **Profile Management**: Maintain and update personal information and legal preferences.

### 🛡️ Security & Privacy
- **Biometric Authentication**: Secure access using FaceID or TouchID.
- **Encrypted Messaging**: End-to-end encryption for sensitive legal communications.
- **Keychain Integration**: Secure storage for sensitive user credentials.

### 🛠️ Advanced Technologies
- **Live Text**: Extract text from legal documents and images using advanced OCR capabilities.
- **Calendar Integration**: Sync legal deadlines and appointments directly with Apple Calendar.
- **Real-time Data**: Powered by Firebase Firestore for seamless multi-device synchronization.
- **Offline Support**: Core Data implementation ensures data accessibility even without an internet connection.
- **Accessibility**: Full support for VoiceOver and dynamic font sizes, ensuring an inclusive experience for all users.

## 💻 Technical Stack

- **Framework**: SwiftUI (100% Declarative UI)
- **Backend**: Firebase (Authentication, Firestore, Cloud Storage)
- **Persistence**: Core Data & Keychain
- **Native Frameworks**:
  - `MapKit` for location-based services.
  - `EventKit` for calendar and reminder integration.
  - `LocalAuthentication` for biometric security.
  - `VisionKit` for Live Text integration.
  - `UserNotifications` for real-time push alerts.

## 📂 Project Structure

- `LawMate/Views`: SwiftUI views organized by role (Client/Lawyer) and functionality.
- `LawMate/Managers`: Singleton managers for shared state (Auth, Firestore, Notifications, etc.).
- `LawMate/Services`: Logic-focused service layers.
- `LawMate/Models`: Data models for Firebase and Core Data entities.
- `LawMate/Resources`: Assets, fonts, and configuration files.

## 🛠️ Setup & Installation

1. Clone the repository.
2. Open `LawMate.xcodeproj` in Xcode 15+.
3. Ensure you have a valid `GoogleService-Info.plist` in the `LawMate/` directory.
4. Build and run on an iOS Simulator or a physical device (iOS 17.0+ recommended).

