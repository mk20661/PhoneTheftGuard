import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Community')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Please log in to view or share posts.'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login'); // 跳转
                },
                child: Text('Log In'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Phone Theft Community')),
      body: Column(
        children: [
          PostInputSection(user: user),
          Divider(height: 1),
          Expanded(child: PostListSection()),
        ],
      ),
    );
  }
}

class PostInputSection extends StatefulWidget {
  final User user;
  const PostInputSection({required this.user});

  @override
  State<PostInputSection> createState() => _PostInputSectionState();
}

class _PostInputSectionState extends State<PostInputSection> {
  final TextEditingController _controller = TextEditingController();
  bool _isPosting = false;

  Future<void> _submitPost() async {
    final content = _controller.text.trim();
    if (content.isEmpty || _isPosting) return;

    setState(() => _isPosting = true);

    try {
      await FirebaseFirestore.instance.collection('posts').add({
        'uid': widget.user.uid,
        'username': widget.user.displayName ?? 'Anonymous',
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _controller.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to post: $e')));
    }

    setState(() => _isPosting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          TextField(
            controller: _controller,
            maxLines: null,
            decoration: InputDecoration(
              hintText: 'Share your phone theft experience...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _submitPost,
              child:
                  _isPosting
                      ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Text('Post'),
            ),
          ),
        ],
      ),
    );
  }
}

class PostListSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('posts')
              .orderBy('timestamp', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No stories have been shared yet.'));
        }

        final posts = snapshot.data!.docs;

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index].data() as Map<String, dynamic>;
            final time = (post['timestamp'] as Timestamp?)?.toDate();

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: ListTile(
                title: Text(post['username'] ?? 'Anonymous'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post['content'] ?? ''),
                    const SizedBox(height: 4),
                    Text(
                      time != null
                          ? time.toLocal().toString().substring(0, 16)
                          : 'Unknown time',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
