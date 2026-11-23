import 'package:flutter/material.dart';

/// Where users go when something is wrong with a booking or their account.
const supportEmail = 'support@ntiza.app';

/// "Help & support" dialog shared by every portal.
Future<void> showHelpDialog(BuildContext context) => showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Help & support'),
        content: const Text('Problem with a booking or your account? '
            'E-mail $supportEmail with the booking reference and the NTIZA team '
            'will reply within one working day.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
        ],
      ),
    );
