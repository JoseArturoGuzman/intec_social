import 'dart:convert'; // Para decodificar Base64
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentsScreen extends StatelessWidget {
  final String postId;

  CommentsScreen({required this.postId});

  @override
  Widget build(BuildContext context) {
    final commentController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text('Comentarios'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(postId)
                  .collection('comments')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error al cargar los comentarios'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No hay comentarios disponibles'));
                }

                final comments = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final commentText = comment['text'] ?? '';
                    final authorName = comment['authorName'] ?? 'Anónimo';
                    final authorImage = comment['authorImage'] ?? '';
                    final likes = comment['likes'] ?? 0;
                    final likedBy = comment['likedBy'] ?? [];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: authorImage.isNotEmpty
                            ? MemoryImage(base64Decode(authorImage))
                            : AssetImage('assets/default_profile.png') as ImageProvider,
                      ),
                      title: Text(authorName),
                      subtitle: Text(commentText),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.favorite,
                              color: likedBy.contains(FirebaseAuth.instance.currentUser?.uid)
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                            onPressed: () => _toggleCommentLike(comment.id),
                          ),
                          Text('$likes'),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: 'Escribe un comentario...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () => _addComment(commentController.text, context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addComment(String text, BuildContext context) async {
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final authorName = userData['name'] ?? 'Anónimo';
    final authorImage = userData['profilePicture'] ?? '';

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .add({
      'text': text,
      'authorName': authorName,
      'authorImage': authorImage,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 0,
      'likedBy': [],
    });

    Navigator.pop(context);
  }

  Future<void> _toggleCommentLike(String commentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final commentRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId);

    final commentDoc = await commentRef.get();
    final likedBy = commentDoc['likedBy'] ?? [];
    final isLiked = likedBy.contains(user.uid);

    if (isLiked) {
      await commentRef.update({
        'likes': FieldValue.increment(-1),
        'likedBy': FieldValue.arrayRemove([user.uid]),
      });
    } else {
      await commentRef.update({
        'likes': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([user.uid]),
      });
    }
  }
}
