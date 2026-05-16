import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/wallet.dart';
import '../services/firestore_services.dart';
import '../theme/app_theme.dart';
import '../widgets/kharcha_widgets.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _service = FirestoreServices();
  final _fmt = NumberFormat('#,##,###');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = AppColors.bgFor(isDark);
    final card = AppColors.surfaceFor(isDark);
    final border = AppColors.borderFor(isDark);
    final textPrimary = AppColors.textPrimaryFor(isDark);
    final textMuted = AppColors.textMutedFor(isDark);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Wallet Tracker',
            style: AppTextStyles.heading
                .copyWith(color: textPrimary, fontSize: 18)),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: AppColors.primary),
            onPressed: () => _showAddSheet(context, isDark, card, border,
                textPrimary, textMuted),
          ),
        ],
      ),
      body: StreamBuilder<List<Wallet>>(
        stream: _service.getWallets(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2));
          }
          final wallets = snap.data ?? [];
          if (wallets.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.account_balance_wallet_outlined,
              title: 'No wallets added',
              subtitle: 'Track cash, UPI, and bank balances',
              buttonLabel: 'Add Wallet',
              onButton: () => _showAddSheet(context, isDark, card,
                  border, textPrimary, textMuted),
            );
          }
          final totalBalance =
              wallets.fold(0.0, (s, w) => s + w.balance);
          return Column(
            children: [
              _TotalBalanceCard(
                  balance: totalBalance, isDark: isDark, fmt: _fmt),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  itemCount: wallets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _WalletTile(
                      wallet: wallets[i],
                      isDark: isDark,
                      fmt: _fmt,
                      onDelete: () => _service.deleteWallet(wallets[i].id)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddSheet(
    BuildContext context,
    bool isDark,
    Color card,
    Color border,
    Color textPrimary,
    Color textMuted,
  ) {
    final nameCtrl = TextEditingController();
    final balCtrl = TextEditingController();
    String type = 'Cash';
    final types = ['Cash', 'Bank', 'UPI', 'Card', 'Other'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: card,
      shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.sheetRadius),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: AppColors.borderFor(isDark),
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text('Add Wallet',
                  style: TextStyle(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              PremiumTextField(
                  controller: nameCtrl,
                  label: 'Wallet Name',
                  hint: 'e.g. SBI Savings'),
              const SizedBox(height: 12),
              PremiumTextField(
                  controller: balCtrl,
                  label: 'Opening Balance (₹)',
                  hint: '0',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: types
                    .map((t) => ChoiceChip(
                          label: Text(t),
                          selected: type == t,
                          onSelected: (_) => setSt(() => type = t),
                          selectedColor:
                              AppColors.primary.withValues(alpha: 0.20),
                          labelStyle: TextStyle(
                              color: type == t
                                  ? AppColors.primary
                                  : textMuted,
                              fontSize: 12),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Add Wallet',
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final bal = double.tryParse(balCtrl.text) ?? 0;
                  if (name.isEmpty) return;
                  final w = Wallet(
                    id: '',
                    name: name,
                    balance: bal,
                    type: type,
                    createdAt: DateTime.now(),
                  );
                  await _service.addWallet(w);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalBalanceCard extends StatelessWidget {
  final double balance;
  final bool isDark;
  final NumberFormat fmt;
  const _TotalBalanceCard(
      {required this.balance,
      required this.isDark,
      required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.20), width: 0.8),
      ),
      child: Column(
        children: [
          Text('Total Balance',
              style: TextStyle(
                  color: AppColors.textMutedFor(isDark), fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            '₹${fmt.format(balance.toInt())}',
            style: const TextStyle(
                color: AppColors.primary,
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: -1),
          ),
        ],
      ),
    );
  }
}

class _WalletTile extends StatelessWidget {
  final Wallet wallet;
  final bool isDark;
  final NumberFormat fmt;
  final VoidCallback onDelete;

  const _WalletTile({
    required this.wallet,
    required this.isDark,
    required this.fmt,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final card = AppColors.surfaceFor(isDark);
    final border = AppColors.borderFor(isDark);
    final textPrimary = AppColors.textPrimaryFor(isDark);
    final textMuted = AppColors.textMutedFor(isDark);

    return Dismissible(
      key: Key(wallet.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.danger),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: border, width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.account_balance_wallet_outlined,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(wallet.name,
                      style: TextStyle(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  Text(wallet.type,
                      style: TextStyle(color: textMuted, fontSize: 12)),
                ],
              ),
            ),
            Text(
              '₹${fmt.format(wallet.balance.toInt())}',
              style: TextStyle(
                  color: wallet.balance >= 0
                      ? AppColors.success
                      : AppColors.danger,
                  fontSize: 14,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
