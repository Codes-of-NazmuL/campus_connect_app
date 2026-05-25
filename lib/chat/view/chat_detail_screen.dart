import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:campus_connect_app/core/theme/colors.dart';
import 'package:campus_connect_app/core/theme/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_connect_app/core/network/chat_repository.dart';
import 'package:campus_connect_app/core/providers/user_provider.dart';
import 'package:campus_connect_app/core/utils/date_formatter.dart';
import 'package:intl/intl.dart';
import 'package:campus_connect_app/core/utils/toast_service.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String roomId;
  final String chatName;
  final bool isGroup;
  final bool isOnline;

  const ChatDetailScreen({
    super.key,
    required this.roomId,
    required this.chatName,
    this.isGroup = false,
    this.isOnline = false,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isTyping = false;
  StreamSubscription? _messageSub;
  late final ChatRepository _chatRepo;

  @override
  void initState() {
    super.initState();
    _chatRepo = ref.read(chatRepositoryProvider);
    _initChat();
    _messageController.addListener(() {
      setState(() {
        _isTyping = _messageController.text.trim().isNotEmpty;
      });
    });
  }

  Future<void> _initChat() async {
    try {
      // 1. Fetch historical messages
      final fetched = await _chatRepo.fetchMessages(widget.roomId);
      if (mounted) {
        setState(() {
          _messages = fetched;
          _isLoading = false;
        });
      }

      // 2. Connect socket and join room
      await _chatRepo.connectSocket();
      _chatRepo.joinRoom(widget.roomId);

      // 3. Listen to incoming real-time messages
      _messageSub = _chatRepo.messageStream.listen((msg) {
        if (msg['chatRoomId'] == widget.roomId) {
          if (mounted) {
            setState(() {
              // Add to top of list since ListView is reversed
              _messages.insert(0, msg);
            });
          }
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ToastService.showError(
          context: context,
          message: 'Failed to load chat: $e',
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageSub?.cancel();
    // Use the saved _chatRepo instead of ref.read to avoid unmounted ref errors
    _chatRepo.leaveRoom(widget.roomId);
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _chatRepo.sendMessage(widget.roomId, text);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        reverse: true, // Show newest at the bottom
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final user = ref.watch(userProvider);
                          final isMe = msg['senderId'] == user.value?['id'];

                          // Date formatting for the time inside the bubble
                          String timeStr = '';
                          DateTime? currentDate;
                          if (msg['createdAt'] != null) {
                            try {
                              currentDate = DateTime.parse(msg['createdAt']).toLocal();
                              timeStr = DateFormat('hh:mm a').format(currentDate);
                            } catch (_) {}
                          }

                          // Check if we need to show a date header
                          bool showDateHeader = false;
                          final olderMsg = index + 1 < _messages.length ? _messages[index + 1] : null;
                          if (olderMsg == null) {
                            // Oldest message (at top of list visually), always show header
                            showDateHeader = true;
                          } else {
                            DateTime? olderDate;
                            if (olderMsg['createdAt'] != null) {
                              olderDate = DateTime.parse(olderMsg['createdAt']).toLocal();
                            }
                            if (!DateFormatter.isSameDay(currentDate, olderDate)) {
                              showDateHeader = true;
                            }
                          }

                          final messageBubble = _buildMessageBubble(
                            message: msg['content'] ?? '',
                            time: timeStr,
                            isMe: isMe,
                            senderName: widget.isGroup && !isMe
                                ? (msg['sender'] != null
                                      ? msg['sender']['name']
                                      : null)
                                : null,
                          );

                          if (showDateHeader) {
                            return Column(
                              children: [
                                _buildDateHeader(currentDate),
                                messageBubble,
                              ],
                            );
                          }
                          return messageBubble;
                        },
                      ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          FluentIcons.chevron_left_24_regular,
          color: AppColors.neutral900,
        ),
        onPressed: () => context.pop(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isGroup
                      ? AppColors.primary50
                      : AppColors.neutral100,
                  border: Border.all(color: AppColors.neutral200),
                ),
                child: Icon(
                  widget.isGroup
                      ? FluentIcons.people_24_regular
                      : FluentIcons.person_24_regular,
                  color: widget.isGroup
                      ? AppColors.primary600
                      : AppColors.neutral600,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chatName,
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.isGroup ? 'Group' : 'Direct Message',
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: AppColors.neutral500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppColors.neutral200, height: 1),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(FluentIcons.more_vertical_24_regular, color: AppColors.neutral900),
          onSelected: (value) async {
            if (value == 'leave') {
              try {
                await _chatRepo.leaveChatRoom(widget.roomId);
                if (context.mounted) context.pop();
              } catch (e) {
                if (context.mounted) {
                  ToastService.showError(context: context, message: 'Failed to leave chat');
                }
              }
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'leave',
              child: Text(
                widget.isGroup ? 'Leave Group' : 'Delete Chat',
                style: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.error500),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              FluentIcons.chat_bubbles_question_24_regular,
              size: 48,
              color: AppColors.neutral400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No messages yet',
            style: AppTypography.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.neutral800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Say hi and start the conversation!',
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: AppColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(DateTime? date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.neutral200.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              DateFormatter.formatChatHeaderDate(date),
              style: AppTypography.textTheme.labelSmall?.copyWith(
                color: AppColors.neutral600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required String message,
    required String time,
    required bool isMe,
    String? senderName,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && widget.isGroup) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neutral200,
              ),
              child: const Icon(
                FluentIcons.person_16_regular,
                size: 16,
                color: AppColors.neutral600,
              ),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMe && senderName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 4),
                    child: Text(
                      senderName,
                      style: AppTypography.textTheme.labelSmall?.copyWith(
                        color: AppColors.neutral500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primary500 : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    message,
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: isMe ? Colors.white : AppColors.neutral800,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      time,
                      style: AppTypography.textTheme.labelSmall?.copyWith(
                        color: AppColors.neutral400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.neutral200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.neutral200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: AppTypography.textTheme.bodyMedium?.copyWith(
                          color: AppColors.neutral400,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      maxLines: 4,
                      minLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          AnimatedScale(
            scale: _isTyping ? 1.0 : 0.9,
            duration: const Duration(milliseconds: 150),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: _isTyping ? AppColors.primary500 : AppColors.neutral200,
                shape: BoxShape.circle,
                boxShadow: _isTyping 
                    ? [BoxShadow(color: AppColors.primary500.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]
                    : [],
              ),
              child: IconButton(
                icon: Icon(
                  FluentIcons.send_24_filled, 
                  color: _isTyping ? Colors.white : AppColors.neutral400,
                  size: 20,
                ),
                onPressed: _isTyping ? _sendMessage : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
