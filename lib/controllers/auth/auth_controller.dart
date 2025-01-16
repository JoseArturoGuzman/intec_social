import 'package:firebase_auth/firebase_auth.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Registro de usuario
  Future<User?> registerWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
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
}
