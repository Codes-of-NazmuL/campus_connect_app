import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_connect_app/core/theme/colors.dart';
import 'package:campus_connect_app/core/theme/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_connect_app/core/providers/user_provider.dart';
import 'package:campus_connect_app/core/network/auth_repository.dart';

class TeacherProfileScreen extends ConsumerWidget {
  const TeacherProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsyncValue = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Profile',
          style: AppTypography.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: userAsyncValue.when(
        data: (user) {
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileHeader(user),
                const SizedBox(height: 24),
                _buildSettingsSection(context, ref),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error loading profile',
                style: AppTypography.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(userProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> user) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.secondary100, width: 4),
              color: AppColors.neutral100,
            ),
            child: const Icon(
              FluentIcons.person_48_filled,
              size: 50,
              color: AppColors.neutral400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user['name'] ?? 'Teacher Name',
            style: AppTypography.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ID: ${user['employeeId'] ?? user['id']}',
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: AppColors.neutral500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildInfoChip(
                FluentIcons.briefcase_16_regular,
                user['department'] ?? 'Department',
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                FluentIcons.contact_card_16_regular,
                user['designation'] ?? 'Designation',
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(FluentIcons.edit_24_regular, size: 20),
              label: const Text('Edit Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondary600,
                side: const BorderSide(
                  color: AppColors.secondary200,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondary50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.secondary600),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.textTheme.labelMedium?.copyWith(
              color: AppColors.secondary700,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: FluentIcons.settings_24_regular,
            title: 'Account Settings',
            onTap: () {},
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: FluentIcons.local_language_24_regular,
            title: 'Language',
            subtitle: 'English',
            onTap: () {},
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: FluentIcons.lock_closed_24_regular,
            title: 'Privacy & Security',
            onTap: () {},
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: FluentIcons.question_circle_24_regular,
            title: 'Help & Support',
            onTap: () {},
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: FluentIcons.sign_out_24_regular,
            title: 'Log Out',
            isDestructive: true,
            onTap: () async {
              await ref.read(authRepositoryProvider).logout();
              if (context.mounted) {
                context.go('/');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    final color = isDestructive ? AppColors.error500 : AppColors.neutral700;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive ? AppColors.error50 : AppColors.neutral100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
      title: Text(
        title,
        style: AppTypography.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (subtitle != null) ...[
            Text(
              subtitle,
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: AppColors.neutral500,
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (!isDestructive)
            const Icon(
              FluentIcons.chevron_right_20_regular,
              size: 20,
              color: AppColors.neutral400,
            ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 60),
      color: AppColors.neutral100,
    );
  }
}
