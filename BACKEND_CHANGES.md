# Backend & Integration Changes Documentation

## Overview
This document details the architectural updates made to implement Role-Based Access Control (RBAC), Automated User Provisioning, and Admin Data Export capabilities. These changes bridge the Flutter frontend with Firebase Backend services (Auth, Firestore, Cloud Functions).

## 1. Cloud Functions Architecture
**Location:** `/functions/index.js`
**Runtime:** Node.js 22
**Key Dependencies:** `firebase-admin`, `firebase-functions`, `csv-stringify`

### A. `exportEnrollmentsToCsv` (Gen 2)
*   **Type:** HTTPS Callable Function (v2).
*   **Trigger:** Client-side call via `FirebaseFunctions.instance.httpsCallable('exportEnrollmentsToCsv')`.
*   **Logic:**
    1.  **Security:** Verifies authentication and enforces `role === 'admin'` check using custom claims.
    2.  **Data Aggregation:** Queries the `enrollments` collection. For each enrollment, fetches related data from `users` (Student Name/Email) and `courses` (Course Name) collections.
    3.  **CSV Generation:** Uses `csv-stringify` to format the aggregated data.
    4.  **Storage:** Uploads the generated CSV to Firebase Storage under the `admin_exports/` path.
    5.  **Delivery:** Generates a signed URL (valid for 15 minutes) and returns it to the client.

### B. `addDefaultUserRole` (Gen 1)
*   **Type:** Authentication Trigger (v1).
*   **Trigger:** `functions.auth.user().onCreate`.
*   **Logic:**
    1.  **Custom Claims:** Immediately assigns `{ role: 'student' }` custom claim to the newly created user.
    2.  **Firestore Provisioning:** Checks for an existing user document in Firestore (`users/{uid}`). If missing, creates one with default fields (`full_name`, `email`, `role: 'student'`, `createdAt`).
*   **Note:** Gen 1 syntax was retained for this specific trigger due to environment specific CLI constraints, while Gen 2 was used for the HTTPS function.

## 2. Flutter Client-Side Integration

### A. Authentication Service (`lib/services/auth_service.dart`)
*   **Purpose:** Encapsulates all Firebase Auth interactions.
*   **Features:**
    *   `signInWithEmailAndPassword`: Standard login.
    *   `createUserWithEmailAndPassword`: Registration flow. Includes a client-side failsafe to create the Firestore user document immediately.
    *   `signInWithGoogle`: Google Sign-In flow. Also triggers Firestore document creation.
    *   `getUserRole`: Force-refreshes the ID Token (`getIdTokenResult(true)`) to retrieve the latest custom claims.

### B. Role-Based Routing (`lib/features/auth/widgets/role_check_wrapper.dart`)
*   **Logic:**
    *   Listens to `authStateChanges`.
    *   If unauthenticated -> `LoginScreen`.
    *   If authenticated -> Fetches Custom Claims via `AuthService`.
    *   Routes to `AdminDashboardScreen`, `InstructorDashboardScreen`, or `StudentDashboardScreen` based on the `role` claim.

### C. Admin Reporting (`lib/features/admin/screens/admin_reports_screen.dart`)
*   **UI:** Dedicated screen for admin tools.
*   **Action:** "Export Enrollment Data (CSV)" button.
*   **Implementation:** Calls `exportEnrollmentsToCsv` cloud function, parses the result for `downloadUrl`, and launches the URL using `url_launcher`.

## 3. Configuration Updates
*   **`pubspec.yaml`**: Added `google_sign_in`, `font_awesome_flutter`, `cloud_functions`, `url_launcher`.
*   **`firebase.json`**: Configured to deploy `functions` source and mapped Flutter Android/Web apps.
*   **`functions/package.json`**: Configured for Node.js 22 and dependencies.

## 4. Reconciliation Notes for Backend AI
*   **Source of Truth:** The `functions/index.js` file now serves as the primary logic for User Role Assignment (backend-side) and Data Export.
*   **RBAC:** Security rules in Firestore and Storage should rely on `request.auth.token.role`.
*   **Data Consistency:** The system ensures a 1:1 mapping between an Auth User and a Firestore `users` document.
