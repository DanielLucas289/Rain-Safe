import 'package:flutter/material.dart';
import 'about_screen.dart';
import '../theme/app_colors.dart';

class ConfigScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text("Habilitar modo escuro"),
          value: false,
          onChanged: (val) {},
        ),
        ListTile(
          title: const Text("Notificações"),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {},
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AboutScreen()),
            );
          },
          child: const Text("Sobre"),
        ),
      ],
    );
  }
}
