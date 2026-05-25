import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:campus_connect_app/core/theme/colors.dart';
import 'package:campus_connect_app/core/theme/typography.dart';
import 'package:campus_connect_app/core/network/chat_repository.dart';

import 'teacher_home_screen.dart';
import 'teacher_students_screen.dart';
import 'teacher_announcements_screen.dart';
import 'teacher_chats_screen.dart';
import 'teacher_profile_screen.dart';

class TeacherMainContainer extends ConsumerStatefulWidget {
  const TeacherMainContainer({super.key});

  @override
  ConsumerState<TeacherMainContainer> createState() => _TeacherMainContainerState();
}

class _TeacherMainContainerState extends ConsumerState<TeacherMainContainer> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Connect global socket for live chatting
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatRepositoryProvider).connectSocket();
    });
  }

  final List<Widget> _screens = [
    const TeacherHomeScreen(),
    const TeacherStudentsScreen(),
    const TeacherAnnouncementsScreen(),
    const TeacherChatsScreen(),
    const TeacherProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: AppColors.neutral200, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            indicatorColor: Colors.transparent,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppTypography.textTheme.labelSmall!.copyWith(
                  color: AppColors.secondary500,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                );
              }
              return AppTypography.textTheme.labelSmall!.copyWith(
                color: AppColors.neutral400,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundColor: Colors.white,
            elevation: 0,
            height: 64,
            destinations: [
              _buildNavDestination(
                icon: FluentIcons.home_24_regular,
                selectedIcon: FluentIcons.home_24_filled,
                label: 'Home',
                isSelected: _currentIndex == 0,
              ),
              _buildNavDestination(
                icon: FluentIcons.people_24_regular,
                selectedIcon: FluentIcons.people_24_filled,
                label: 'Students',
                isSelected: _currentIndex == 1,
              ),
              _buildNavDestination(
                icon: FluentIcons.megaphone_24_regular,
                selectedIcon: FluentIcons.megaphone_24_filled,
                label: 'Updates',
                isSelected: _currentIndex == 2,
              ),
              _buildNavDestination(
                icon: FluentIcons.chat_24_regular,
                selectedIcon: FluentIcons.chat_24_filled,
                label: 'Chats',
                isSelected: _currentIndex == 3,
              ),
              _buildNavDestination(
                icon: FluentIcons.person_24_regular,
                selectedIcon: FluentIcons.person_24_filled,
                label: 'Profile',
                isSelected: _currentIndex == 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  NavigationDestination _buildNavDestination({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool isSelected,
  }) {
    return NavigationDestination(
      icon: Icon(icon, color: AppColors.neutral400),
      selectedIcon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(selectedIcon, color: AppColors.secondary500),
          const SizedBox(height: 4),
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: AppColors.secondary500,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
      label: label,
    );
  }
}
