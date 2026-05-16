enum ReportGrade { aPlus, a, b, c, d }

extension ReportGradeExt on ReportGrade {
  String get label {
    switch (this) {
      case ReportGrade.aPlus: return 'A+';
      case ReportGrade.a:     return 'A';
      case ReportGrade.b:     return 'B';
      case ReportGrade.c:     return 'C';
      case ReportGrade.d:     return 'D';
    }
  }

  String get tagline {
    switch (this) {
      case ReportGrade.aPlus: return 'Outstanding! You are a finance pro.';
      case ReportGrade.a:     return 'Excellent month. Keep it up!';
      case ReportGrade.b:     return 'Good work. A few areas to improve.';
      case ReportGrade.c:     return 'Average. Let\'s work on your habits.';
      case ReportGrade.d:     return 'Needs attention. Small steps matter.';
    }
  }
}

class FinancialReportCard {
  final int month;
  final int year;
  final ReportGrade grade;
  final double score; // 0–100
  final double budgetAdherence; // 0–100
  final double savingsRate; // 0–100
  final double expenseGrowth; // %
  final double debtRatio; // 0–100 (lower=better)
  final double consistency; // 0–100
  final List<String> strengths;
  final List<String> warnings;
  final List<String> suggestions;

  FinancialReportCard({
    required this.month,
    required this.year,
    required this.grade,
    required this.score,
    required this.budgetAdherence,
    required this.savingsRate,
    required this.expenseGrowth,
    required this.debtRatio,
    required this.consistency,
    required this.strengths,
    required this.warnings,
    required this.suggestions,
  });
}
