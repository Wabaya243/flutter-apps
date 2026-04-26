import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <Map<String, dynamic>>[
      {'icon': Icons.login, 'label': 'Se connecter'},
      {'icon': Icons.tune, 'label': 'General'},
      {'icon': Icons.email_outlined, 'label': 'Email'},
      {'icon': Icons.workspace_premium_outlined, 'label': 'Upgrade to Plus'},
      {'icon': Icons.hub_outlined, 'label': 'App et connector'},
      {'icon': Icons.person_outline, 'label': 'Personalisation'},
      {'icon': Icons.data_saver_off, 'label': 'Data control'},
      {'icon': Icons.record_voice_over_outlined, 'label': 'Voice'},
      {'icon': Icons.security_outlined, 'label': 'Security'},
      {'icon': Icons.info_outline, 'label': 'About'},
      {'icon': Icons.logout, 'label': 'Déconnecter'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final it = items[index];
          return ListTile(
            leading: Icon(it['icon'] as IconData),
            title: Text(it['label'] as String),
            onTap: () async {
              if (it['icon'] == Icons.logout) {
                try {
                  await authService.logout();
                } finally {
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  }
                }
                return;
              }
              if (it['icon'] == Icons.login) {
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                }
                return;
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${it['label']} (à venir)')),
                );
              }
            },
          );
        },
      ),
    );
  }
}

