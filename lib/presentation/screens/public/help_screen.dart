import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../widgets/ui.dart';
import '../common/support.dart';

/// How NTIZA works and how to reach support.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const TopBar('Help', back: false),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('How NTIZA works',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            const AppCard(
              padding: EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Column(
                children: <Widget>[
                  HowStep(1, 'Farmer Requests', 'Pick a machine and the day you need it'),
                  HowStep(2, 'Owner Confirms', 'The machine owner accepts your request'),
                  HowStep(3, 'Payment Processed', 'Pay securely with MTN MoMo or Airtel Money'),
                  HowStep(4, 'Service Delivered', 'The equipment arrives at your farm'),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text('Need help?', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.all(16),
              onTap: () => showHelpDialog(context),
              child: const Row(
                children: [
                  IconTile(Icons.mail_outline, bg: AppColors.green50, size: 40, radius: 12),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text('Contact support',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.faint),
                ],
              ),
            ),
          ],
        ),
      );
}

class HowStep extends StatelessWidget {
  const HowStep(this.n, this.title, this.sub);
  final int n;
  final String title, sub;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: Text('$n',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(sub, style: const TextStyle(fontSize: 13.5, color: AppColors.muted)),
                ],
              ),
            ),
          ],
        ),
      );
}
