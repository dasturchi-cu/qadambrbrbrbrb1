import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Example notifications list
    final notifications = <String>[
      'Yangi challenge qo‘shildi!',
      'Mukofotingiz tayyor!',
      'Do‘stingiz sizni challengega taklif qildi.',
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirishnomalar'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Text(
                'Bildirishnomalar yo‘q',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.notifications, color: Colors.deepPurple),
                  title: Text(notifications[index]),
                );
              },
            ),
    );
  }
} 