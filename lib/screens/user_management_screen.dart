import 'package:flutter/material.dart';

class UserManagementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("User Management")),
      body: ListView(
        children: [
          ListTile(
            title: Text("User 1"),
            subtitle: Text("Active"),
            trailing: IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                // Handle user management
              },
            ),
          ),
          // Add more users
        ],
      ),
    );
  }
}
