import 'package:flutter/material.dart';

class NotificationSetupScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Notification Setup")),
      body: Column(
        children: [
          ListTile(
            title: Text("Remind me about task completion"),
            trailing: Switch(
              value: true,
              onChanged: (value) {
                // Handle notification setup
              },
            ),
          ),
          // Add more notification settings
        ],
      ),
    );
  }
}
