import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:campus_connect_app/core/theme/colors.dart';
import 'package:campus_connect_app/core/theme/typography.dart';
import 'package:campus_connect_app/shared/widgets/cards.dart';
import 'package:campus_connect_app/core/network/exam_repository.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:campus_connect_app/core/utils/toast_service.dart';

class StudentAcademicScreen extends ConsumerStatefulWidget {
  const StudentAcademicScreen({super.key});

  @override
  ConsumerState<StudentAcademicScreen> createState() =>
      _StudentAcademicScreenState();
}

class _StudentAcademicScreenState extends ConsumerState<StudentAcademicScreen> {
  List<dynamic> schedules = [];
  List<dynamic> examSeats = [];
  List<dynamic> results = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final examRepo = ref.read(examRepositoryProvider);
      final fetchedSchedules = await examRepo.getSchedules();
      final fetchedSeats = await examRepo.getExamSeats();
      final fetchedResults = await examRepo.getResults();

      if (mounted) {
        setState(() {
          schedules = fetchedSchedules;
          examSeats = fetchedSeats;
          results = fetchedResults;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ToastService.showError(
          context: context,
          message: 'Failed to load academic data: $e',
        );
      }
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      if (mounted) {
        ToastService.showError(
          context: context,
          message: 'Could not open file link.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.neutral50,
        appBar: AppBar(
          backgroundColor: AppColors.neutral50,
          elevation: 0,
          title: Text(
            'Academic',
            style: AppTypography.textTheme.headlineMedium?.copyWith(
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
                _loadData();
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.neutral200.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: TabBar(
                    labelColor: AppColors.neutral900,
                    unselectedLabelColor: AppColors.neutral500,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    dividerColor: Colors.transparent,
                    labelStyle: AppTypography.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: AppTypography.textTheme.labelMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    tabs: const [
                      Tab(text: 'Schedules'),
                      Tab(text: 'Exam Seats'),
                      Tab(text: 'Results'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildScheduleTab(),
                  _buildExamSeatsTab(),
                  _buildResultsTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildScheduleTab() {
    if (schedules.isEmpty) {
      return Center(
        child: Text(
          'No schedules posted yet.',
          style: AppTypography.textTheme.bodyMedium?.copyWith(
            color: AppColors.neutral500,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: schedules.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final s = schedules[index];
        return ScheduleCard(
          leftBorderColor: AppColors.primary500,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s['title'], style: AppTypography.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                '${s['department']} • Sem ${s['semester']} ${s['shift'] != null ? '• Shift ${s['shift']}' : ''} ${s['group'] != null ? '• Grp ${s['group']}' : ''}',
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: AppColors.neutral600,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _launchUrl(s['fileUrl']),
                icon: const Icon(FluentIcons.document_pdf_24_regular, size: 18),
                label: const Text('View Routine'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary600,
                  side: const BorderSide(color: AppColors.primary200),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExamSeatsTab() {
    if (examSeats.isEmpty) {
      return Center(
        child: Text(
          'No exam seats posted yet.',
          style: AppTypography.textTheme.bodyMedium?.copyWith(
            color: AppColors.neutral500,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: examSeats.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final s = examSeats[index];
        return StandardCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s['title'], style: AppTypography.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                '${s['department']} • Sem ${s['semester']} ${s['shift'] != null ? '• Shift ${s['shift']}' : ''} ${s['group'] != null ? '• Grp ${s['group']}' : ''}',
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: AppColors.neutral600,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  context.push('/exam-seat', extra: jsonEncode(s));
                },
                icon: const Icon(
                  FluentIcons.clipboard_letter_24_regular,
                  size: 18,
                ),
                label: const Text('View Seat Plan'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary600,
                  side: const BorderSide(color: AppColors.secondary200),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResultsTab() {
    if (results.isEmpty) {
      return Center(
        child: Text(
          'No results posted yet.',
          style: AppTypography.textTheme.bodyMedium?.copyWith(
            color: AppColors.neutral500,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final s = results[index];
        return StandardCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s['title'], style: AppTypography.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                '${s['department']} • Sem ${s['semester']} ${s['shift'] != null ? '• Shift ${s['shift']}' : ''} ${s['group'] != null ? '• Grp ${s['group']}' : ''}',
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: AppColors.neutral600,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _launchUrl(s['fileUrl']),
                icon: const Icon(
                  FluentIcons.hat_graduation_24_regular,
                  size: 18,
                ),
                label: const Text('View Result'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.success700,
                  side: const BorderSide(color: AppColors.success100),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
