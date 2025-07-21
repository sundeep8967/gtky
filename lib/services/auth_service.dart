import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/logger.dart';
import 'firestore_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Google Sign-In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return null; // User cancelled the sign-in
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // Check if this is a new user and needs profile setup
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        await _createInitialUserProfile(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      Logger.error('Error signing in with Google', 'Auth', e);
      return null;
    }
  }

  // Create initial user profile after Google sign-in
  Future<void> _createInitialUserProfile(User user) async {
    final userModel = UserModel(
      id: user.uid,
      email: user.email ?? '',
      name: user.displayName ?? '',
      age: 0, // Will be set during profile completion
      profilePhotoUrl: user.photoURL,
      company: '', // Will be set during LinkedIn verification
      foodPreferences: [],
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
    );

    await _firestoreService.createUser(userModel);
  }

  // Check if user has completed profile setup
  Future<bool> isProfileComplete() async {
    if (currentUser == null) return false;
    
    final userModel = await _firestoreService.getUser(currentUser!.uid);
    if (userModel == null) return false;

    return userModel.age > 0 && 
           userModel.company.isNotEmpty && 
           userModel.foodPreferences.isNotEmpty;
  }

  // Check if user has LinkedIn verification
  Future<bool> isLinkedInVerified() async {
    if (currentUser == null) return false;
    
    final userModel = await _firestoreService.getUser(currentUser!.uid);
    if (userModel == null) return false;

    return userModel.company.isNotEmpty;
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      
      // Clear local preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      Logger.error('Error signing out', 'Auth', e);
    }
  }

  // Delete account
  Future<bool> deleteAccount() async {
    try {
      if (currentUser == null) return false;

      final userId = currentUser!.uid;
      
      // Delete user data from Firestore
      await _firestoreService.deleteUser(userId);
      
      // Delete Firebase Auth account
      await currentUser!.delete();
      
      return true;
    } catch (e) {
      Logger.error('Error deleting account', 'Auth', e);
      return false;
    }
  }

  // Update last active timestamp
  Future<void> updateLastActive() async {
    if (currentUser == null) return;
    
    await _firestoreService.updateUserLastActive(currentUser!.uid);
  }
}