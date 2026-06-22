import 'package:flutter/material.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'licenses_modal.dart';

class SettingsFooter extends StatelessWidget {
  const SettingsFooter({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Text("myHaystack", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
          const Text("Easily manage your OpenHaystack accessories"),
          const Text("with a wonderful UI"),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("by "),
              GestureDetector(
                onTap: () => _launchUrl('https://github.com/ReLoia'),
                child: const Text(
                  "reloia",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => _launchUrl('https://github.com/ReLoia/myHaystack'),
                icon: const Icon(SimpleIcons.github),
              ),
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const LicensesModal(),
                  );
                },
                icon: const Icon(Icons.info_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
