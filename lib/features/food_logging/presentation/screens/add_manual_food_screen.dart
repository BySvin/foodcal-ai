import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/option_selector.dart';
import '../../../../routing/route_paths.dart';
import '../../domain/entities/food_log_entry.dart';
import '../providers/food_log_providers.dart';
import '../widgets/meal_section.dart';

class AddManualFoodScreen extends ConsumerStatefulWidget {
  const AddManualFoodScreen({super.key, required this.mealType, required this.date});

  final MealType mealType;
  final DateTime date;

  @override
  ConsumerState<AddManualFoodScreen> createState() => _AddManualFoodScreenState();
}

class _AddManualFoodScreenState extends ConsumerState<AddManualFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _servingSizeController = TextEditingController(text: '1');
  final _servingUnitController = TextEditingController(text: 'serving');
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  late MealType _mealType = widget.mealType;

  @override
  void dispose() {
    _nameController.dispose();
    _servingSizeController.dispose();
    _servingUnitController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final failure = await ref.read(foodLogControllerProvider.notifier).logFood(
          foodId: null,
          foodName: _nameController.text.trim(),
          servingSize: num.parse(_servingSizeController.text.trim()),
          servingUnit: _servingUnitController.text.trim(),
          quantity: 1,
          caloriesPerServing: num.parse(_caloriesController.text.trim()),
          proteinPerServing: num.tryParse(_proteinController.text.trim()) ?? 0,
          carbsPerServing: num.tryParse(_carbsController.text.trim()) ?? 0,
          fatPerServing: num.tryParse(_fatController.text.trim()) ?? 0,
          mealType: _mealType,
          loggedDate: widget.date,
          source: LogSource.manual,
        );

    if (!mounted) return;
    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
    } else {
      context.go(RoutePaths.log);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(foodLogControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Add food')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _nameController,
                  label: 'Food name',
                  autofocus: true,
                  validator: (v) => Validators.required(v, fieldName: 'Name'),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _servingSizeController,
                        label: 'Serving size',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => Validators.positiveNumber(v, fieldName: 'Serving size'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppTextField(
                        controller: _servingUnitController,
                        label: 'Unit (e.g. g, cup)',
                        validator: (v) => Validators.required(v, fieldName: 'Unit'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _caloriesController,
                  label: 'Calories',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => Validators.positiveNumber(v, fieldName: 'Calories'),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _proteinController,
                        label: 'Protein (g)',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppTextField(
                        controller: _carbsController,
                        label: 'Carbs (g)',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppTextField(
                        controller: _fatController,
                        label: 'Fat (g)',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Meal', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.sm),
                OptionSelector<MealType>(
                  selected: _mealType,
                  onSelected: (m) => setState(() => _mealType = m),
                  options: [
                    for (final type in MealType.values)
                      SelectorOption(value: type, label: mealTypeLabels[type]!),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(label: 'Add to log', isLoading: isLoading, onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
