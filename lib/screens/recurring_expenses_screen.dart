import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/models/recurring_expense.dart';
import 'package:flutter_application_1/services/firestore_services.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:intl/intl.dart';

class RecurringExpensesScreen extends StatefulWidget {
  const RecurringExpensesScreen({super.key});

  @override
  State<RecurringExpensesScreen> createState() =>
      _RecurringExpensesScreenState();
}

class _RecurringExpensesScreenState extends State<RecurringExpensesScreen> {
  final _service = FirestoreServices();

  final List<String> _categories = const [
    'Food',
    'Transport',
    'Shopping',
    'Entertainment',
    'Bills',
    'Other',
  ];

  final List<String> _frequencies = const [
    'daily',
    'weekly',
    'monthly',
    'yearly',
  ];

  Future<void> _showRecurringForm({RecurringExpense? recurring}) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: recurring?.title ?? '');
    final amountController = TextEditingController(
      text: recurring == null ? '' : recurring.amount.toStringAsFixed(2),
    );

    String selectedCategory = recurring?.category ?? _categories.first;
    String selectedFrequency = recurring?.frequency ?? 'monthly';
    DateTime selectedNextDueDate = recurring?.nextDueDate ?? DateTime.now();
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedNextDueDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );

              if (picked != null) {
                setModalState(() {
                  selectedNextDueDate = picked;
                });
              }
            }

            Future<void> save() async {
              if (!formKey.currentState!.validate()) return;

              setModalState(() => isSaving = true);
              try {
                final recurringExpense = RecurringExpense(
                  id: recurring?.id ?? '',
                  title: titleController.text.trim(),
                  amount: double.parse(amountController.text.trim()),
                  category: selectedCategory,
                  date: recurring?.date ?? DateTime.now(),
                  frequency: selectedFrequency,
                  nextDueDate: selectedNextDueDate,
                  isActive: recurring?.isActive ?? true,
                  lastCreatedDate: recurring?.lastCreatedDate,
                  lastReminderDate: recurring?.lastReminderDate,
                );

                if (recurring == null) {
                  await _service.addRecurringExpense(recurringExpense);
                } else {
                  await _service.updateRecurringExpense(recurringExpense);
                }

                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      recurring == null
                          ? 'Recurring expense created'
                          : 'Recurring expense updated',
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to save recurring expense: $e'),
                    backgroundColor: AppColors.danger,
                  ),
                );
              } finally {
                setModalState(() => isSaving = false);
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recurring == null
                            ? 'Add Recurring Expense'
                            : 'Edit Recurring Expense',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Amount (Rs)',
                          prefixIcon: Icon(Icons.currency_rupee_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Amount is required';
                          }
                          final amount = double.tryParse(value.trim());
                          if (amount == null || amount <= 0) {
                            return 'Enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_rounded),
                        ),
                        items: _categories
                            .map(
                              (c) => DropdownMenuItem<String>(
                                value: c,
                                child: Text(c),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setModalState(() => selectedCategory = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedFrequency,
                        decoration: const InputDecoration(
                          labelText: 'Frequency',
                          prefixIcon: Icon(Icons.repeat_rounded),
                        ),
                        items: _frequencies
                            .map(
                              (f) => DropdownMenuItem<String>(
                                value: f,
                                child: Text(
                                  '${f[0].toUpperCase()}${f.substring(1)}',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setModalState(() => selectedFrequency = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F3F7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_month,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Next due: ${DateFormat('dd MMM yyyy').format(selectedNextDueDate)}',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isSaving
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Save',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    titleController.dispose();
    amountController.dispose();
  }

  Future<void> _deleteRecurringExpense(String id) async {
    try {
      await _service.deleteRecurringExpense(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recurring expense deleted'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete recurring expense: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryDark,
              AppColors.primary,
              AppColors.accent,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Recurring Expenses',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 14),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: StreamBuilder<List<RecurringExpense>>(
                    stream: _service.getRecurringExpenses(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'Failed to load recurring expenses: ${snapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      final items = snapshot.data ?? [];
                      if (items.isEmpty) {
                        return const Center(
                          child: Text(
                            'No recurring expenses yet. Tap + to add one.',
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final recurring = items[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            recurring.title,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${recurring.category} | ${recurring.frequency.toUpperCase()}',
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Next due: ${DateFormat('dd MMM yyyy').format(recurring.nextDueDate)}',
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      'Rs ${recurring.amount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Switch(
                                      value: recurring.isActive,
                                      activeThumbColor: AppColors.accent,
                                      onChanged: (value) async {
                                        await _service.updateRecurringStatus(
                                          recurring.id,
                                          value,
                                        );
                                      },
                                    ),
                                    const Text('Active'),
                                    const Spacer(),
                                    IconButton(
                                      onPressed: () => _showRecurringForm(
                                        recurring: recurring,
                                      ),
                                      icon: const Icon(
                                        Icons.edit,
                                        color: AppColors.info,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          _deleteRecurringExpense(recurring.id),
                                      icon: const Icon(
                                        Icons.delete,
                                        color: AppColors.danger,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRecurringForm(),
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Recurring',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
