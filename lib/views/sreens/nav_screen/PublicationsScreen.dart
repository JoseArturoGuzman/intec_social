import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';

class PublicationsScreen extends StatefulWidget {
  @override
  _PublicationsScreenState createState() => _PublicationsScreenState();
}

class _PublicationsScreenState extends State<PublicationsScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _titleController = TextEditingController();
  File? _selectedFile;
  String? _mediaType;
  bool _isUploading = false;
  VideoPlayerController? _videoController;

  Future<void> _selectMedia(String type) async {
    try {
      final pickedFile = await (type == 'image'
          ? _picker.pickImage(source: ImageSource.gallery)
          : _picker.pickVideo(source: ImageSource.gallery));

      if (pickedFile != null) {
        setState(() {
          _selectedFile = File(pickedFile.path);
          _mediaType = type;

          // Inicializar el controlador de video si se selecciona un video
          if (type == 'video') {
            _videoController = VideoPlayerController.file(_selectedFile!)
              ..initialize().then((_) {
                setState(() {}); // Actualizar la UI cuando el video esté listo
              });
          }
        });
      }
    } catch (e) {
      print('Error al seleccionar medio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar el archivo.')),
      );
    }
  }

  String _encodeVideoToBase64(File videoFile) {
    List<int> videoBytes = videoFile.readAsBytesSync();
    return base64Encode(videoBytes);
  }

  Future<dynamic> _decodeBase64ToVideo(String base64Video) async {
    return base64Decode(base64Video);
  }

  Future<void> _uploadMedia() async {
    if (_selectedFile == null || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, selecciona un archivo y escribe un título.')),
      );
      return;
    }

    try {
      setState(() {
        _isUploading = true;
      });

      // Get current user
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuario no autenticado.');

      // Encode the media file to Base64
      String base64Media = _mediaType == 'image'
          ? base64Encode(_selectedFile!.readAsBytesSync())
          : _encodeVideoToBase64(_selectedFile!);

      // Save metadata in Firestore
      await FirebaseFirestore.instance.collection('posts').add({
        'userId': user.uid, // User ID
        'imageBase64': _mediaType == 'image' ? base64Media : '', // Image data
        'videoBase64': _mediaType == 'video' ? base64Media : '', // Video data
        'mediaType': _mediaType, // 'image' or 'video'
        'title': _titleController.text, // Title of the post
        'uploadedAt': FieldValue.serverTimestamp(), // Timestamp of upload
        'likes': 0, // Initial likes
        'likedBy': [], // Empty list of likes
        'commentsCount': 0, // Initial comments count
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Publicación subida con éxito.')),
      );

      // Reset state after upload
      setState(() {
        _selectedFile = null;
        _mediaType = null;
        _titleController.clear(); // Clear the title field
        _videoController?.dispose(); // Dispose of the video controller
        _videoController = null;
      });
    } catch (e) {
      print('Error al subir archivo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir el archivo: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }


  @override
  void dispose() {
    _videoController?.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subir Publicaciones'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Campo de título
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Título de la publicación',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            SizedBox(height: 20),
            // Vista previa del archivo
            if (_selectedFile != null)
              _mediaType == 'image'
                  ? Image.file(_selectedFile!, height: 200, width: double.infinity, fit: BoxFit.cover)
                  : _videoController != null && _videoController!.value.isInitialized
                  ? AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              )
                  : Center(child: CircularProgressIndicator()),
            SizedBox(height: 20),
            // Botones de selección
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _selectMedia('image'),
                  icon: Icon(Icons.image, color: Colors.white),
                  label: Text('Seleccionar Imagen', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _selectMedia('video'),
                  icon: Icon(Icons.videocam, color: Colors.white),
                  label: Text('Seleccionar Video', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            // Botón de subir
            if (_selectedFile != null)
              ElevatedButton(
                onPressed: _isUploading ? null : _uploadMedia,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: _isUploading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                  'Subir Publicación',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}