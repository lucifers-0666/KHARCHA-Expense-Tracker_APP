import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/budget.dart';
import 'package:flutter_application_1/services/firestore_services.dart';
import 'package:flutter_application_1/theme/app_theme.dart';

class BudgetSetupScreen extends StatefulWidget {
  const BudgetSetupScreen({super.key});

  @override
  _BudgetSetupScreenState createState() => _BudgetSetupScreenState();
}

class _BudgetSetupScreenState extends State<BudgetSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _monthlyLimitController = TextEditingController();
  final FirestoreServices _firestoreServices = FirestoreServices();

  Map<String, double> _categoryLimits = {
    'Food': 0,
    'Transport': 0,
    'Shopping': 0,
    'Entertainment': 0,
    'Bills': 0,
    'Other': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadBudget();
  }

  Future<void> _loadBudget() async {
    final now = DateTime.now();
    final budget = await _firestoreServices.fetchBudgetForMonth(
      now.year,
      now.month,
    );
    if (budget != null) {
      _monthlyLimitController.text = budget.monthlyLimit.toString();
      setState(() {
        _categoryLimits = budget.categoryLimits;
      });
    }
  }

  @override
  void dispose() {
    _monthlyLimitController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final monthlyLimit = double.tryParse(_monthlyLimitController.text) ?? 0.0;

      final budget = Budget(
        id: '', // Firestore will generate it
        monthlyLimit: monthlyLimit,
        categoryLimits: _categoryLimits,
        month: now.month,
        year: now.year,
      );

      await _firestoreServices.saveBudget(budget);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Budget saved successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the errors in red.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Your Budget'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Monthly Budget',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _monthlyLimitController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Overall Monthly Limit',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a monthly limit.';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Category Budgets',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ..._categoryLimits.keys.map((category) {
                return _buildCategorySlider(category);
              }).toList(),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveBudget,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Save Budget',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySlider(String category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$category: \$${_categoryLimits[category]!.toStringAsFixed(2)}'),
        Slider(
          value: _categoryLimits[category]!,
          min: 0,
          max: double.tryParse(_monthlyLimitController.text) ?? 0,
          divisions: 100,
          label: _categoryLimits[category]!.toStringAsFixed(2),
          activeColor: AppColors.primary,
          inactiveColor: AppColors.primary.withValues(alpha: 0.3),
          onChanged: (value) {
            setState(() {
              _categoryLimits[category] = value;
            });
          },
        ),
      ],
    );
  }
}
