import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/calorie_calculator.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/option_selector.dart';
import '../providers/onboarding_providers.dart';
import '../widgets/onboarding_step_scaffold.dart';

const _stepCount = 6;

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String? _stepError;
  bool _initializedName = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() {
      _currentStep = step;
      _stepError = null;
    });
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _next(OnboardingFormState form) {
    final notifier = ref.read(onboardingControllerProvider.notifier);

    switch (_currentStep) {
      case 0:
        if (_nameController.text.trim().isEmpty) {
          setState(() => _stepError = 'Please enter your name');
          return;
        }
        notifier.setName(_nameController.text.trim());
      case 1:
        final age = int.tryParse(_ageController.text.trim());
        if (age == null || age < 13 || age > 120) {
          setState(() => _stepError = 'Enter a valid age between 13 and 120');
          return;
        }
        if (form.gender == null) {
          setState(() => _stepError = 'Please select a gender');
          return;
        }
        notifier.setAge(age);
      case 2:
        final height = double.tryParse(_heightController.text.trim());
        final weight = double.tryParse(_weightController.text.trim());
        if (height == null || height < 100 || height > 250) {
          setState(() => _stepError = 'Enter a valid height in cm (100-250)');
          return;
        }
        if (weight == null || weight < 30 || weight > 300) {
          setState(() => _stepError = 'Enter a valid weight in kg (30-300)');
          return;
        }
        notifier.setHeightCm(height);
        notifier.setWeightKg(weight);
      case 3:
        if (form.activityLevel == null) {
          setState(() => _stepError = 'Please select an activity level');
          return;
        }
      case 4:
        if (form.goal == null) {
          setState(() => _stepError = 'Please select a goal');
          return;
        }
    }

    if (_currentStep < _stepCount - 1) {
      _goToStep(_currentStep + 1);
    }
  }

  Future<void> _finish() async {
    final error = await ref.read(onboardingControllerProvider.notifier).submit();
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
    // On success, the router redirect (watching appUserProvider) takes the
    // user to /dashboard automatically once Firestore confirms the write.
  }

  @override
  Widget build(BuildContext context) {
    final formAsync = ref.watch(onboardingControllerProvider);

    return formAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: ErrorView(
          message: 'Could not load your onboarding progress.',
          onRetry: () => ref.invalidate(onboardingControllerProvider),
        ),
      ),
      data: (form) {
        if (!_initializedName) {
          _nameController.text = form.name;
          _initializedName = true;
        }

        return PopScope(
          canPop: false,
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildNameStep(form),
              _buildAgeGenderStep(form),
              _buildHeightWeightStep(form),
              _buildActivityStep(form),
              _buildGoalStep(form),
              _buildSummaryStep(form, formAsync.isLoading),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNameStep(OnboardingFormState form) {
    return OnboardingStepScaffold(
      stepIndex: 0,
      stepCount: _stepCount,
      title: "What's your name?",
      subtitle: "We'll use this to personalize your experience.",
      onNext: () => _next(form),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(controller: _nameController, label: 'Name', autofocus: true),
          if (_stepError != null) _buildError(),
        ],
      ),
    );
  }

  Widget _buildAgeGenderStep(OnboardingFormState form) {
    return OnboardingStepScaffold(
      stepIndex: 1,
      stepCount: _stepCount,
      title: 'Tell us about you',
      onBack: () => _goToStep(0),
      onNext: () => _next(form),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _ageController,
            label: 'Age',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Gender', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          OptionSelector<Gender>(
            selected: form.gender,
            onSelected: (g) => ref.read(onboardingControllerProvider.notifier).setGender(g),
            options: const [
              SelectorOption(value: Gender.female, label: 'Female'),
              SelectorOption(value: Gender.male, label: 'Male'),
              SelectorOption(value: Gender.other, label: 'Other'),
            ],
          ),
          if (_stepError != null) _buildError(),
        ],
      ),
    );
  }

  Widget _buildHeightWeightStep(OnboardingFormState form) {
    return OnboardingStepScaffold(
      stepIndex: 2,
      stepCount: _stepCount,
      title: 'Height & weight',
      onBack: () => _goToStep(1),
      onNext: () => _next(form),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _heightController,
            label: 'Height (cm)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _weightController,
            label: 'Current weight (kg)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          if (_stepError != null) _buildError(),
        ],
      ),
    );
  }

  Widget _buildActivityStep(OnboardingFormState form) {
    return OnboardingStepScaffold(
      stepIndex: 3,
      stepCount: _stepCount,
      title: 'How active are you?',
      onBack: () => _goToStep(2),
      onNext: () => _next(form),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OptionSelector<ActivityLevel>(
            selected: form.activityLevel,
            onSelected: (a) =>
                ref.read(onboardingControllerProvider.notifier).setActivityLevel(a),
            options: const [
              SelectorOption(
                value: ActivityLevel.sedentary,
                label: 'Sedentary',
                description: 'Little or no exercise',
              ),
              SelectorOption(
                value: ActivityLevel.light,
                label: 'Lightly active',
                description: 'Exercise 1-3 days/week',
              ),
              SelectorOption(
                value: ActivityLevel.moderate,
                label: 'Moderately active',
                description: 'Exercise 3-5 days/week',
              ),
              SelectorOption(
                value: ActivityLevel.active,
                label: 'Active',
                description: 'Hard exercise 6-7 days/week',
              ),
              SelectorOption(
                value: ActivityLevel.veryActive,
                label: 'Very active',
                description: 'Very hard exercise & physical job',
              ),
            ],
          ),
          if (_stepError != null) _buildError(),
        ],
      ),
    );
  }

  Widget _buildGoalStep(OnboardingFormState form) {
    return OnboardingStepScaffold(
      stepIndex: 4,
      stepCount: _stepCount,
      title: "What's your goal?",
      onBack: () => _goToStep(3),
      onNext: () => _next(form),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OptionSelector<Goal>(
            selected: form.goal,
            onSelected: (g) => ref.read(onboardingControllerProvider.notifier).setGoal(g),
            options: const [
              SelectorOption(value: Goal.lose, label: 'Lose weight'),
              SelectorOption(value: Goal.maintain, label: 'Maintain weight'),
              SelectorOption(value: Goal.gain, label: 'Gain weight'),
            ],
          ),
          if (_stepError != null) _buildError(),
        ],
      ),
    );
  }

  Widget _buildSummaryStep(OnboardingFormState form, bool isSubmitting) {
    final targets = form.computedTargets;
    final theme = Theme.of(context);

    return OnboardingStepScaffold(
      stepIndex: 5,
      stepCount: _stepCount,
      title: 'Your daily targets',
      subtitle: 'You can fine-tune these later in your profile.',
      onBack: () => _goToStep(4),
      onNext: _finish,
      nextLabel: 'Start tracking',
      isNextLoading: isSubmitting,
      child: targets == null
          ? const Text('Please complete the previous steps.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SummaryRow(label: 'Daily calories', value: '${targets.dailyCalorieTarget} kcal'),
                _SummaryRow(label: 'Protein', value: '${targets.proteinG} g'),
                _SummaryRow(label: 'Carbs', value: '${targets.carbsG} g'),
                _SummaryRow(label: 'Fat', value: '${targets.fatG} g'),
                _SummaryRow(label: 'Water goal', value: '${targets.dailyWaterTargetMl} ml'),
                if (targets.wasClamped) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'We adjusted your target to a safe range.',
                    style: theme.textTheme.labelLarge,
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Text(
        _stepError!,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyLarge),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
