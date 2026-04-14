import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/sms_suggestion.dart';
import 'package:flutter_application_1/screens/add_expense.dart';
import 'package:flutter_application_1/services/sms_import_service.dart';
import 'package:flutter_application_1/services/sms_parser_service.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsImportScreen extends StatefulWidget {
  const SmsImportScreen({super.key});

  @override
  State<SmsImportScreen> createState() => _SmsImportScreenState();
}

class _SmsImportScreenState extends State<SmsImportScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final SmsImportService _importService = SmsImportService();

  bool _isLoading = true;
  bool _isImporting = false;
  // Default to denied; updated once we check the real status
  PermissionStatus _permissionStatus = PermissionStatus.denied;

  List<SmsSuggestion> _newSuggestions = [];
  List<SmsSuggestion> _imported = [];
  List<SmsSuggestion> _ignored  = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── init ──────────────────────────────────────────────────

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    _permissionStatus = await Permission.sms.status;
    if (_permissionStatus.isGranted) {
      await _scanSms();
    }
    await _refreshLists();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _requestPermission() async {
    final status = await Permission.sms.request();
    if (!mounted) return;
    setState(() => _permissionStatus = status);

    if (status.isGranted) {
      await _scanSms();
      await _refreshLists();
      if (!mounted) return;
      _showSnack('SMS access granted. Suggestions are ready.');
      return;
    }

    if (status.isPermanentlyDenied && mounted) {
      _showSnack(
        'Permission permanently denied. Open settings to enable SMS.',
        true,
      );
    }
  }

  Future<void> _scanSms() async {
    if (!mounted) return;
    setState(() => _isImporting = true);
    try {
      final inserted = await _importService.pullAndParseRecentSms();
      if (!mounted) return;
      _showSnack(
        'Imported $inserted new suggestion${inserted == 1 ? '' : 's'}.',
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to read SMS: $e', true);
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _refreshLists() async {
    final results = await Future.wait([
      _importService.getSuggestionsByStatus(SmsSuggestionStatus.newSuggestion),
      _importService.getSuggestionsByStatus(SmsSuggestionStatus.imported),
      _importService.getSuggestionsByStatus(SmsSuggestionStatus.ignored),
    ]);
    if (!mounted) return;
    setState(() {
      _newSuggestions = results[0];
      _imported       = results[1];
      _ignored        = results[2];
    });
  }

  Future<void> _confirmSuggestion(SmsSuggestion suggestion) async {
    try {
      await _importService.confirmAndCreateExpense(suggestion: suggestion);
      await _refreshLists();
      if (!mounted) return;
      _showSnack('Expense created from SMS suggestion.');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Could not confirm suggestion: $e', true);
    }
  }

  Future<void> _ignoreSuggestion(SmsSuggestion suggestion) async {
    await _importService.ignoreSuggestion(suggestion.id);
    await _refreshLists();
    if (!mounted) return;
    _showSnack('Suggestion moved to Ignored.');
  }

  Future<void> _openEditPrefill(SmsSuggestion suggestion) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Material(
              color: Theme.of(ctx).colorScheme.surface,
              child: AddExpenseScreen(
                onSave: () async {
                  await _importService.markAsImported(suggestion.id);
                  await _refreshLists();
                },
                initialTitle   : suggestion.parsedMerchant ?? 'SMS Import',
                initialAmount  : suggestion.parsedAmount,
                initialDate    : suggestion.parsedDate,
                initialCategory: 'Other',
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSnack(String message, [bool isError = false]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
      ),
    );
  }

  // ── build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Import'),
        actions: [
          if (_isImporting)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              onPressed: _permissionStatus.isGranted
                  ? () async {
                      await _scanSms();
                      await _refreshLists();
                    }
                  : null,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Suggestions',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'New (${_newSuggestions.length})'),
            Tab(text: 'Imported (${_imported.length})'),
            Tab(text: 'Ignored (${_ignored.length})'),
          ],
        ),
      ),
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
        child: _isLoading
            ? _buildShimmerList()
            : !_permissionStatus.isGranted
                ? _buildPermissionView()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(_newSuggestions, isNewTab: true),
                      _buildList(_imported),
                      _buildList(_ignored),
                    ],
                  ),
      ),
    );
  }

  // ── permission view ───────────────────────────────────────

  Widget _buildPermissionView() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.sms_rounded, color: AppColors.primary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'SMS access needed',
                        style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'KHARCHA reads only transactional SMS alerts '
                  '(bank/UPI/card debit) to suggest expenses. '
                  'We never auto-submit entries without your review.',
                  style: TextStyle(
                    color: AppColors.textSecondary, height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: _permissionStatus.isPermanentlyDenied
                      ? ElevatedButton.icon(
                          // openAppSettings is from permission_handler
                          onPressed: openAppSettings,
                          icon: const Icon(Icons.settings),
                          label: const Text('Open App Settings'),
                        )
                      : ElevatedButton.icon(
                          onPressed: _requestPermission,
                          icon: const Icon(Icons.lock_open_rounded),
                          label: const Text('Allow SMS Access'),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── shimmer loading list ──────────────────────────────────

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 14, width: 180, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Container(height: 14, width: 100, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Container(height: 12, width: double.infinity, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }

  // ── suggestion list ───────────────────────────────────────

  Widget _buildList(List<SmsSuggestion> suggestions, {bool isNewTab = false}) {
    if (suggestions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isNewTab ? Icons.inbox_rounded : Icons.check_circle_outline,
                size: 48,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 16),
              Text(
                isNewTab
                    ? 'No suggestions yet.\nTap ↻ to scan recent transactional SMS.'
                    : 'Nothing here yet.',
                style: const TextStyle(color: Colors.white, fontSize: 15),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshLists,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: suggestions.length,
        itemBuilder: (context, index) => _SuggestionCard(
          suggestion  : suggestions[index],
          threshold   : SmsParserService.defaultConfidenceThreshold,
          onConfirm   : isNewTab ? () => _confirmSuggestion(suggestions[index]) : null,
          onEdit      : isNewTab ? () => _openEditPrefill(suggestions[index])  : null,
          onIgnore    : isNewTab ? () => _ignoreSuggestion(suggestions[index])  : null,
        ),
      ),
    );
  }
}

// ── suggestion card ───────────────────────────────────────────────────────────

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.suggestion,
    required this.threshold,
    this.onConfirm,
    this.onEdit,
    this.onIgnore,
  });

  final SmsSuggestion suggestion;
  final double        threshold;
  final VoidCallback? onConfirm;
  final VoidCallback? onEdit;
  final VoidCallback? onIgnore;

  @override
  Widget build(BuildContext context) {
    final pct          = (suggestion.confidence * 100).toStringAsFixed(0);
    final lowConfidence= suggestion.confidence < threshold;
    final dateText     = suggestion.parsedDate == null
        ? 'Unknown date'
        : DateFormat('dd MMM yyyy, hh:mm a').format(suggestion.parsedDate!);

    return Container(
      margin   : const EdgeInsets.only(bottom: 12),
      padding  : const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── header row ──
          Row(
            children: [
              Expanded(
                child: Text(
                  suggestion.parsedMerchant ?? 'Unknown merchant',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                '\u20b9${(suggestion.parsedAmount ?? 0).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.calendar_today_outlined, label: dateText),
          _InfoRow(
            icon : Icons.verified_outlined,
            label: 'Confidence: $pct%',
            color: lowConfidence ? AppColors.warning : AppColors.income,
          ),
          if (suggestion.detectedAccount != null)
            _InfoRow(
              icon : Icons.account_balance_outlined,
              label: suggestion.detectedAccount!,
            ),
          if (lowConfidence)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 14, color: AppColors.warning),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Low confidence — review before confirming.',
                      style: TextStyle(
                        color: AppColors.warning, fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // ── action buttons ──
          if (onConfirm != null || onEdit != null || onIgnore != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (onConfirm != null)
                    ElevatedButton.icon(
                      onPressed: onConfirm,
                      icon : const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Confirm'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.income,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  if (onEdit != null)
                    OutlinedButton.icon(
                      onPressed: onEdit,
                      icon : const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  if (onIgnore != null)
                    TextButton.icon(
                      onPressed: onIgnore,
                      icon : const Icon(Icons.block_outlined, size: 16),
                      label: const Text('Ignore'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.expense,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, this.color});
  final IconData icon;
  final String   label;
  final Color?   color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: c),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
