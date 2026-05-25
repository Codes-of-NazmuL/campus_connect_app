import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:campus_connect_app/core/theme/colors.dart';
import 'package:campus_connect_app/core/theme/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_connect_app/core/network/chat_repository.dart';
import 'package:campus_connect_app/core/utils/toast_service.dart';

class NewChatScreen extends ConsumerStatefulWidget {
  const NewChatScreen({super.key});

  @override
  ConsumerState<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends ConsumerState<NewChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedFilterIndex = 0;
  
  // 0: ALL, 1: STUDENT, 2: TEACHER
  final List<String> _filters = ['All', 'Students', 'Teachers'];
  final List<String> _roleFilters = ['ALL', 'STUDENT', 'TEACHER'];

  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchUsers();
    });
  }

  Future<void> _searchUsers() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(chatRepositoryProvider);
      final query = _searchController.text.trim();
      final role = _roleFilters[_selectedFilterIndex];
      final users = await repo.searchUsers(query: query, role: role);
      
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ToastService.showError(
          context: context,
          message: 'Failed to fetch users: $e',
        );
      }
    }
  }

  Future<void> _startChatWithUser(Map<String, dynamic> user) async {
    try {
      final repo = ref.read(chatRepositoryProvider);
      
      // Create or get existing DM room
      final room = await repo.createRoom(
        participantIds: [user['id']],
        name: user['name'], // Fallback name
        isGroup: false,
      );

      if (mounted) {
        // Go to chat detail screen
        context.pushReplacement(
          '/chat/${room['id']}?chatName=${Uri.encodeComponent(user['name'] ?? '')}&isGroup=false',
        );
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(
          context: context,
          message: 'Failed to start chat: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            FluentIcons.dismiss_24_regular,
            color: AppColors.neutral900,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'New Message',
          style: AppTypography.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(130),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search name or ID...',
                    hintStyle: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: AppColors.neutral400,
                    ),
                    prefixIcon: const Icon(
                      FluentIcons.search_24_regular,
                      color: AppColors.neutral500,
                    ),
                    filled: true,
                    fillColor: AppColors.neutral100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: List.generate(_filters.length, (index) {
                    final isSelected = _selectedFilterIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8, bottom: 12),
                      child: FilterChip(
                        label: Text(_filters[index]),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedFilterIndex = index;
                          });
                          _searchUsers(); // Refresh search with new filter
                        },
                        backgroundColor: AppColors.neutral50,
                        selectedColor: AppColors.primary900,
                        labelStyle: AppTypography.textTheme.labelMedium
                            ?.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.neutral700,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                        side: BorderSide(
                          color: isSelected
                              ? Colors.transparent
                              : AppColors.neutral200,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        showCheckmark: false,
                      ),
                    );
                  }),
                ),
              ),
              Container(height: 1, color: AppColors.neutral200),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(
                  child: Text(
                    'No users found',
                    style: AppTypography.textTheme.bodyLarge?.copyWith(
                      color: AppColors.neutral500,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final isTeacher = user['role'] == 'TEACHER';
                    
                    String subtitle = '';
                    if (isTeacher) {
                      subtitle = 'Teacher • ${user['department'] ?? 'Unknown'}';
                    } else {
                      subtitle = 'Student • ${user['department'] ?? ''} ${user['semester'] ?? ''}';
                    }

                    return _buildContactTile(
                      name: user['name'] ?? 'Unknown',
                      subtitle: subtitle,
                      isTeacher: isTeacher,
                      onTap: () => _startChatWithUser(user),
                    );
                  },
                ),
    );
  }

  Widget _buildContactTile({
    required String name,
    required String subtitle,
    required VoidCallback onTap,
    bool isTeacher = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isTeacher
                    ? AppColors.secondary50
                    : AppColors.neutral100,
                border: Border.all(color: AppColors.neutral200),
              ),
              child: Icon(
                FluentIcons.person_24_regular,
                color: isTeacher
                    ? AppColors.secondary600
                    : AppColors.neutral600,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: AppTypography.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isTeacher) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Teacher',
                            style: AppTypography.textTheme.labelSmall?.copyWith(
                              color: AppColors.secondary700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: AppColors.neutral500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
