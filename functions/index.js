const { onCall, HttpsError } = require("firebase-functions/v2/https");
const functionsV1 = require("firebase-functions/v1"); 
const admin = require("firebase-admin");
const { stringify } = require("csv-stringify/sync");

admin.initializeApp();

/**
 * Exports enrollment data to a CSV file and returns a signed download URL.
 * This function MUST be called by an authenticated user (Admin).
 * MIGRATED TO GEN 2
 */
exports.exportEnrollmentsToCsv = onCall({ memory: "256MiB" }, async (request) => {
  // 1. Security Check: Ensure user is authenticated
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  // 2. Security Check: Ensure user is an Admin
  const callerUid = request.auth.uid;
  // Note: In Gen 2 onCall, request.auth.token contains claims directly
  const callerRole = request.auth.token.role;

  if (callerRole !== "admin") {
    throw new HttpsError(
      "permission-denied",
      "Only administrators can export enrollment data."
    );
  }

  try {
    // 3. Fetch Enrollment Data from Firestore
    const enrollmentsSnapshot = await admin.firestore().collection("enrollments").get();

    if (enrollmentsSnapshot.empty) {
      return { message: "No enrollment data found.", downloadUrl: null };
    }

    // 4. Process Data into CSV Format
    const records = [];
    enrollmentsSnapshot.forEach((doc) => {
      const d = doc.data();
      records.push({
        enrollment_id: doc.id,
        user_id: d.user_id || "",
        course_id: d.course_id || "",
        status: d.status || "",
        payment_status: d.payment_status || "",
        enrol_date: d.enrol_date ? d.enrol_date.toDate().toISOString() : "",
      });
    });

    const csvData = stringify(records, {
      header: true,
      columns: [
        "enrollment_id",
        "user_id",
        "course_id",
        "status",
        "payment_status",
        "enrol_date",
      ],
    });

    // 5. Save CSV to Firebase Storage
    const bucket = admin.storage().bucket();
    const fileName = `exports/enrollments_${new Date().toISOString()}.csv`;
    const file = bucket.file(fileName);

    await file.save(csvData, {
      contentType: "text/csv",
      metadata: {
        metadata: {
          firebaseStorageDownloadTokens: Date.now().toString(),
        },
      },
    });

    // 6. Generate a Signed URL for the Client to Download
    const [downloadUrl] = await file.getSignedUrl({
      action: "read",
      expires: Date.now() + 15 * 60 * 1000, // 15 minutes
    });

    return { downloadUrl };
  } catch (error) {
    console.error("Error exporting enrollments:", error);
    throw new HttpsError("internal", "Unable to export enrollments.");
  }
});

/**
 * Triggered when a new user account is created in Firebase Authentication.
 * Sets a default 'student' role custom claim and creates a corresponding
 * user document in Firestore.
 * KEEPING AS V1 for simplicity
 */
exports.addDefaultUserRole = functionsV1
  .runWith({ memory: "256MB" })
  .auth.user()
  .onCreate(async (user) => {
    console.log("New user created:", user.uid, user.email, user.displayName);

    try {
      const customClaims = { role: "student" };
      await admin.auth().setCustomUserClaims(user.uid, customClaims);
      console.log(`Set custom claim 'role: student' for user ${user.uid}`);

      const userDocRef = admin.firestore().collection("users").doc(user.uid);
      const userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        await userDocRef.set({
          full_name: user.displayName || "New Student User",
          email: user.email,
          contact: "",
          role: "student",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`Created Firestore user document for ${user.uid}`);
      } else {
        await userDocRef.set({ role: "student" }, { merge: true });
        console.log(
          `Updated existing Firestore doc for ${user.uid} with role: student`
        );
      }

      return null;
    } catch (error) {
      console.error(
        `Error setting default role/creating Firestore doc for user ${user.uid}:`,
        error
      );
      return null;
    }
  });

/**
 * TEMPORARY ADMIN FUNCTION: Sets custom user claims.
 * Call this from the app (or a temporary script/button) to fix existing users.
 * Arguments: { uid: string, role: 'admin' | 'instructor' | 'student' }
 * 
 * WARNING: This function is OPEN for testing. 
 * IN PRODUCTION, ADD AUTH CHECKS SO ONLY SUPER-ADMIN CAN CALL IT.
 * FOR NOW, WE ASSUME YOU WILL DELETE/DISABLE IT AFTER FIXING USERS.
 */
exports.setUserRole = onCall({ memory: "256MiB" }, async (request) => {
  const { uid, role } = request.data;

  if (!uid || !role) {
    throw new HttpsError("invalid-argument", "The function must be called with 'uid' and 'role'.");
  }

  if (!['admin', 'instructor', 'student'].includes(role)) {
    throw new HttpsError("invalid-argument", "Role must be one of: admin, instructor, student.");
  }

  try {
    await admin.auth().setCustomUserClaims(uid, { role });
    console.log(`Successfully set role '${role}' for user ${uid}`);
    
    // Also update Firestore for consistency
    await admin.firestore().collection("users").doc(uid).set({ role }, { merge: true });

    return { message: `Success! User ${uid} is now a ${role}. Please sign out and sign back in.` };
  } catch (error) {
    console.error("Error setting user role:", error);
    throw new HttpsError("internal", "Unable to set user role.");
  }
});
