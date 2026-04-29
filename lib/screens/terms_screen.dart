import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    final textColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.t('terms'),
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
              'Last Updated: April 2026',
              style: TextStyle(color: mutedColor, fontSize: 13),
            ),
            const SizedBox(height: 24),

            _buildSection(context, '1. Acceptance of Terms',
              'By downloading and using Kharcha, you agree to be bound by these Terms & Conditions. If you do not agree to any part of these terms, please do not use the application.',
              textColor, mutedColor),

            _buildSection(context, '2. App Purpose',
              'Kharcha is a personal expense tracking application designed to help you record, monitor, and understand your financial habits. It is intended for personal, non-commercial use only.',
              textColor, mutedColor),

            _buildSection(context, '3. No Financial Advice',
              'Kharcha does not provide any financial, investment, legal, or tax advice. The data shown in the app — including balances, summaries, and insights — is based solely on the information you enter and should not be treated as professional financial guidance.',
              textColor, mutedColor),

            _buildSection(context, '4. Data Ownership',
              'All data you enter into Kharcha belongs to you. The app stores all your expense and income records locally on your device using device storage. We do not access, upload, or process your data on any external servers.',
              textColor, mutedColor),

            _buildSection(context, '5. Data Loss',
              'Since all data is stored locally on your device, we are not responsible for any loss of data caused by uninstalling the app, clearing app data, device damage, factory resets, or any other circumstances beyond our control. We strongly recommend periodically noting important figures.',
              textColor, mutedColor),

            _buildSection(context, '6. Permitted Use',
              'You agree to use Kharcha only for lawful purposes and in a manner consistent with these Terms. You may not attempt to reverse-engineer, modify, or distribute the application without prior written permission.',
              textColor, mutedColor),

            _buildSection(context, '7. Updates & Changes',
              'We reserve the right to update or modify the app and these Terms at any time. Updated Terms will be reflected within the app. Your continued use of Kharcha after changes are posted constitutes your acceptance of the revised Terms.',
              textColor, mutedColor),

            _buildSection(context, '8. Disclaimer of Warranty',
              'Kharcha is provided "as is" without warranty of any kind, express or implied. We do not guarantee uninterrupted service, error-free performance, or that the app will meet your specific requirements.',
              textColor, mutedColor),

            _buildSection(context, '9. Limitation of Liability',
              'To the fullest extent permitted by law, the developers of Kharcha shall not be liable for any indirect, incidental, special, or consequential damages arising from your use or inability to use the application.',
              textColor, mutedColor),

            _buildSection(context, '10. Contact',
              'If you have any questions about these Terms & Conditions, please reach out to us at kharcha.app.help@gmail.com.',
              textColor, mutedColor),

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
