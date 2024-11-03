import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutterspecimencopy/Screens/Admin/PostsScreen_Admin.dart';
import 'package:flutterspecimencopy/Screens/Admin/UserManagementScreen_Admin.dart';
import '../../screens/Admin/ContentModerationScreen_Admin.dart';

class AdminHomeTab extends StatefulWidget {
  @override
  State<AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends State<AdminHomeTab> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  int activeUsers = 0;
  int totalPosts = 0;
  int flaggedContent = 0;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }


  Future<void> fetchDashboardData() async {
    try {
      final activeUsersSnapshot = await _dbRef.child('users').once();
      final postsSnapshot = await _dbRef.child('posts').once();
      final flaggedSnapshot = await _dbRef.child('flaggedPosts').once();

      setState(() {
        activeUsers = activeUsersSnapshot.snapshot.children.length;
        totalPosts = postsSnapshot.snapshot.children.length;
        flaggedContent = flaggedSnapshot.snapshot.children.length;
      });
    } catch (e) {
      print('Error fetching dashboard data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildSummaryCard(
                  title: 'Active Users',
                  value: '$activeUsers',
                  icon: Icons.people,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => UserManagementTab()),
                    );
                  },
                ),
                _buildSummaryCard(
                  title: 'Total Posts',
                  value: '$totalPosts',
                  icon: Icons.post_add,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PostsScreenAdmin()),
                    );
                  },
                ),
                _buildSummaryCard(
                  title: 'Flagged Content',
                  value: '$flaggedContent',
                  icon: Icons.flag,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ContentModerationScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24.0),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.blueAccent),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(title, style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
