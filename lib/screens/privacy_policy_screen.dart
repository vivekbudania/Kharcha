import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    final textColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.t('privacy_policy'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${loc.t('pp_last_updated')} April 2026',
              style: TextStyle(color: mutedColor, fontSize: 13),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '1. Data Collection',
              'Kharcha is a fully offline personal expense tracker. We do not collect, transmit, or store any of your personal data on any external servers. All data you enter (such as amounts, categories, and logs) is stored entirely locally on your device.',
              textColor,
              mutedColor,
            ),
            _buildSection(
              context,
              '2. Data Security',
              'Since your data is strictly stored locally through your device\'s shared preferences, its security relies on your device\'s built-in security features. If you delete the app or clear its data, your expense history will be permanently lost as we do not hold cloud backups.',
              textColor,
              mutedColor,
            ),
            _buildSection(
              context,
              '3. Third-Party Services',
              'Kharcha does not use any third-party tracking, analytics, or advertising services that actively harvest user behavior or financial information.',
              textColor,
              mutedColor,
            ),
            _buildSection(
              context,
              '4. Permissions',
              'Kharcha does not request any sensitive device permissions such as camera, microphone, location, or contacts. The app only requires storage access to persist your locally saved expenses.',
              textColor,
              mutedColor,
            ),
            _buildSection(
              context,
              '5. Children\'s Privacy',
              'Kharcha is not directed at children under the age of 13. We do not knowingly collect any personal information from children.',
              textColor,
              mutedColor,
            ),
            _buildSection(
              context,
              '6. Changes to This Policy',
              'We may update our Privacy Policy from time to time. Any changes will be updated inside this screen along with the "Last Updated" date at the top.',
              textColor,
              mutedColor,
            ),
            _buildSection(
              context,
              '7. Contact Us',
              'If you have any questions or suggestions about this Privacy Policy, please contact us at kharcha.app.help@gmail.com.',
              textColor,
              mutedColor,
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String content,
    Color titleColor,
    Color contentColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: contentColor,
            ),
          ),
        ],
      ),
    );
  }
}
