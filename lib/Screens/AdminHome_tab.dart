import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';


class AdminhomeTab extends StatefulWidget {
  @override
  State<AdminhomeTab> createState() => _AdminhomeTabState();
}

class _AdminhomeTabState extends State<AdminhomeTab> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  int activeUsers = 0;
  int totalPosts = 0;
  int flaggedContent = 0;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  // Fetch data from Firebase
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
                _buildSummaryCard('Active Users', '$activeUsers', Icons.people),
                _buildSummaryCard('Total Posts', '$totalPosts', Icons.post_add),
                _buildSummaryCard('Flagged Content', '$flaggedContent', Icons.flag),
              ],
            ),
            const SizedBox(height: 24.0),

          ],
        ),
      ),
    );
  }


  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Card(
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
    );
  }
}
