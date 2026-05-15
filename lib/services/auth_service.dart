import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Register with full name — saves user profile to Firestore
  // Rolls back auth user if Firestore write fails
  Future<UserCredential?> registerWithEmailPasswordAndName(
    String email,
    String password,
    String fullName,
  ) async {
    User? createdUser;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      createdUser = credential.user;
      if (createdUser == null) {
        throw 'Unable to create user account.';
      }

      final normalizedName = fullName.trim();
      await createdUser.updateDisplayName(normalizedName);

      await _firestore.collection('users').doc(createdUser.uid).set({
        'uid': createdUser.uid,
        'fullName': normalizedName,
        'email': createdUser.email ?? email,
        'createdAt': FieldValue.serverTimestamp(),
        'profileImageUrl': null,
        'totalMonthlyBudget': 0.0,
      });

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } on FirebaseException catch (e) {
      // Firestore write failed — roll back the created auth user
      // so user doesn't get stuck in a half-created state
      await createdUser?.delete();
      throw e.message ?? 'Failed to save user profile. Please try again.';
    } catch (e) {
      await createdUser?.delete();
      rethrow;
    }
  }

  // Fetch user profile from Firestore
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (_) {
      return null;
    }
  }

  // Update user profile in Firestore
  Future<void> updateUserProfile(UserModel user) async {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(user.toFirestore(), SetOptions(merge: true));
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Handle FirebaseAuth exceptions — returns human-readable message
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled. Please contact support.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'invalid-credential':
        return 'Invalid credentials. Please verify your email and password.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
