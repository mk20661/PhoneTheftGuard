import 'package:firebase_auth/firebase_auth.dart'
    hide EmailAuthProvider, PhoneAuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_state.dart';
import 'src/authentication.dart';
import 'src/widgets.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final TextEditingController _controller = TextEditingController();
  final List<DocumentSnapshot> _posts = [];
  DocumentSnapshot? _lastDocument;
  final int _limit = 10;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMorePosts();
  }

  Future<void> _postMessage(String text, User user) async {
    if (text.trim().isEmpty) return;

    await FirebaseFirestore.instance.collection('posts').add({
      'content': text.trim(),
      'timestamp': Timestamp.now(),
      'author': user.email ?? user.uid,
      'displayName': user.displayName ?? 'Anonymous',
      'likes': 0,
      'likedBy': [],
      'uid': user.uid,
    });

    _controller.clear();
    _refreshPosts();
  }

  Future<void> _refreshPosts() async {
    setState(() {
      _posts.clear();
      _lastDocument = null;
    });
    await _loadMorePosts();
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading) return;
    _isLoading = true;

    final query = FirebaseFirestore.instance
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .limit(_limit);

    final snapshot =
        _lastDocument == null
            ? await query.get()
            : await query.startAfterDocument(_lastDocument!).get();

    if (snapshot.docs.isNotEmpty) {
      _lastDocument = snapshot.docs.last;
      setState(() {
        _posts.addAll(snapshot.docs);
      });
    }

    _isLoading = false;
  }

  void _showEditDialog(String docId, String oldContent) {
    final TextEditingController editController =
        TextEditingController(text: oldContent);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Post'),
        content: TextField(
          controller: editController,
          maxLines: null,
          decoration: const InputDecoration(labelText: 'Your post'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('posts')
                  .doc(docId)
                  .update({'content': editController.text});
              Navigator.of(context).pop();
              _refreshPosts();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📢 Anti-Theft Community'),
      ),
      body: Consumer<ApplicationState>(
        builder: (context, appState, _) {
          final user = FirebaseAuth.instance.currentUser;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const IconAndDetail(Icons.feed, 'Real Incidents'),
                      const IconAndDetail(Icons.shield, 'Phone Theft Awareness'),
                      const SizedBox(height: 8),
                      AuthFunc(
                        loggedIn: appState.loggedIn,
                        signOut: () => FirebaseAuth.instance.signOut(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Header('🛡️ Share Your Story'),
              const Paragraph(
                'Have you experienced or witnessed phone theft? Share your story to help others stay alert.',
              ),
              const SizedBox(height: 12),
              if (appState.loggedIn && user != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: 'Write your experience or advice...',
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          maxLines: null,
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () => _postMessage(_controller.text, user),
                            icon: const Icon(Icons.send),
                            label: const Text('Post'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'Please log in to participate in the discussion.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 24),
              const Row(
                children: [
                  Icon(Icons.article_outlined, color: Colors.blue),
                  SizedBox(width: 6),
                  Text(
                    'Community Posts',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._posts.map((doc) {
                final data = doc.data()! as Map<String, dynamic>;
                final likedBy = List<String>.from(data['likedBy'] ?? []);
                final isLiked = user != null && likedBy.contains(user.uid);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['content'] ?? '',
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.person, size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text('By ${data['displayName'] ?? 'Unknown'}',
                                style: const TextStyle(color: Colors.grey)),
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                isLiked
                                    ? Icons.thumb_up_alt
                                    : Icons.thumb_up_alt_outlined,
                                size: 20,
                                color: isLiked ? Colors.blue : null,
                              ),
                              onPressed: user == null
                                  ? null
                                  : () async {
                                      final postRef = doc.reference;

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

                                      _refreshPosts();
                                    },
                            ),
                            Text('${data['likes'] ?? 0}'),
                            if (user != null && data['uid'] == user.uid) ...[
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () =>
                                    _showEditDialog(doc.id, data['content']),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Confirm Delete'),
                                      content: const Text(
                                          'Are you sure you want to delete this post?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmed == true) {
                                    await doc.reference.delete();
                                    _refreshPosts();

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Post deleted')),
                                    );
                                  }
                                },
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              if (!_isLoading && _lastDocument != null)
                Center(
                  child: OutlinedButton.icon(
                    onPressed: _loadMorePosts,
                    icon: const Icon(Icons.expand_more),
                    label: const Text('Load more'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
