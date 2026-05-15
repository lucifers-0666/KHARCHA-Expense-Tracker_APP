import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/budget.dart';
import 'package:flutter_application_1/models/expense.dart';
import 'package:flutter_application_1/services/firestore_services.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:intl/intl.dart';

class FinancialHealthScreen extends StatefulWidget {
  const FinancialHealthScreen({super.key});

  @override
  State<FinancialHealthScreen> createState() => _FinancialHealthScreenState();
}

class _FinancialHealthScreenState extends State<FinancialHealthScreen>
    with SingleTickerProviderStateMixin {
  final _service = FirestoreServices();
  late AnimationController _animationController;
  late Animation<double> _animation;

  int _healthScore = 0;
  Map<String, double> _scoreBreakdown = {};
  List<String> _insights = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _calculateHealthScore();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _calculateHealthScore() async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month);
      final lastMonth = DateTime(now.year, now.month - 1);

      // Get data
      final budget = await _service.fetchBudgetForMonth(now.year, now.month);
      final expenses = await _service.getExpensesByMonth(currentMonth).first;
      final lastMonthExpenses = await _service
          .getExpensesByMonth(lastMonth)
          .first;
      final income = await _service.getTotalIncomeByMonth(currentMonth).first;

      // Calculate score components
      final budgetScore = _calculateBudgetAdherence(expenses, budget);
      final savingsScore = _calculateSavingsRate(income, expenses);
      final consistencyScore = _calculateConsistency(
        expenses,
        lastMonthExpenses,
      );
      final categoryScore = _calculateCategoryBalance(expenses);

      // Weighted total (out of 100)
      final totalScore =
          (budgetScore * 0.35 +
                  savingsScore * 0.30 +
                  consistencyScore * 0.20 +
                  categoryScore * 0.15)
              .round();

      _scoreBreakdown = {
        'Budget Adherence': budgetScore,
        'Savings Rate': savingsScore,
        'Expense Consistency': consistencyScore,
        'Category Balance': categoryScore,
      };

      _insights = _generateInsights(
        expenses,
        lastMonthExpenses,
        income,
        budget,
        totalScore,
      );

      setState(() {
        _healthScore = totalScore;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  double _calculateBudgetAdherence(List<Expense> expenses, Budget? budget) {
    if (budget == null || budget.monthlyLimit <= 0) return 50.0;

    final totalSpent = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final ratio = totalSpent / budget.monthlyLimit;

    if (ratio <= 0.75) return 100.0;
    if (ratio <= 0.90) return 80.0;
    if (ratio <= 1.0) return 60.0;
    if (ratio <= 1.1) return 40.0;
    if (ratio <= 1.25) return 20.0;
    return 0.0;
  }

  double _calculateSavingsRate(double income, List<Expense> expenses) {
    if (income <= 0) return 0.0;

    final totalSpent = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final savingsRate = ((income - totalSpent) / income) * 100;

    if (savingsRate >= 30) return 100.0;
    if (savingsRate >= 20) return 80.0;
    if (savingsRate >= 10) return 60.0;
    if (savingsRate >= 0) return 40.0;
    if (savingsRate >= -10) return 20.0;
    return 0.0;
  }

  double _calculateConsistency(List<Expense> current, List<Expense> previous) {
    if (previous.isEmpty) return 75.0;

    final currentTotal = current.fold<double>(0, (sum, e) => sum + e.amount);
    final previousTotal = previous.fold<double>(0, (sum, e) => sum + e.amount);

    if (previousTotal == 0) return 75.0;

    final change = ((currentTotal - previousTotal).abs() / previousTotal) * 100;

    if (change <= 10) return 100.0;
    if (change <= 20) return 80.0;
    if (change <= 30) return 60.0;
    if (change <= 50) return 40.0;
    return 20.0;
  }

  double _calculateCategoryBalance(List<Expense> expenses) {
    if (expenses.isEmpty) return 75.0;

    final categoryTotals = <String, double>{};
    final total = expenses.fold<double>(0, (sum, e) {
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
      return sum + e.amount;
    });

    // Check if spending is too concentrated in one category
    final maxCategoryPercent = categoryTotals.values
        .map((v) => (v / total) * 100)
        .reduce((a, b) => a > b ? a : b);

    if (maxCategoryPercent <= 40) return 100.0;
    if (maxCategoryPercent <= 50) return 80.0;
    if (maxCategoryPercent <= 60) return 60.0;
    if (maxCategoryPercent <= 70) return 40.0;
    return 20.0;
  }

  List<String> _generateInsights(
    List<Expense> expenses,
    List<Expense> lastMonthExpenses,
    double income,
    Budget? budget,
    int score,
  ) {
    final insights = <String>[];

    // Overall assessment
    if (score >= 80) {
      insights.add('🎉 Excellent! Your financial health is outstanding!');
    } else if (score >= 60) {
      insights.add('💪 Good job! You\'re managing your finances well.');
    } else if (score >= 40) {
      insights.add('⚡ Fair. There\'s room for improvement.');
    } else {
      insights.add('⚠️ Your financial health needs attention.');
    }

    // Spending comparison
    if (lastMonthExpenses.isNotEmpty) {
      final currentTotal = expenses.fold<double>(0, (sum, e) => sum + e.amount);
      final lastTotal = lastMonthExpenses.fold<double>(
        0,
        (sum, e) => sum + e.amount,
      );
      final change = ((currentTotal - lastTotal) / lastTotal * 100).abs();

      if (currentTotal > lastTotal) {
        insights.add(
          '📈 You spent ${change.toStringAsFixed(1)}% more than last month.',
        );
      } else if (currentTotal < lastTotal) {
        insights.add(
          '📉 Great! You spent ${change.toStringAsFixed(1)}% less than last month.',
        );
      }
    }

    // Budget adherence
    if (budget != null && budget.monthlyLimit > 0) {
      final spent = expenses.fold<double>(0, (sum, e) => sum + e.amount);
      final remaining = budget.monthlyLimit - spent;

      if (remaining > 0) {
        insights.add(
          '💰 You have ₹${NumberFormat('#,##,###').format(remaining)} left in your budget.',
        );
      } else {
        insights.add(
          '🚨 You\'ve exceeded your budget by ₹${NumberFormat('#,##,###').format(remaining.abs())}.',
        );
      }
    }

    // Category analysis
    if (expenses.isNotEmpty) {
      final categoryTotals = <String, double>{};
      for (var expense in expenses) {
        categoryTotals[expense.category] =
            (categoryTotals[expense.category] ?? 0) + expense.amount;
      }

      final topCategory = categoryTotals.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );

      insights.add(
        '🏷️ Top spending category: ${topCategory.key} (₹${NumberFormat('#,##,###').format(topCategory.value)})',
      );
    }

    // Savings rate
    if (income > 0) {
      final spent = expenses.fold<double>(0, (sum, e) => sum + e.amount);
      final savingsRate = ((income - spent) / income * 100);

      if (savingsRate >= 20) {
        insights.add(
          '✨ Excellent savings rate of ${savingsRate.toStringAsFixed(1)}%!',
        );
      } else if (savingsRate >= 10) {
        insights.add(
          '💡 Consider increasing your savings rate from ${savingsRate.toStringAsFixed(1)}%.',
        );
      } else if (savingsRate < 0) {
        insights.add(
          '⚠️ You\'re spending more than you earn. Review your expenses.',
        );
      }
    }

    // Improvement suggestions
    if (score < 80) {
      insights.add(
        '💡 Tip: Set up category budgets to better track your spending.',
      );
    }
    if (score < 60) {
      insights.add(
        '📝 Suggestion: Review your recurring expenses and cancel unused subscriptions.',
      );
    }

    return insights;
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
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildScoreGauge(),
                            Container(
                              margin: const EdgeInsets.only(top: 16),
                              decoration: const BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(30),
                                  topRight: Radius.circular(30),
                                ),
                              ),
                              child: Column(
                                children: [
                                  _buildScoreBreakdown(),
                                  _buildInsights(),
                                  _buildAchievements(),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 8),
          const Text(
            'Financial Health',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _calculateHealthScore,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreGauge() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            size: const Size(200, 200),
            painter: _ScoreGaugePainter(
              score: (_healthScore * _animation.value).toInt(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScoreBreakdown() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Score Breakdown',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ..._scoreBreakdown.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key, style: const TextStyle(fontSize: 14)),
                      Text(
                        '${entry.value.toInt()}/100',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: entry.value / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      entry.value >= 80
                          ? AppColors.success
                          : entry.value >= 60
                          ? Colors.orange
                          : AppColors.danger,
                    ),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildInsights() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                'Insights & Suggestions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._insights.map((insight) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ', style: TextStyle(fontSize: 20)),
                  Expanded(
                    child: Text(
                      insight,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAchievements() {
    final achievements = <Map<String, dynamic>>[];

    if (_healthScore >= 80) {
      achievements.add({
        'icon': Icons.emoji_events,
        'title': 'Health Master',
        'desc': 'Excellent financial health!',
        'color': Colors.amber,
      });
    }
    if (_scoreBreakdown['Budget Adherence'] != null &&
        _scoreBreakdown['Budget Adherence']! >= 90) {
      achievements.add({
        'icon': Icons.account_balance_wallet,
        'title': 'Budget Ninja',
        'desc': 'Staying within budget',
        'color': AppColors.success,
      });
    }
    if (_scoreBreakdown['Savings Rate'] != null &&
        _scoreBreakdown['Savings Rate']! >= 80) {
      achievements.add({
        'icon': Icons.savings,
        'title': 'Savings Star',
        'desc': 'Great savings rate!',
        'color': AppColors.info,
      });
    }

    if (achievements.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.military_tech, color: Colors.purple),
              SizedBox(width: 8),
              Text(
                'Achievements Unlocked',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: achievements.map((achievement) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (achievement['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      achievement['icon'] as IconData,
                      color: achievement['color'] as Color,
                      size: 32,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement['title'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      achievement['desc'] as String,
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ScoreGaugePainter extends CustomPainter {
  final int score;

  _ScoreGaugePainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    // Background arc
    final backgroundPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      pi * 0.75,
      pi * 1.5,
      false,
      backgroundPaint,
    );

    // Score arc
    final scoreAngle = pi * 1.5 * (score / 100);
    final gradient = SweepGradient(
      startAngle: pi * 0.75,
      endAngle: pi * 0.75 + scoreAngle,
      colors: [
        Colors.red,
        Colors.orange,
        Colors.yellow,
        Colors.lightGreen,
        Colors.green,
      ],
    );

    final scorePaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      pi * 0.75,
      scoreAngle,
      false,
      scorePaint,
    );

    // Score text
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$score',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const TextSpan(
            text: '\n/100',
            style: TextStyle(fontSize: 18, color: Colors.white70),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    // Rating label
    String rating = '';
    if (score >= 80)
      rating = 'Excellent';
    else if (score >= 60)
      rating = 'Good';
    else if (score >= 40)
      rating = 'Fair';
    else
      rating = 'Needs Work';

    final ratingPainter = TextPainter(
      text: TextSpan(
        text: rating,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    );

    ratingPainter.layout();
    ratingPainter.paint(
      canvas,
      Offset(center.dx - ratingPainter.width / 2, center.dy + 40),
    );
  }

  @override
  bool shouldRepaint(_ScoreGaugePainter oldDelegate) {
    return oldDelegate.score != score;
  }
}
