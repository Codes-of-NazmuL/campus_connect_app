import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:campus_connect_app/core/theme/colors.dart';
import 'package:campus_connect_app/core/theme/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:campus_connect_app/core/network/exam_repository.dart';

final scheduleProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repo = ref.watch(examRepositoryProvider);
  return repo.getSchedules();
});

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(scheduleProvider);

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Exam Schedule',
          style: AppTypography.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            FluentIcons.chevron_left_24_regular,
            color: AppColors.neutral900,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: scheduleAsync.when(
        data: (schedules) {
          if (schedules.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    FluentIcons.calendar_cancel_24_regular,
                    size: 56,
                    color: AppColors.neutral300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No schedules found',
                    style: AppTypography.textTheme.titleMedium?.copyWith(
                      color: AppColors.neutral500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Schedules will appear here once published',
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: AppColors.neutral400,
                    ),
                  ),
                ],
              ),
            );
          }

          // Group schedules by date
          final Map<String, List<Map<String, dynamic>>> grouped = {};
          for (final s in schedules) {
            final date = s['date'] ?? 'Unknown';
            grouped.putIfAbsent(date, () => []);
            grouped[date]!.add(Map<String, dynamic>.from(s));
          }

          final sortedDates = grouped.keys.toList()..sort();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(scheduleProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final date = sortedDates[index];
                final entries = grouped[date]!;
                return _buildDateGroup(date, entries);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Failed to load schedules',
                style: AppTypography.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(scheduleProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateGroup(String dateStr, List<Map<String, dynamic>> entries) {
    String formattedDate = dateStr;
    String dayName = '';
    bool isToday = false;

    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      isToday = date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
      formattedDate = DateFormat('MMM d, yyyy').format(date);
      dayName = isToday ? 'Today' : DateFormat('EEEE').format(date);
    } catch (_) {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 8),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isToday ? AppColors.primary700 : AppColors.neutral200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  dayName,
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: isToday ? Colors.white : AppColors.neutral700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formattedDate,
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: AppColors.neutral500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        ...entries.map((s) => _buildScheduleCard(s)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> schedule) {
    final type = schedule['type'] ?? 'EXAM';

    Color typeColor;
    IconData typeIcon;
    switch (type) {
      case 'CLASS':
        typeColor = AppColors.accentBlue;
        typeIcon = FluentIcons.book_24_regular;
        break;
      case 'LAB':
        typeColor = AppColors.success500;
        typeIcon = FluentIcons.beaker_24_regular;
        break;
      default: // EXAM
        typeColor = AppColors.error500;
        typeIcon = FluentIcons.document_24_regular;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left color stripe
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: typeColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type badge + title row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(typeIcon, size: 12, color: typeColor),
                              const SizedBox(width: 4),
                              Text(
                                type,
                                style: AppTypography.textTheme.labelSmall
                                    ?.copyWith(
                                  color: typeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (schedule['room'] != null &&
                            schedule['room'].toString().isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                FluentIcons.location_16_regular,
                                size: 14,
                                color: AppColors.neutral400,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                schedule['room'],
                                style: AppTypography.textTheme.labelSmall
                                    ?.copyWith(
                                  color: AppColors.neutral500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Subject
                    Text(
                      schedule['subject'] ?? 'Unknown Subject',
                      style: AppTypography.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Title (schedule name)
                    Text(
                      schedule['title'] ?? '',
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                        color: AppColors.neutral500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Time row
                    Row(
                      children: [
                        Icon(
                          FluentIcons.clock_16_regular,
                          size: 14,
                          color: AppColors.neutral400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${schedule['startTime'] ?? ''} – ${schedule['endTime'] ?? ''}',
                          style: AppTypography.textTheme.labelMedium?.copyWith(
                            color: AppColors.neutral600,
                            fontWeight: FontWeight.w600,
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
}
