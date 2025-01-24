import 'dart:convert'; // Para decodificar Base64
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'EditProfileScreen.dart'; // Asegúrate de importar la pantalla de edición

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? userName;
  String? userLastName;
  String? userEmail;
  String? userProfilePicture;
  String? userBio;
  String? userPhone;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        setState(() {
          userName = userData['name'];
          userLastName = userData['surname']; // Cambia 'lastName' por 'surname'
          userEmail = userData['email'];
          userProfilePicture = userData['profilePicture'];
          userBio = userData['bio'];
          userPhone = userData['phone'];
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  // Decodificar la imagen desde Base64
  Image _decodeBase64ToImage(String base64Image) {
    try {
      return Image.memory(
        base64Decode(base64Image),
        fit: BoxFit.cover,
      );
    } catch (e) {
      print('Error al decodificar la imagen: $e');
      return Image.asset('assets/default_profile.png'); // Mostrar una imagen por defecto en caso de error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Perfil'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(
                    currentName: userName ?? '',
                    currentLastName: userLastName ?? '',
                    currentBio: userBio ?? '',
                    currentPhone: userPhone ?? '',
                    currentProfilePicture: userProfilePicture ?? '',
                  ),
                ),
              ).then((_) => fetchUserData()); // Recargar datos después de editar
            },
          ),
        ],
      ),
      body: Center(
        child: userName != null && userEmail != null
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Foto de perfil
            CircleAvatar(
              radius: 50,
              backgroundImage: userProfilePicture != null && userProfilePicture!.isNotEmpty
                  ? _decodeBase64ToImage(userProfilePicture!).image
                  : AssetImage('assets/default_profile.png') as ImageProvider,
            ),
            SizedBox(height: 16),
            Text(
              'Nombre: $userName $userLastName',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Correo: $userEmail',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Teléfono: ${userPhone ?? "No proporcionado"}',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                userBio ?? 'No hay biografía disponible',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        )
            : CircularProgressIndicator(),
      ),
    );
  }
}