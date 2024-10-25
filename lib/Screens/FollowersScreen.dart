import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class FollowersScreen extends StatelessWidget {
  final String userId;

  FollowersScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Followers'),
        backgroundColor: Colors.black,
      ),
      body: FutureBuilder<DataSnapshot>(
        future: FirebaseDatabase.instance.ref('users/$userId/followers').get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading followers'));
          } else if (!snapshot.hasData || snapshot.data!.value == null) {
            return Center(child: Text('No followers found'));
          } else {
            Map<dynamic, dynamic> followersMap = snapshot.data!.value as Map;
            List followerIds = followersMap.keys.toList();

            return ListView.builder(
              itemCount: followerIds.length,
              itemBuilder: (context, index) {
                String followerId = followerIds[index];


                return FutureBuilder<DataSnapshot>(
                  future: FirebaseDatabase.instance.ref('users/$followerId').get(),
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
