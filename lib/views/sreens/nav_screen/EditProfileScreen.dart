import 'dart:convert'; // Para codificar en Base64
import 'dart:io'; // Para manejar archivos
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentLastName;
  final String currentBio;
  final String currentPhone;
  final String currentProfilePicture;

  EditProfileScreen({
    required this.currentName,
    required this.currentLastName,
    required this.currentBio,
    required this.currentPhone,
    required this.currentProfilePicture,
  });

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  File? _image;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentName;
    _lastNameController.text = widget.currentLastName;
    _bioController.text = widget.currentBio;
    _phoneController.text = widget.currentPhone;
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // Convertir la imagen a Base64
  String _encodeImageToBase64(File imageFile) {
    List<int> imageBytes = imageFile.readAsBytesSync();
    return base64Encode(imageBytes);
  }

  // Mostrar la imagen desde Base64
  Image _decodeBase64ToImage(String base64Image) {
    return Image.memory(
      base64Decode(base64Image),
      fit: BoxFit.cover,
    );
  }

  Future<void> _updateProfile() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuario no autenticado.');

      String? profilePictureBase64 = widget.currentProfilePicture;

      // Convertir la nueva imagen a Base64 si el usuario seleccionó una
      if (_image != null) {
        profilePictureBase64 = _encodeImageToBase64(_image!);
      }

      // Actualizar datos en Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': _nameController.text,
        'surname': _lastNameController.text,
        'bio': _bioController.text,
        'phone': _phoneController.text,
        'profilePicture': profilePictureBase64, // Guardar la imagen en Base64
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Perfil actualizado correctamente')),
      );

      Navigator.pop(context); // Regresar a la pantalla de perfil
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar el perfil: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Perfil'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _updateProfile,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Foto de perfil
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _image != null
                      ? FileImage(_image!)
                      : (widget.currentProfilePicture.isNotEmpty
                      ? _decodeBase64ToImage(widget.currentProfilePicture).image
                      : AssetImage('assets/default_profile.png') as ImageProvider),
                ),
              ),
              SizedBox(height: 16),
              // Campo de nombre
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              // Campo de apellido
              TextField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: 'Apellido',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              // Campo de biografía
              TextField(
                controller: _bioController,
                decoration: InputDecoration(
                  labelText: 'Biografía',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              // Campo de teléfono
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
      ),
    );
  }
}