import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class FollowingScreen extends StatelessWidget {
  final String userId;

  FollowingScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Following'),
        backgroundColor: Colors.black,
      ),
      body: FutureBuilder<DataSnapshot>(
        future: FirebaseDatabase.instance.ref('users/$userId/following').get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading following list'));
          } else if (!snapshot.hasData || snapshot.data!.value == null) {
            return Center(child: Text('No following found'));
          } else {
            Map<dynamic, dynamic> followingMap = snapshot.data!.value as Map;
            List followingIds = followingMap.keys.toList();

            return ListView.builder(
              itemCount: followingIds.length,
              itemBuilder: (context, index) {
                String followingId = followingIds[index];
                return FutureBuilder<DataSnapshot>(
                  future: FirebaseDatabase.instance.ref('users/$followingId').get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[300],
                          child: CircularProgressIndicator(),
                        ),
                        title: Text('Loading...'),
                      );
                    } else if (userSnapshot.hasError) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red[300],
                          child: Icon(Icons.error),
                        ),
                        title: Text('Error loading user data'),
                      );
                    } else if (!userSnapshot.hasData || userSnapshot.data!.value == null) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: AssetImage('assets/profile_placeholder.png'),
                        ),
                        title: Text('Unknown user'),
                      );
                    } else {
                      Map<dynamic, dynamic> userData = userSnapshot.data!.value as Map;
                      String userName = userData['userName'] ?? 'No name available';
                      String? profileImage = userData['profileImage'];

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: profileImage != null
                              ? NetworkImage(profileImage)
                              : AssetImage('assets/profile_placeholder.png') as ImageProvider,
                        ),
                        title: Text(userName),
                        onTap: () {
                          // Navigate to the followed user's profile
                        },
                      );
                    }
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
