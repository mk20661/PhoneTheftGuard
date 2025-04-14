import 'package:firebase_auth/firebase_auth.dart' 
    hide EmailAuthProvider, PhoneAuthProvider; 
import 'package:flutter/material.dart';         
import 'package:provider/provider.dart';         

import 'app_state.dart';                          
import 'src/authentication.dart';                
import 'src/widgets.dart';   
class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Page'),
      ),
      body: ListView(
        children: <Widget>[
          const SizedBox(height: 8),
          const IconAndDetail(Icons.people, 'Community Events'),
          const IconAndDetail(Icons.shield, 'Phone Theft Awareness'),

          Consumer<ApplicationState>(
            builder: (context, appState, _) => AuthFunc(
              loggedIn: appState.loggedIn,
              signOut: () {
                FirebaseAuth.instance.signOut();
              },
            ),
          ),

          const Divider(
            height: 8,
            thickness: 1,
            indent: 8,
            endIndent: 8,
            color: Colors.grey,
          ),
          const Header('Discussion'),
          const Paragraph(
            'Join the community conversation and share your experiences.',
          ),
        ],
      ),
    );
  }
}