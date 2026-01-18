// ignore_for_file: avoid_print
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:socially_app/services/exceptions/exceptions.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // 1. දැනට සිටින පරිශීලකයා ලබා ගැනීම
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // 2. Sign Up with Email and Password
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(mapFirebaseAuthExceptionCode(e.code));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 3. Sign In with Email and Password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(mapFirebaseAuthExceptionCode(e.code));
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  // 4. Sign In with Google (නිවැරදි කරන ලද කොටස)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Firestore එකේ මේ User දැනටමත් ඉන්නවද කියලා බලනවා
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          // User අලුත් නම් පමණක් Role එක 'user' ලෙස සකස් කර අලුතින් Document එකක් හදනවා
          final userData = {
            'userId': user.uid,
            'name': user.displayName ?? 'No Name',
            'email': user.email ?? 'No Email',
            'jobTitle': 'Member',
            'imageUrl': user.photoURL ?? '',
            'createdAt': Timestamp.now(),
            'updatedAt': Timestamp.now(),
            'password': '',
            'followers': 0,
            'role': 'user', // Default role for new users
          };

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(userData);
          print("New user created in Firestore");
        } else {
          // User දැනටමත් සිටී නම්, Role එක වෙනස් නොකර login වූ වේලාව පමණක් update කරනවා
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
                'updatedAt': Timestamp.now(),
                'imageUrl': user.photoURL ?? userDoc.get('imageUrl'),
              });
          print("Existing user updated without changing role");
        }
      }
      return userCredential;
    } catch (e) {
      print('Error Google Sign-In: $e');
      return null;
    }
  }

  // 5. Sign Out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }
}
