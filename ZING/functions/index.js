const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.deleteUser = functions.https.onCall(async (data, context) => {
  const uid = data.uid;
  try {
    await admin.auth().deleteUser(uid);
    return {message: "User deleted successfully"};
  } catch (error) {
    throw new functions.https.HttpsError("not-found", "User not found", error);
  }
});
