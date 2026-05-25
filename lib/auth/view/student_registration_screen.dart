import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:campus_connect_app/core/theme/colors.dart';
import 'package:campus_connect_app/core/theme/typography.dart';
import 'package:campus_connect_app/core/network/auth_repository.dart';
import 'package:campus_connect_app/shared/widgets/buttons.dart';
import 'package:campus_connect_app/shared/widgets/inputs.dart';
import 'package:campus_connect_app/core/utils/toast_service.dart';

class StudentRegistrationScreen extends ConsumerStatefulWidget {
  const StudentRegistrationScreen({super.key});

  @override
  ConsumerState<StudentRegistrationScreen> createState() =>
      _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState
    extends ConsumerState<StudentRegistrationScreen> {
  int _currentStep = 0;
  final int _totalSteps = 3;
  bool _isLoading = false;

  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _boardRollController = TextEditingController();
  final _regNoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedDepartment;
  String? _selectedSemester;
  String? _selectedShift;
  String? _selectedGroup;

  final List<String> _departments = [
    'Computer Science and Technology',
    'Civil Technology',
    'Electrical Technology',
    'Electronics Technology',
    'Mechanical Technology',
  ];

  final List<String> _semesters = [
    '1st Semester',
    '2nd Semester',
    '3rd Semester',
    '4th Semester',
  ];
  final List<String> _shifts = ['1st Shift', '2nd Shift'];
  final List<String> _groups = ['Group A', 'Group B', 'Group C', 'None'];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _boardRollController.dispose();
    _regNoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegistration() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ToastService.showError(
        context: context,
        message: 'Passwords do not match!',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.register({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'role': 'STUDENT',
        'phone': _phoneController.text.trim(),
        'department': _selectedDepartment,
        'boardRoll': _boardRollController.text.trim(),
        'regNo': _regNoController.text.trim(),
        'semester': _selectedSemester,
        'shift': _selectedShift,
        'group': _selectedGroup,
      });

      if (mounted) {
        context.go('/register/status?status=success');
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(
          context: context,
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onNext() {
    if (_formKeys[_currentStep].currentState?.validate() != true) {
      return;
    }
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep += 1);
    } else {
      _submitRegistration();
    }
  }

  void _onBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    } else {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        backgroundColor: AppColors.neutral50,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            FluentIcons.arrow_left_24_regular,
            color: AppColors.neutral900,
          ),
          onPressed: _onBack,
        ),
        title: Text(
          'Student Registration',
          style: AppTypography.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _buildCurrentStepContent(),
            ),
          ),
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      decoration: const BoxDecoration(
        color: AppColors.neutral50,
        border: Border(
          bottom: BorderSide(color: AppColors.neutral200, width: 1),
        ),
      ),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isCompleted = index < _currentStep;
          final isActive = index == _currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isCompleted || isActive
                          ? AppColors.accentBlue
                          : AppColors.neutral200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < _totalSteps - 1) const SizedBox(width: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalStep();
      case 1:
        return _buildAcademicStep();
      case 2:
        return _buildAccountStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildPersonalStep() {
    return Form(
      key: _formKeys[0],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Personal Details',
            style: AppTypography.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please provide your basic information.',
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: AppColors.neutral500,
            ),
          ),
          const SizedBox(height: 24),
          const Text('Full Name *'),
          const SizedBox(height: 8),
          StandardInput(
            controller: _nameController,
            hintText: 'Enter your full name',
            prefixIcon: const Icon(FluentIcons.person_20_regular),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: 20),
          const Text('Phone Number *'),
          const SizedBox(height: 8),
          StandardInput(
            controller: _phoneController,
            hintText: 'Enter your phone number',
            prefixIcon: const Icon(FluentIcons.call_20_regular),
            keyboardType: TextInputType.phone,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Phone number is required'
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicStep() {
    return Form(
      key: _formKeys[1],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Academic Information',
            style: AppTypography.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          const Text('Board Roll Number *'),
          const SizedBox(height: 8),
          StandardInput(
            controller: _boardRollController,
            hintText: 'Enter your Board Roll Number',
            prefixIcon: const Icon(FluentIcons.badge_20_regular),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Board Roll is required'
                : null,
          ),
          const SizedBox(height: 20),
          const Text('Registration Number *'),
          const SizedBox(height: 8),
          StandardInput(
            controller: _regNoController,
            hintText: 'Enter your Registration Number',
            prefixIcon: const Icon(FluentIcons.document_text_20_regular),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Registration No is required'
                : null,
          ),
          const SizedBox(height: 20),
          const Text('Department *'),
          const SizedBox(height: 8),
          StandardDropdown<String>(
            hintText: 'Select Department',
            value: _selectedDepartment,
            items: _departments
                .map(
                  (dep) => DropdownMenuItem(
                    value: dep,
                    child: Text(dep, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedDepartment = value),
            prefixIcon: const Icon(FluentIcons.building_bank_20_regular),
          ),
          const SizedBox(height: 20),
          const Text('Semester *'),
          const SizedBox(height: 8),
          StandardDropdown<String>(
            hintText: 'Select Semester',
            value: _selectedSemester,
            items: _semesters
                .map(
                  (sem) => DropdownMenuItem(
                    value: sem,
                    child: Text(sem, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedSemester = value),
            prefixIcon: const Icon(FluentIcons.timer_20_regular),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Shift'),
                    const SizedBox(height: 8),
                    StandardDropdown<String>(
                      hintText: 'Shift',
                      value: _selectedShift,
                      items: _shifts
                          .map(
                            (shift) => DropdownMenuItem(
                              value: shift,
                              child: Text(
                                shift,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedShift = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Group'),
                    const SizedBox(height: 8),
                    StandardDropdown<String>(
                      hintText: 'Group',
                      value: _selectedGroup,
                      items: _groups
                          .map(
                            (group) => DropdownMenuItem(
                              value: group,
                              child: Text(
                                group,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedGroup = value),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountStep() {
    return Form(
      key: _formKeys[2],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Account Setup',
            style: AppTypography.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          const Text('Email Address *'),
          const SizedBox(height: 8),
          StandardInput(
            controller: _emailController,
            hintText: 'Enter email address',
            prefixIcon: const Icon(FluentIcons.mail_20_regular),
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 20),
          const Text('Password *'),
          const SizedBox(height: 8),
          StandardInput(
            controller: _passwordController,
            hintText: 'Create a password',
            obscureText: true,
            prefixIcon: const Icon(FluentIcons.lock_closed_20_regular),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 20),
          const Text('Confirm Password *'),
          const SizedBox(height: 8),
          StandardInput(
            controller: _confirmPasswordController,
            hintText: 'Confirm your password',
            obscureText: true,
            prefixIcon: const Icon(FluentIcons.lock_closed_20_regular),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your password';
              if (v != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.neutral0,
        border: const Border(
          top: BorderSide(color: AppColors.neutral200, width: 1),
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? Center(
                child: Lottie.asset(
                  'assets/animations/loading.json',
                  width: 80,
                  height: 80,
                ),
              )
            : PrimaryButton(
                text: _currentStep == _totalSteps - 1
                    ? 'Submit Registration'
                    : 'Next Step',
                onPressed: _onNext,
              ),
      ),
    );
  }
}
