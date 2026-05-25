import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_connect_app/core/network/auth_repository.dart';

final userProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.getProfile();
});
