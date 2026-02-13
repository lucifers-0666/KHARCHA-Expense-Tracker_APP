import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/expense.dart';
import 'package:flutter_application_1/models/income.dart';
import 'package:flutter_application_1/services/firestore_services.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class ExportReportsScreen extends StatefulWidget {
  const ExportReportsScreen({super.key});

  @override
  State<ExportReportsScreen> createState() => _ExportReportsScreenState();
}

class _ExportReportsScreenState extends State<ExportReportsScreen> {
  final _service = FirestoreServices();
  DateTimeRange? _dateRange;
  String _reportType = 'summary'; //  summary, detailed, category
  bool _isExporting = false;

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
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildDateRangeSelector(),
                      const SizedBox(height: 24),
                      _buildReportTypeSelector(),
                      const SizedBox(height: 32),
                      _buildExportOptions(),
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
            'Export & Reports',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Date Range',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickDateButton('This Month', () {
                  final now = DateTime.now();
                  setState(() {
                    _dateRange = DateTimeRange(
                      start: DateTime(now.year, now.month, 1),
                      end: DateTime(now.year, now.month + 1, 0),
                    );
                  });
                }),
                _buildQuickDateButton('Last Month', () {
                  final now = DateTime.now();
                  final lastMonth = DateTime(now.year, now.month - 1);
                  setState(() {
                    _dateRange = DateTimeRange(
                      start: DateTime(lastMonth.year, lastMonth.month, 1),
                      end: DateTime(lastMonth.year, lastMonth.month + 1, 0),
                    );
                  });
                }),
                _buildQuickDateButton('Last 3 Months', () {
                  final now = DateTime.now();
                  setState(() {
                    _dateRange = DateTimeRange(
                      start: DateTime(now.year, now.month - 3, 1),
                      end: now,
                    );
                  });
                }),
                _buildQuickDateButton('This Year', () {
                  final now = DateTime.now();
                  setState(() {
                    _dateRange = DateTimeRange(
                      start: DateTime(now.year, 1, 1),
                      end: now,
                    );
                  });
                }),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                  initialDateRange: _dateRange,
                );
                if (range != null) {
                  setState(() => _dateRange = range);
                }
              },
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _dateRange == null
                    ? 'Select Custom Range'
                    : '${DateFormat('dd MMM yyyy').format(_dateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_dateRange!.end)}',
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDateButton(String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(label),
    );
  }

  Widget _buildReportTypeSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const <ButtonSegment<String>>[
                ButtonSegment<String>(
                  value: 'summary',
                  label: Text('Summary'),
                  tooltip: 'Overview with totals and charts',
                ),
                ButtonSegment<String>(
                  value: 'detailed',
                  label: Text('Detailed'),
                  tooltip: 'All expenses with full details',
                ),
                ButtonSegment<String>(
                  value: 'category',
                  label: Text('Category'),
                  tooltip: 'Breakdown by category',
                ),
              ],
              selected: <String>{_reportType},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() => _reportType = newSelection.first);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOptions() {
    return Column(
      children: [
        _buildExportButton(
          icon: Icons.picture_as_pdf,
          label: 'Export as PDF',
          color: Colors.red,
          onPressed: _isExporting ? null : _exportPDF,
        ),
        const SizedBox(height: 12),
        _buildExportButton(
          icon: Icons.table_chart,
          label: 'Export as CSV',
          color: Colors.green,
          onPressed: _isExporting ? null : _exportCSV,
        ),
      ],
    );
  }

  Widget _buildExportButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: _isExporting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _exportPDF() async {
    if (_dateRange == null) {
      _showSnackBar('Please select a date range', isError: true);
      return;
    }

    setState(() => _isExporting = true);

    try {
      final expenses = await _getExpensesInRange();
      final incomes = await _getIncomesInRange();

      final pdf = await _generatePDF(expenses, incomes);
      final file = await _savePDF(pdf);

      await Share.shareXFiles([XFile(file.path)], text: 'Expense Report');

      _showSnackBar('PDF exported successfully!');
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportCSV() async {
    if (_dateRange == null) {
      _showSnackBar('Please select a date range', isError: true);
      return;
    }

    setState(() => _isExporting = true);

    try {
      final expenses = await _getExpensesInRange();
      final incomes = await _getIncomesInRange();

      final file = await _generateCSV(expenses, incomes);

      await Share.shareXFiles([XFile(file.path)], text: 'Expense Report');

      _showSnackBar('CSV exported successfully!');
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<List<Expense>> _getExpensesInRange() async {
    final allExpenses = await _service.getAllExpenses().first;
    return allExpenses.where((expense) {
      return expense.date.isAfter(_dateRange!.start) &&
          expense.date.isBefore(_dateRange!.end.add(const Duration(days: 1)));
    }).toList();
  }

  Future<List<Income>> _getIncomesInRange() async {
    final allIncomes = await _service.getAllIncome().first;
    return allIncomes.where((income) {
      return income.date.isAfter(_dateRange!.start) &&
          income.date.isBefore(_dateRange!.end.add(const Duration(days: 1)));
    }).toList();
  }

  Future<pw.Document> _generatePDF(
    List<Expense> expenses,
    List<Income> incomes,
  ) async {
    final pdf = pw.Document();

    final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final totalIncome = incomes.fold<double>(0, (sum, i) => sum + i.amount);
    final netCashFlow = totalIncome - totalExpenses;

    // Category totals
    final Map<String, double> categoryTotals = {};
    for (var expense in expenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'KHARCHA',
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Expense Report',
                  style: const pw.TextStyle(fontSize: 20),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  '${DateFormat('dd MMM yyyy').format(_dateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_dateRange!.end)}',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Summary Section
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _pdfSummaryItem(
                      'Total Income',
                      totalIncome,
                      PdfColors.green,
                    ),
                    _pdfSummaryItem(
                      'Total Expenses',
                      totalExpenses,
                      PdfColors.red,
                    ),
                    _pdfSummaryItem(
                      'Net Cash Flow',
                      netCashFlow,
                      netCashFlow >= 0 ? PdfColors.green : PdfColors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Category Breakdown
          if (_reportType == 'summary' || _reportType == 'category') ...[
            pw.Header(level: 1, child: pw.Text('Category Breakdown')),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _pdfTableCell('Category', isHeader: true),
                    _pdfTableCell('Amount', isHeader: true),
                    _pdfTableCell('Percentage', isHeader: true),
                  ],
                ),
                ...categoryTotals.entries.map((entry) {
                  final percentage = totalExpenses > 0
                      ? (entry.value / totalExpenses * 100)
                      : 0.0;
                  return pw.TableRow(
                    children: [
                      _pdfTableCell(entry.key),
                      _pdfTableCell(
                        '₹${NumberFormat('#,##,###').format(entry.value)}',
                      ),
                      _pdfTableCell('${percentage.toStringAsFixed(1)}%'),
                    ],
                  );
                }).toList(),
              ],
            ),
            pw.SizedBox(height: 20),
          ],

          // Detailed Expenses
          if (_reportType == 'detailed') ...[
            pw.Header(level: 1, child: pw.Text('Detailed Expenses')),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _pdfTableCell('Date', isHeader: true),
                    _pdfTableCell('Title', isHeader: true),
                    _pdfTableCell('Category', isHeader: true),
                    _pdfTableCell('Amount', isHeader: true),
                  ],
                ),
                ...expenses.map((expense) {
                  return pw.TableRow(
                    children: [
                      _pdfTableCell(DateFormat('dd MMM').format(expense.date)),
                      _pdfTableCell(expense.title),
                      _pdfTableCell(expense.category),
                      _pdfTableCell(
                        '₹${NumberFormat('#,##,###').format(expense.amount)}',
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ],

          // Footer
          pw.SizedBox(height: 30),
          pw.Divider(),
          pw.Text(
            'Generated on ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _pdfSummaryItem(String label, double value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '₹${NumberFormat('#,##,###').format(value)}',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  pw.Widget _pdfTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  Future<File> _savePDF(pw.Document pdf) async {
    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/kharcha_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
    );
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<File> _generateCSV(
    List<Expense> expenses,
    List<Income> incomes,
  ) async {
    List<List<dynamic>> rows = [];

    // Expenses section
    rows.add(['EXPENSES']);
    rows.add(['Date', 'Title', 'Category', 'Amount']);
    for (var expense in expenses) {
      rows.add([
        DateFormat('dd/MM/yyyy').format(expense.date),
        expense.title,
        expense.category,
        expense.amount,
      ]);
    }
    rows.add([]);

    // Income section
    rows.add(['INCOME']);
    rows.add(['Date', 'Source', 'Category', 'Amount', 'Description']);
    for (var income in incomes) {
      rows.add([
        DateFormat('dd/MM/yyyy').format(income.date),
        income.source,
        income.category,
        income.amount,
        income.description,
      ]);
    }
    rows.add([]);

    // Summary
    final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final totalIncome = incomes.fold<double>(0, (sum, i) => sum + i.amount);
    rows.add(['SUMMARY']);
    rows.add(['Total Income', totalIncome]);
    rows.add(['Total Expenses', totalExpenses]);
    rows.add(['Net Cash Flow', totalIncome - totalExpenses]);

    String csv = const ListToCsvConverter().convert(rows);

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/kharcha_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv',
    );
    await file.writeAsString(csv);
    return file;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
      ),
    );
  }
}
