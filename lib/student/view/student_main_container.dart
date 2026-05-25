import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:campus_connect_app/core/theme/colors.dart';
import 'package:campus_connect_app/core/theme/typography.dart';
import 'package:campus_connect_app/core/network/chat_repository.dart';
import 'student_home_screen.dart';
import 'student_academic_screen.dart';
import 'student_chats_screen.dart';
import 'student_notifications_screen.dart';
import 'student_profile_screen.dart';

class StudentMainContainer extends ConsumerStatefulWidget {
  const StudentMainContainer({super.key});

  @override
  ConsumerState<StudentMainContainer> createState() => _StudentMainContainerState();
}

class _StudentMainContainerState extends ConsumerState<StudentMainContainer> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const StudentHomeScreen(),
    const StudentAcademicScreen(),
    const StudentChatsScreen(),
    const StudentNotificationsScreen(),
    const StudentProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Connect global socket for live chatting
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatRepositoryProvider).connectSocket();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.neutral0,
          border: const Border(
            top: BorderSide(color: AppColors.neutral200, width: 1),
          ),
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.neutral0,
            elevation: 0,
            selectedItemColor: AppColors.accentBlue,
            unselectedItemColor: AppColors.neutral500,
            selectedLabelStyle: AppTypography.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: AppTypography.textTheme.labelSmall,
            showUnselectedLabels: true,
            items: [
              _buildNavItem(
                FluentIcons.home_24_regular,
                FluentIcons.home_24_filled,
                'Home',
              ),
              _buildNavItem(
                FluentIcons.building_bank_24_regular,
                FluentIcons.building_bank_24_filled,
                'Academic',
              ),
              _buildNavItem(
                FluentIcons.chat_24_regular,
                FluentIcons.chat_24_filled,
                'Chats',
              ),
              _buildNavItem(
                FluentIcons.alert_24_regular,
                FluentIcons.alert_24_filled,
                'Alerts',
              ),
              _buildNavItem(
                FluentIcons.person_24_regular,
                FluentIcons.person_24_filled,
                'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 4, top: 8),
        child: Icon(icon),
      ),
      activeIcon: Padding(
        padding: const EdgeInsets.only(bottom: 4, top: 8),
        child: Icon(activeIcon),
      ),
      label: label,
    );
  }
}
