import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:campus_connect_app/core/theme/colors.dart';
import 'package:campus_connect_app/core/theme/typography.dart';
import 'package:campus_connect_app/core/providers/user_provider.dart';
import 'package:go_router/go_router.dart';

class ExamSeatDetailScreen extends ConsumerWidget {
  final Map<String, dynamic> seatData;

  const ExamSeatDetailScreen({super.key, required this.seatData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final userRoll = user.value?['boardRoll'] ?? '';

    // Parse grid
    List<List<String>> grid = [];
    int rows = seatData['rows'] ?? 0;
    int cols = seatData['columns'] ?? 0;

    try {
      if (seatData['layoutJson'] != null) {
        final List<dynamic> parsed = jsonDecode(seatData['layoutJson']);
        grid = parsed.map((r) => List<String>.from(r)).toList();
      }
    } catch (_) {}

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            FluentIcons.chevron_left_24_regular,
            color: AppColors.neutral900,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          seatData['title'] ?? 'Seat Plan',
          style: AppTypography.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        FluentIcons.building_24_regular,
                        size: 20,
                        color: AppColors.primary600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Department: ${seatData['department'] ?? 'N/A'}',
                        style: AppTypography.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        FluentIcons.book_24_regular,
                        size: 20,
                        color: AppColors.primary600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Semester: ${seatData['semester'] ?? 'N/A'}',
                        style: AppTypography.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (grid.isEmpty || rows == 0 || cols == 0)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'No grid layout available for this seat plan.',
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      color: AppColors.neutral500,
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    // Whiteboard
                    Container(
                      width: 200,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.neutral200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'FRONT OF CLASS (WHITEBOARD)',
                        style: AppTypography.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.neutral600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Icon(
                      FluentIcons.desktop_24_regular,
                      color: AppColors.neutral400,
                      size: 32,
                    ),
                    const SizedBox(height: 24),

                    // The Grid Map
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final screenWidth = constraints.maxWidth;
                        final double cellSpacing = 8.0;
                        final double availableWidth =
                            screenWidth - (cellSpacing * (cols - 1));
                        final double cellWidth = availableWidth / cols;
                        final double cellHeight =
                            cellWidth * 0.6; // Maintain aspect ratio

                        return Column(
                          children: List.generate(rows, (r) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: cellSpacing),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(cols, (c) {
                                  String val = '';
                                  if (r < grid.length && c < grid[r].length) {
                                    val = grid[r][c];
                                  }

                                  bool isDisabled = val == '[X]';
                                  bool isMySeat =
                                      val == userRoll && userRoll.isNotEmpty;

                                  return Container(
                                    width: cellWidth,
                                    height: cellHeight,
                                    margin: c < cols - 1
                                        ? EdgeInsets.only(right: cellSpacing)
                                        : EdgeInsets.zero,
                                    decoration: BoxDecoration(
                                      color: isDisabled
                                          ? Colors.transparent
                                          : (isMySeat
                                                ? AppColors.success500
                                                : Colors.white),
                                      border: Border.all(
                                        color: isDisabled
                                            ? AppColors.neutral300
                                            : (isMySeat
                                                  ? AppColors.success500
                                                  : AppColors.primary400),
                                        width: isDisabled ? 1.5 : 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: isDisabled
                                          ? null
                                          : [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.05,
                                                ),
                                                blurRadius: 2,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                    ),
                                    alignment: Alignment.center,
                                    child: isDisabled
                                        ? const SizedBox()
                                        : FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                2.0,
                                              ),
                                              child: Text(
                                                val,
                                                style: AppTypography
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 10,
                                                      color: isMySeat
                                                          ? Colors.white
                                                          : AppColors
                                                                .neutral900,
                                                    ),
                                              ),
                                            ),
                                          ),
                                  );
                                }),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
