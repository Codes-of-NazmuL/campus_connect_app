import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_connect_app/core/theme/colors.dart';
import 'package:campus_connect_app/core/theme/typography.dart';
import 'package:campus_connect_app/core/network/auth_repository.dart';

// Create a standalone students provider in this file
final studentsListProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  // ignore: deprecated_member_use
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.getAllStudents();
});

class TeacherStudentsScreen extends ConsumerStatefulWidget {
  const TeacherStudentsScreen({super.key});

  @override
  ConsumerState<TeacherStudentsScreen> createState() =>
      _TeacherStudentsScreenState();
}

class _TeacherStudentsScreenState extends ConsumerState<TeacherStudentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsListProvider);

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Students',
          style: AppTypography.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) =>
                      setState(() => _searchQuery = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search by name or roll...',
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
              Container(height: 1, color: AppColors.neutral200),
            ],
          ),
        ),
      ),
      body: studentsAsync.when(
        data: (students) {
          final filtered = students.where((s) {
            if (_searchQuery.isEmpty) return true;
            final name = (s['name'] ?? '').toString().toLowerCase();
            final roll = (s['boardRoll'] ?? '').toString().toLowerCase();
            return name.contains(_searchQuery) || roll.contains(_searchQuery);
          }).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    FluentIcons.person_question_mark_24_regular,
                    size: 64,
                    color: AppColors.neutral300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty
                        ? 'No students found'
                        : 'No results for "$_searchQuery"',
                    style: AppTypography.textTheme.titleMedium?.copyWith(
                      color: AppColors.neutral500,
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(studentsListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: filtered.length,
              separatorBuilder: (ctx, idx) => const Divider(
                height: 1,
                indent: 88,
                color: AppColors.neutral100,
              ),
              itemBuilder: (context, index) =>
                  _buildStudentTile(filtered[index]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Failed to load students',
                style: AppTypography.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(studentsListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentTile(Map<String, dynamic> student) {
    final dept = student['department'] ?? 'N/A';
    final sem = student['semester'] ?? '';
    final shift = student['shift'] ?? '';
    final subtitle = [dept, sem, shift].where((s) => s.isNotEmpty).join(' • ');

    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.secondary100,
              child: Text(
                (student['name'] as String? ?? 'S')
                    .substring(0, 1)
                    .toUpperCase(),
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  color: AppColors.secondary700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student['name'] ?? 'Unknown',
                    style: AppTypography.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: AppColors.neutral500,
                    ),
                  ),
                ],
              ),
            ),
            if (student['boardRoll'] != null)
              Text(
                'Roll: ${student['boardRoll']}',
                style: AppTypography.textTheme.labelSmall?.copyWith(
                  color: AppColors.neutral400,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
