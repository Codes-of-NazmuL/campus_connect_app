import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_connect_app/core/theme/colors.dart';
import 'package:campus_connect_app/core/theme/typography.dart';
import 'package:campus_connect_app/core/providers/user_provider.dart';
import 'package:campus_connect_app/core/network/auth_repository.dart';

class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsyncValue = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: userAsyncValue.when(
        data: (user) {
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 80,
                      ), // Space for overlapping avatar
                      _buildProfileHeader(user),
                      const SizedBox(height: 24),
                      Text(
                        'Academic Profile',
                        style: AppTypography.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildAcademicBadges(user),
                      const SizedBox(height: 24),
                      Text(
                        'Preferences',
                        style: AppTypography.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSettingsSection(),
                      const SizedBox(height: 24),
                      _buildLogoutButton(context, ref),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
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

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140.0,
      pinned: true,
      backgroundColor: AppColors.primary900,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary900, AppColors.primary700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            FluentIcons.settings_24_regular,
            color: Colors.white,
          ),
          onPressed: () {},
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: SizedBox(
          height: 0,
          child: OverflowBox(
            minHeight: 0,
            maxHeight: double.infinity,
            alignment: Alignment.center,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.neutral50, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const CircleAvatar(
                radius: 46,
                backgroundColor: AppColors.neutral100,
                child: Icon(
                  FluentIcons.person_48_filled,
                  size: 50,
                  color: AppColors.neutral400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> user) {
    return Column(
      children: [
        Center(
          child: Text(
            user['name'] ?? 'Student Name',
            style: AppTypography.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'ID: ${user['boardRoll'] ?? user['id']}',
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: AppColors.neutral500,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.neutral200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                FluentIcons.building_bank_20_regular,
                size: 18,
                color: AppColors.primary700,
              ),
              const SizedBox(width: 8),
              Text(
                user['department'] ?? 'Department',
                style: AppTypography.textTheme.labelMedium?.copyWith(
                  color: AppColors.neutral700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAcademicBadges(Map<String, dynamic> user) {
    return Row(
      children: [
        Expanded(
          child: _buildBadge(
            'Semester',
            user['semester'] ?? 'N/A',
            FluentIcons.book_24_regular,
            AppColors.secondary500,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildBadge(
            'Shift',
            user['shift'] ?? 'N/A',
            FluentIcons.clock_24_regular,
            AppColors.warning500,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildBadge(
            'Group',
            user['group'] ?? 'N/A',
            FluentIcons.people_24_regular,
            AppColors.success500,
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.neutral500, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: AppTypography.textTheme.labelSmall?.copyWith(
              color: AppColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            FluentIcons.globe_24_regular,
            'Language',
            'English',
          ),
          _buildDivider(),
          _buildSettingsTile(
            FluentIcons.dark_theme_24_regular,
            'Appearance',
            'Light Theme',
          ),
          _buildDivider(),
          _buildSettingsTile(
            FluentIcons.alert_24_regular,
            'Notifications',
            'Enabled',
            isNavigate: true,
          ),
          _buildDivider(),
          _buildSettingsTile(
            FluentIcons.lock_closed_24_regular,
            'Privacy & Security',
            null,
            isNavigate: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title,
    String? trailingText, {
    bool isNavigate = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon, color: AppColors.neutral600, size: 24),
      title: Text(
        title,
        style: AppTypography.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(
              trailingText,
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: AppColors.neutral500,
              ),
            ),
          if (isNavigate) ...[
            const SizedBox(width: 8),
            const Icon(
              FluentIcons.chevron_right_20_regular,
              size: 20,
              color: AppColors.neutral400,
            ),
          ],
        ],
      ),
      onTap: () {},
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1, color: AppColors.neutral100),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          await ref.read(authRepositoryProvider).logout();
          if (context.mounted) {
            context.go('/');
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.error700,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.neutral200),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(FluentIcons.sign_out_24_regular),
            SizedBox(width: 8),
            Text(
              'Log Out',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
