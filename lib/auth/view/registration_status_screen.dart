import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:campus_connect_app/core/theme/colors.dart';
import 'package:campus_connect_app/core/theme/typography.dart';
import 'package:campus_connect_app/shared/widgets/buttons.dart';

class RegistrationStatusScreen extends StatelessWidget {
  final String status; // 'pending', 'approved', 'rejected'

  const RegistrationStatusScreen({
    super.key,
    this.status = 'pending', // Defaulting to pending for demonstration
  });

  @override
  Widget build(BuildContext context) {
    Color themeColor;
    IconData icon;
    String title;
    String description;

    switch (status) {
      case 'approved':
        themeColor = AppColors.success500;
        icon = FluentIcons.checkmark_circle_24_regular;
        title = 'Application Approved';
        description =
            'Your registration has been approved. You can now login to your account.';
        break;
      case 'rejected':
        themeColor = AppColors.error500;
        icon = FluentIcons.dismiss_circle_24_regular;
        title = 'Application Rejected';
        description =
            'Unfortunately, your registration was not approved. Please contact the administration.';
        break;
      case 'pending':
      default:
        themeColor = AppColors
            .accentBlue; // Using accentBlue instead of warning500 for a cleaner look
        icon = FluentIcons.timer_24_regular;
        title = 'Under Review';
        description =
            'Your application has been submitted and is currently under review by the administration. You will be notified once approved.';
        break;
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(icon, size: 100, color: themeColor),
              const SizedBox(height: 32),
              Text(
                title,
                style: AppTypography.textTheme.headlineLarge?.copyWith(
                  color: themeColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: AppTypography.textTheme.bodyLarge?.copyWith(
                  color: AppColors.neutral500,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              PrimaryButton(
                text: 'Back to Login',
                onPressed: () => context.go('/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
