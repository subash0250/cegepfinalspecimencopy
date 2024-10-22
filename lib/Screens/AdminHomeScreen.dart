import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'home_tab.dart';
import 'followers_tab.dart';
import 'post_tab.dart';
import 'profile_tab.dart';

class Adminhomescreen extends StatefulWidget {
  @override
  _AdminhomescreenState createState() => _AdminhomescreenState();
}

class _AdminhomescreenState extends State<Adminhomescreen> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
    HomeTab(),
    FollowersFragment(),
    PostTab(),
    ProfileTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'AdminHome',
            backgroundColor: Colors.black, // Background color for Home tab
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Followers',
            backgroundColor: Colors.black, // Background color for Followers tab
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Post',
            backgroundColor: Colors.black, // Background color for Post tab
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
            backgroundColor: Colors.black, // Background color for Profile tab
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white, // Highlight color for selected item
        unselectedItemColor: Colors.grey[600], // Color for unselected items
        onTap: _onItemTapped,
        type: BottomNavigationBarType.shifting, // To allow different tab background colors
      ),
    );
  }
}
