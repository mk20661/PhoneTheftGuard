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
      'uid': user.uid,
    });

    _controller.clear();
    _refreshPosts();
  }

  Future<void> _refreshPosts() async {
    _posts.clear();
    _lastDocument = null;
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
    final TextEditingController editController = TextEditingController(
      text: oldContent,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Community Page')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: <Widget>[
          const SizedBox(height: 8),
          const IconAndDetail(Icons.people, 'Community Events'),
          const IconAndDetail(Icons.shield, 'Phone Theft Awareness'),
          Consumer<ApplicationState>(
            builder:
                (context, appState, _) => AuthFunc(
                  loggedIn: appState.loggedIn,
                  signOut: () {
                    FirebaseAuth.instance.signOut();
                  },
                ),
          ),
          const Divider(height: 16, thickness: 1, color: Colors.grey),
          const Header('Discussion'),
          const Paragraph(
            'Join the community conversation and share your experiences.',
          ),
          const SizedBox(height: 8),
          if (user != null) ...[
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Share your insight...',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _postMessage(_controller.text, user),
              child: const Text('Post'),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Please log in to participate in the discussion.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          const Divider(),
          const Text(
            'Community Posts:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._posts.map((doc) {
            final data = doc.data()! as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text(data['content'] ?? ''),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('By ${data['displayName'] ?? 'Unknown'}'),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.thumb_up),
                          onPressed: () {
                            doc.reference.update({
                              'likes': FieldValue.increment(1),
                            });
                          },
                        ),
                        Text('${data['likes'] ?? 0}'),
                        if (user != null && data['uid'] == user.uid) ...[
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              _showEditDialog(doc.id, data['content']);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              await doc.reference.delete();
                              _refreshPosts();
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
              child: TextButton(
                onPressed: _loadMorePosts,
                child: const Text('Load more'),
              ),
            ),
        ],
      ),
    );
  }
}
