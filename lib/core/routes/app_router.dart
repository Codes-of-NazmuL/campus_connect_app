import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/view/splash_screen.dart';
import '../../auth/view/onboarding_screen.dart';
import '../../auth/view/login_screen.dart';
import '../../auth/view/student_registration_screen.dart';
import '../../auth/view/teacher_registration_screen.dart';
import '../../auth/view/registration_status_screen.dart';
import '../../student/view/student_main_container.dart';
import '../../teacher/view/teacher_main_container.dart';
import '../../chat/view/chat_detail_screen.dart';
import '../../chat/view/new_chat_screen.dart';
import '../../student/view/exam_seat_detail_screen.dart';
import '../../shared/screens/coming_soon_screen.dart';
import '../../shared/screens/schedule_screen.dart';
import '../../teacher/view/create_announcement_screen.dart';
import 'dart:convert';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register/student',
        builder: (context, state) => const StudentRegistrationScreen(),
      ),
      GoRoute(
        path: '/register/teacher',
        builder: (context, state) => const TeacherRegistrationScreen(),
      ),
      GoRoute(
        path: '/register/status',
        builder: (context, state) {
          final status = state.uri.queryParameters['status'] ?? 'pending';
          return RegistrationStatusScreen(status: status);
        },
      ),
      GoRoute(
        path: '/student/home',
        builder: (context, state) => const StudentMainContainer(),
      ),
      GoRoute(
        path: '/teacher/home',
        builder: (context, state) => const TeacherMainContainer(),
      ),
      GoRoute(
        path: '/chat/new',
        builder: (context, state) => const NewChatScreen(),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? 'Unknown';
          final chatName = state.uri.queryParameters['chatName'] ?? id;
          final isGroup = state.uri.queryParameters['isGroup'] == 'true';
          final isOnline = state.uri.queryParameters['isOnline'] == 'true';
          return ChatDetailScreen(
            roomId: id,
            chatName: chatName,
            isGroup: isGroup,
            isOnline: isOnline,
          );
        },
      ),
      GoRoute(
        path: '/exam-seat',
        builder: (context, state) {
          final extra = state.extra as String?;
          final data = extra != null ? jsonDecode(extra) : <String, dynamic>{};
          return ExamSeatDetailScreen(seatData: data);
        },
      ),
      GoRoute(
        path: '/schedule',
        builder: (context, state) => const ScheduleScreen(),
      ),
      GoRoute(
        path: '/notify',
        builder: (context, state) => const CreateAnnouncementScreen(),
      ),
      GoRoute(
        path: '/coming-soon',
        builder: (context, state) {
          final feature = state.uri.queryParameters['feature'] ?? 'Feature';
          return ComingSoonScreen(featureName: feature);
        },
      ),
    ],
  );
});
