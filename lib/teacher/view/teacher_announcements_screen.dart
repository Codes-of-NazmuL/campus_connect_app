import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_connect_app/core/theme/colors.dart';
import 'package:campus_connect_app/core/theme/typography.dart';
import 'package:campus_connect_app/core/providers/announcement_provider.dart';
import 'package:campus_connect_app/core/network/announcement_repository.dart';
import 'package:campus_connect_app/shared/widgets/cards.dart';
import 'package:campus_connect_app/shared/widgets/inputs.dart';
import 'package:campus_connect_app/core/utils/toast_service.dart';

class TeacherAnnouncementsScreen extends ConsumerWidget {
  const TeacherAnnouncementsScreen({super.key});

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedTarget = 'ALL';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'New Announcement',
                    style: AppTypography.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  StandardInput(
                    controller: titleController,
                    hintText: 'Announcement title',
                    prefixIcon: const Icon(FluentIcons.megaphone_20_regular),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Write your announcement here...',
                      filled: true,
                      fillColor: AppColors.neutral50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.neutral200,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.neutral200,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.accentBlue,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Target Audience'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedTarget,
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text('Everyone')),
                      DropdownMenuItem(
                        value: 'STUDENT',
                        child: Text('Students Only'),
                      ),
                      DropdownMenuItem(
                        value: 'TEACHER',
                        child: Text('Teachers Only'),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => selectedTarget = v ?? 'ALL'),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.neutral50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.neutral200,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(FluentIcons.send_24_regular),
                    label: const Text('Post Announcement'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary500,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      if (titleController.text.isEmpty ||
                          contentController.text.isEmpty) {
                        return;
                      }
                      Navigator.pop(ctx);
                      try {
                        await ref
                            .read(announcementRepositoryProvider)
                            .createAnnouncement(
                              title: titleController.text.trim(),
                              content: contentController.text.trim(),
                              target: selectedTarget,
                            );
                        ref.invalidate(announcementsProvider);
                        if (context.mounted) {
                          ToastService.showSuccess(
                            context: context,
                            message: 'Announcement posted!',
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ToastService.showError(
                            context: context,
                            message: e.toString(),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsProvider);

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Announcements',
          style: AppTypography.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.neutral200, height: 1),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'teacher_announcements_fab',
        onPressed: () => _showCreateDialog(context, ref),
        backgroundColor: AppColors.secondary500,
        icon: const Icon(FluentIcons.add_24_filled, color: Colors.white),
        label: const Text(
          'New',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: announcementsAsync.when(
        data: (announcements) {
          if (announcements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    FluentIcons.megaphone_off_24_regular,
                    size: 64,
                    color: AppColors.neutral300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No announcements yet',
                    style: AppTypography.textTheme.titleMedium?.copyWith(
                      color: AppColors.neutral500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + New to post one',
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: AppColors.neutral400,
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(announcementsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: announcements.length,
              separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _buildAnnouncementCard(context, ref, announcements[index]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Failed to load',
                style: AppTypography.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(announcementsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> a,
  ) {
    final author = a['author'] as Map<String, dynamic>?;
    final target = a['target'] ?? 'ALL';
    final targetColor = target == 'STUDENT'
        ? AppColors.secondary500
        : (target == 'TEACHER' ? AppColors.primary500 : AppColors.accentBlue);

    return StandardCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: targetColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: targetColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            target == 'ALL'
                                ? 'Everyone'
                                : (target == 'STUDENT'
                                      ? 'Students'
                                      : 'Teachers'),
                            style: AppTypography.textTheme.labelSmall?.copyWith(
                              color: targetColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          _formatDate(a['createdAt']),
                          style: AppTypography.textTheme.labelSmall?.copyWith(
                            color: AppColors.neutral400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      a['title'] ?? '',
                      style: AppTypography.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      a['content'] ?? '',
                      style: AppTypography.textTheme.bodyMedium?.copyWith(
                        color: AppColors.neutral600,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'By ${author?['name'] ?? 'Unknown'}',
                          style: AppTypography.textTheme.labelSmall?.copyWith(
                            color: AppColors.neutral400,
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            try {
                              await ref
                                  .read(announcementRepositoryProvider)
                                  .deleteAnnouncement(a['id']);
                              ref.invalidate(announcementsProvider);
                            } catch (e) {
                              if (context.mounted) {
                                ToastService.showError(
                                  context: context,
                                  message: e.toString(),
                                );
                              }
                            }
                          },
                          child: const Icon(
                            FluentIcons.delete_16_regular,
                            size: 18,
                            color: AppColors.error500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr.toString());
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }
}
