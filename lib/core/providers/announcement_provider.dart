import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_connect_app/core/network/announcement_repository.dart';

final announcementsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  return ref.watch(announcementRepositoryProvider).fetchAnnouncements();
});
