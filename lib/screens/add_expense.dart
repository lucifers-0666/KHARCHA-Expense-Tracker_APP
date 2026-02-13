import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/models/expense.dart';
import 'package:flutter_application_1/services/firestore_services.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:intl/intl.dart';

class AddExpenseScreen extends StatefulWidget {
  final VoidCallback onSave;
  final Expense? expenseToEdit;

  const AddExpenseScreen({Key? key, required this.onSave, this.expenseToEdit})
    : super(key: key);

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen>
    with SingleTickerProviderStateMixin {
  final _formkey = GlobalKey<FormState>();
  final _service = FirestoreServices();

  late TextEditingController titleController;
  late TextEditingController amountController;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String selectedCategory = 'Food';
  DateTime selectedDate = DateTime.now();

  final List<Map<String, dynamic>> categories = [
    {
      'name': 'Food',
      'icon': Icons.restaurant_rounded,
      'color': const Color(0xFFEF6C57),
    },
    {
      'name': 'Transport',
      'icon': Icons.directions_car_rounded,
      'color': const Color(0xFF4C7BF4),
    },
    {
      'name': 'Shopping',
      'icon': Icons.shopping_bag_rounded,
      'color': const Color(0xFFF1A24A),
    },
    {
      'name': 'Entertainment',
      'icon': Icons.movie_rounded,
      'color': const Color(0xFF7A6FF0),
    },
    {
      'name': 'Bills',
      'icon': Icons.receipt_long_rounded,
      'color': const Color(0xFF2BB3A6),
    },
    {
      'name': 'Other',
      'icon': Icons.more_horiz_rounded,
      'color': const Color(0xFF7B8794),
    },
  ];

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();

    if (widget.expenseToEdit != null) {
      titleController = TextEditingController(
        text: widget.expenseToEdit!.title,
      );
      amountController = TextEditingController(
        text: widget.expenseToEdit!.amount.toString(),
      );
      selectedCategory = widget.expenseToEdit!.category;
      selectedDate = widget.expenseToEdit!.date;
    } else {
      titleController = TextEditingController();
      amountController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    titleController.dispose();
    amountController.dispose();
    super.dispose();
  }

  void openDatePicker() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  void saveExpense() async {
    if (!_formkey.currentState!.validate()) return;

    try {
      final expense = Expense(
        id: widget.expenseToEdit?.id ?? '',
        title: titleController.text.trim(),
        amount: double.parse(amountController.text.trim()),
        category: selectedCategory,
        date: selectedDate,
      );

      if (widget.expenseToEdit != null) {
        await _service.updateExpense(expense);
      } else {
        await _service.addExpense(expense);
      }
      widget.onSave();
      if (!mounted) return;
      Navigator.popUntil(
        context,
        (route) => route.settings.name == '/home' || route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving expense: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expenseToEdit != null;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Form(
            key: _formkey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isEditing ? 'Edit Expense' : 'Add New Expense',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      hintText: 'Enter expense title',
                      prefixIcon: const Icon(
                        Icons.title_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      hintText: 'Enter amount',
                      prefixIcon: const Icon(
                        Icons.currency_rupee_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = selectedCategory == category['name'];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedCategory = category['name'];
                            });
                          },
                          child: Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? category['color'].withOpacity(0.2)
                                  : const Color(0xFFF1F3F7),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: isSelected
                                    ? category['color']
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  category['icon'],
                                  size: 32,
                                  color: category['color'],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  category['name'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: openDatePicker,
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F7),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('MMM dd, yyyy').format(selectedDate),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: saveExpense,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            isEditing ? 'Update' : 'Save',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
