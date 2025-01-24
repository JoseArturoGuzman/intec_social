import 'dart:convert'; // Para decodificar Base64
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'Comments_screens.dart';

class FeedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Feed Principal'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('uploadedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar las publicaciones'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No hay publicaciones disponibles'));
          }

          final posts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final postId = post.id;
              final title = post['title'] ?? 'Sin título';
              final imageBase64 = post['imageBase64'] ?? '';
              final likes = post['likes'] ?? 0;
              final likedBy = post['likedBy'] ?? [];
              final commentsCount = post['commentsCount'] ?? 0;
              final userId = post['userId'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return Center(child: Text('Error al cargar el usuario'));
                  }

                  final userData = userSnapshot.data!;
                  final userName = userData['name'] ?? 'Usuario desconocido';
                  final userProfilePicture = userData['profilePicture'] ?? '';

                  return Card(
                    margin: EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (imageBase64.isNotEmpty)
                          Image.memory(
                            base64Decode(imageBase64),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 200,
                          ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: userProfilePicture.isNotEmpty
                                        ? MemoryImage(base64Decode(userProfilePicture))
                                        : AssetImage('assets/default_profile.png') as ImageProvider,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    userName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.favorite,
                                      color: likedBy.contains(FirebaseAuth.instance.currentUser?.uid)
                                          ? Colors.red
                                          : Colors.grey,
                                    ),
                                    onPressed: () => _toggleLike(postId),
                                  ),
                                  Text('$likes Likes'),
                                  SizedBox(width: 16),
                                  IconButton(
                                    icon: Icon(Icons.comment),
                                    onPressed: () => _navigateToCommentsScreen(context, postId),
                                  ),
                                  Text('$commentsCount Comentarios'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _toggleLike(String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
    final postDoc = await postRef.get();

    final likedBy = postDoc['likedBy'] ?? [];
    final isLiked = likedBy.contains(user.uid);

    if (isLiked) {
      await postRef.update({
        'likes': FieldValue.increment(-1),
        'likedBy': FieldValue.arrayRemove([user.uid]),
      });
    } else {
      await postRef.update({
        'likes': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([user.uid]),
      });
    }
  }

  void _navigateToCommentsScreen(BuildContext context, String postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsScreen(postId: postId),
      ),
    );
  }
}
