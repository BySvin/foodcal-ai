import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/calorie_calculator.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/option_selector.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/profile_providers.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  Gender? _gender;
  ActivityLevel? _activityLevel;
  Goal? _goal;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ageController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
  }

  void _initializeFrom(AppUser appUser) {
    if (_initialized) return;
    _nameController.text = appUser.displayName;
    _ageController.text = appUser.age?.toString() ?? '';
    _heightController.text = appUser.heightCm?.toString() ?? '';
    _weightController.text = appUser.currentWeightKg?.toString() ?? '';
    _gender = appUser.gender;
    _activityLevel = appUser.activityLevel;
    _goal = appUser.goal;
    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _submit(AppUser currentAppUser) async {
    if (!_formKey.currentState!.validate()) return;
    if (_gender == null || _activityLevel == null || _goal == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please complete every field.')));
      return;
    }

    final age = int.parse(_ageController.text.trim());
    final heightCm = double.parse(_heightController.text.trim());
    final weightKg = double.parse(_weightController.text.trim());

    final newTargets = CalorieCalculator.calculateTargets(
      gender: _gender!,
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      activityLevel: _activityLevel!,
      goal: _goal!,
    );

    final oldTarget = currentAppUser.dailyCalorieTarget;
    final targetChanged = oldTarget != null && oldTarget != newTargets.dailyCalorieTarget;

    if (targetChanged) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Update your daily target?'),
          content: Text(
            'Your daily calorie target will change from $oldTarget to '
            '${newTargets.dailyCalorieTarget} kcal based on these changes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Update'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final failure = await ref.read(profileControllerProvider.notifier).updateProfile(
          displayName: _nameController.text.trim(),
          age: age,
          gender: _gender!,
          heightCm: heightCm,
          weightKg: weightKg,
          activityLevel: _activityLevel!,
          goal: _goal!,
        );

    if (!mounted) return;
    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appUserAsync = ref.watch(appUserProvider);
    final isLoading = ref.watch(profileControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SafeArea(
        child: appUserAsync.when(
          loading: () => const LoadingView(),
          error: (error, _) => Center(child: Text('$error')),
          data: (appUser) {
            if (appUser == null) return const LoadingView();
            _initializeFrom(appUser);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(controller: _nameController, label: 'Name'),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _ageController,
                            label: 'Age',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppTextField(
                            controller: _heightController,
                            label: 'Height (cm)',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppTextField(
                            controller: _weightController,
                            label: 'Weight (kg)',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Gender', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: AppSpacing.sm),
                    OptionSelector<Gender>(
                      selected: _gender,
                      onSelected: (g) => setState(() => _gender = g),
                      options: const [
                        SelectorOption(value: Gender.female, label: 'Female'),
                        SelectorOption(value: Gender.male, label: 'Male'),
                        SelectorOption(value: Gender.other, label: 'Other'),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Activity level', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: AppSpacing.sm),
                    OptionSelector<ActivityLevel>(
                      selected: _activityLevel,
                      onSelected: (a) => setState(() => _activityLevel = a),
                      options: const [
                        SelectorOption(value: ActivityLevel.sedentary, label: 'Sedentary'),
                        SelectorOption(value: ActivityLevel.light, label: 'Lightly active'),
                        SelectorOption(value: ActivityLevel.moderate, label: 'Moderately active'),
                        SelectorOption(value: ActivityLevel.active, label: 'Active'),
                        SelectorOption(value: ActivityLevel.veryActive, label: 'Very active'),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Goal', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: AppSpacing.sm),
                    OptionSelector<Goal>(
                      selected: _goal,
                      onSelected: (g) => setState(() => _goal = g),
                      options: const [
                        SelectorOption(value: Goal.lose, label: 'Lose weight'),
                        SelectorOption(value: Goal.maintain, label: 'Maintain weight'),
                        SelectorOption(value: Goal.gain, label: 'Gain weight'),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      label: 'Save',
                      isLoading: isLoading,
                      onPressed: () => _submit(appUser),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
