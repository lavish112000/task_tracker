// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const UserAccountsDrawerHeader(
            accountName: Text('User Name'),
            accountEmail: Text('user.name@example.com'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text('U', style: TextStyle(fontSize: 40.0)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('Theme'),
            onTap: () { Navigator.pop(context); },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Us'),
            onTap: () { Navigator.pop(context); },
          ),
          ListTile(
            leading: const Icon(Icons.quiz_outlined),
            title: const Text('FAQ'),
            onTap: () { Navigator.pop(context); },
          ),
          ListTile(
            leading: const Icon(Icons.contact_mail_outlined),
            title: const Text('Contact us'),
            onTap: () { Navigator.pop(context); },
          ),
        ],
      ),
    );
  }
}
