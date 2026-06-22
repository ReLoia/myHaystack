import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LicensesModal extends StatelessWidget {
  const LicensesModal({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Open Source Acknowledgements'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLicenseItem(
              title: 'CARTO',
              url: 'https://carto.com/',
            ),
            _buildLicenseItem(
              title: 'OpenStreetMap Contributors',
              url: 'https://www.openstreetmap.org/copyright',
            ),
            _buildLicenseItem(
              title: 'Nominatim',
              url: 'https://nominatim.org/',
            ),
            _buildLicenseItem(
              title: 'OpenHaystack',
              url: 'https://github.com/seemoo-lab/openhaystack',
            ),
            _buildLicenseItem(
              title: 'Macless Haystack',
              url: 'https://github.com/dchristl/macless-haystack',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildLicenseItem({required String title, required String url}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(url, style: const TextStyle(color: Colors.blue)),
      onTap: () => _launchUrl(url),
      trailing: const Icon(Icons.open_in_new, size: 16),
    );
  }
}
