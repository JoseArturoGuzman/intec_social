import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  // Registro de usuario
  Future<User?> registerWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Guardar información del usuario en Firestore
      await _firebaseFirestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': userCredential.user!.uid,
      });

      return userCredential.user;
    } catch (e) {
      print('Error en el registro: $e');
      return null;
    }
  }

  // Inicio de sesión de usuario
  Future<User?> loginWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print('Error en el inicio de sesión: $e');
      return null;
    }
  }

  // Inicio de sesión con Google
  Future<User?> loginWithGoogle() async {
    // Implementar lógica de inicio de sesión con Google si es necesario
    print('Funcionalidad de inicio de sesión con Google pendiente de implementación');
    return null;
  }

  // Cerrar sesión
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error al cerrar sesión: $e');
    }
  }

  // Recuperación de contraseña
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('Correo de recuperación enviado a $email');
    } catch (e) {
      print('Error en la recuperación de contraseña: $e');
    }
  }

  // Verificación del estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Obtener datos del usuario desde Firestore
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firebaseFirestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error al obtener datos del usuario: $e');
      return null;
    }
  }

  // Actualizar información del usuario en Firestore
  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      await _firebaseFirestore.collection('users').doc(userId).update(data);
      print('Datos del usuario actualizados correctamente.');
    } catch (e) {
      print('Error al actualizar datos del usuario: $e');
    }
  }

  // Eliminar usuario de Firestore
  Future<void> deleteUser(String userId) async {
    try {
      await _firebaseFirestore.collection('users').doc(userId).delete();
      print('Usuario eliminado correctamente de Firestore.');
    } catch (e) {
      print('Error al eliminar usuario: $e');
    }
  }

  // Escuchar cambios en tiempo real de usuarios
  Stream<QuerySnapshot> getUsersStream() {
    return _firebaseFirestore.collection('users').snapshots();
  }
}
