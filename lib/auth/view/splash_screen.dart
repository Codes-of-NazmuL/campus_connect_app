// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_connect_app/core/theme/colors.dart';
import 'package:campus_connect_app/core/theme/typography.dart';
import 'package:lottie/lottie.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_connect_app/core/network/auth_repository.dart';
import 'package:campus_connect_app/core/network/callkit_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Skip the 1-second animation when the user accepted a call —
    // every millisecond counts when a real-time call is waiting.
    if (startupPendingCall == null) {
      await Future.delayed(const Duration(seconds: 1));
    }

    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token != null && token.isNotEmpty) {
        // Attempt to fetch profile to verify token and get role
        final authRepo = ref.read(authRepositoryProvider);
        final profile = await authRepo.getProfile();

        if (!mounted) return;

        if (profile['role'] == 'TEACHER') {
          context.go('/teacher/home');
        } else {
          context.go('/student/home');
        }

        return;
      }
    } catch (e) {
      // Token invalid or network error, fallback to onboarding
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
    }

    if (mounted) {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/Slider_two.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(
              0xFF0F172A,
            ).withValues(alpha: 0.85), // Dark overlay for text readability
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Professional Logo Marker
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Image.asset(
                    'assets/images/tpi.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Tangail Polytechnic',
                  style: AppTypography.textTheme.displayLarge?.copyWith(
                    color: AppColors.neutral0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 48),
                Lottie.asset(
                  'assets/animations/loading.json',
                  width: 100,
                  height: 100,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
