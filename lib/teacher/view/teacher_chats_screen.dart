import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:campus_connect_app/core/theme/colors.dart';
import 'package:campus_connect_app/core/theme/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_connect_app/core/network/chat_repository.dart';
import 'package:campus_connect_app/core/utils/date_formatter.dart';
import 'package:campus_connect_app/core/providers/user_provider.dart';

class TeacherChatsScreen extends ConsumerStatefulWidget {
  const TeacherChatsScreen({super.key});

  @override
  ConsumerState<TeacherChatsScreen> createState() => _TeacherChatsScreenState();
}
class _TeacherChatsScreenState extends ConsumerState<TeacherChatsScreen> {
  List<Map<String, dynamic>> rooms = [];
  bool isLoading = true;
  StreamSubscription? _messageSub;

  @override
  void initState() {
    super.initState();
    _loadRooms();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _messageSub = ref.read(chatRepositoryProvider).messageStream.listen((msg) {
        if (mounted) {
          _handleNewMessage(msg);
        }
      });
    });
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    super.dispose();
  }

  void _handleNewMessage(Map<String, dynamic> msg) {
    final roomId = msg['chatRoomId'];
    final roomIndex = rooms.indexWhere((r) => r['id'] == roomId);

    if (roomIndex != -1) {
      // Room exists, update its messages and move to top
      setState(() {
        final room = rooms.removeAt(roomIndex);
        
        // Update messages array
        List<dynamic> currentMessages = room['messages'] ?? [];
        if (currentMessages.isEmpty) {
          currentMessages.add(msg);
        } else {
          currentMessages[0] = msg; // Just replace the first one for snippet
        }
        room['messages'] = currentMessages;

        // Move to top
        rooms.insert(0, room);
      });
    } else {
      // New room, reload list
      _loadRooms();
    }
  }

  Future<void> _loadRooms() async {
    try {
      final repo = ref.read(chatRepositoryProvider);
      final fetchedRooms = await repo.fetchRooms();
      if (mounted) {
        setState(() {
          rooms = fetchedRooms;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.neutral50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'Chats',
            style: AppTypography.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                FluentIcons.arrow_clockwise_24_regular,
                color: AppColors.neutral700,
              ),
              onPressed: () {
                setState(() => isLoading = true);
                _loadRooms();
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.all(4),
                  labelColor: AppColors.neutral900,
                  unselectedLabelColor: AppColors.neutral500,
                  labelStyle: AppTypography.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: AppTypography.textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Groups'),
                    Tab(text: 'Direct Messages'),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Container(height: 1, color: AppColors.neutral200),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: [
                        _buildList(isGroup: true),
                        _buildList(isGroup: false),
                      ],
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'teacher_chats_fab',
          onPressed: () async {
            await context.push('/chat/new');
            _loadRooms();
          },
          backgroundColor: AppColors.secondary500,
          child: const Icon(
            FluentIcons.chat_add_24_regular,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildList({required bool isGroup}) {
    final filtered = rooms.where((r) => r['isGroup'] == isGroup).toList();
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                isGroup ? FluentIcons.people_team_24_regular : FluentIcons.chat_multiple_24_regular,
                size: 48,
                color: AppColors.neutral300,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No ${isGroup ? 'Group' : 'Direct'} Chats',
              style: AppTypography.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.neutral800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When you start a conversation,\nit will appear here.',
              textAlign: TextAlign.center,
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: AppColors.neutral500,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80), // Space for FAB
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final room = filtered[index];
        
        // Extract the last message if available
        String subtitle = 'Click to start chatting';
        String time = '';
        final messages = room['messages'] as List<dynamic>?;
        if (messages != null && messages.isNotEmpty) {
          final lastMsg = messages[0];
          subtitle = lastMsg['content'] ?? subtitle;
          if (room['isGroup'] == true && lastMsg['sender'] != null) {
            subtitle = '${lastMsg['sender']['name']}: $subtitle';
          }
          if (lastMsg['createdAt'] != null) {
            try {
              final date = DateTime.parse(lastMsg['createdAt']).toLocal();
              time = DateFormatter.formatRelativeTime(date);
            } catch (_) {}
          }
        }
        
        // Use the other participant's name for DMs if room name is null
        String title = room['name'] ?? 'Direct Message';
        if (room['isGroup'] == false && (room['name'] == null || room['name'].isEmpty)) {
           final participants = room['participants'] as List<dynamic>?;
           if (participants != null) {
             final currentUser = ref.read(userProvider).value;
             for (var p in participants) {
               if (p['user'] != null && p['user']['id'] != currentUser?['id']) {
                 title = p['user']['name'] ?? 'User';
                 break;
               }
             }
           }
        }

        return _buildChatTile(
          context: context,
          id: room['id'],
          title: title,
          subtitle: subtitle,
          time: time,
          isGroup: room['isGroup'],
          unreadCount: 0,
        );
      },
    );
  }

  Widget _buildChatTile({
    required BuildContext context,
    required String id,
    required String title,
    required String subtitle,
    required String time,
    int unreadCount = 0,
    bool isGroup = false,
  }) {
    return ListTile(
      onTap: () {
        context.push('/chat/$id?chatName=${Uri.encodeComponent(title)}&isGroup=$isGroup');
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Stack(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isGroup ? AppColors.secondary50 : AppColors.neutral100,
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Icon(
              isGroup
                  ? FluentIcons.people_24_regular
                  : FluentIcons.person_24_regular,
              color: isGroup ? AppColors.secondary600 : AppColors.neutral600,
            ),
          ),
        ],
      ),
      title: Text(
        title,
        style: AppTypography.textTheme.titleMedium?.copyWith(
          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
          color: AppColors.neutral900,
        ),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.textTheme.bodyMedium?.copyWith(
          color: unreadCount > 0 ? AppColors.neutral800 : AppColors.neutral500,
          fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            time,
            style: AppTypography.textTheme.labelSmall?.copyWith(
              color: unreadCount > 0
                  ? AppColors.primary500
                  : AppColors.neutral400,
            ),
          ),
          const SizedBox(height: 4),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primary600,
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
