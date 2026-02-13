import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/models/group.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:intl/intl.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

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
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('groups')
                        .where(
                          'members',
                          arrayContains: {'userId': _auth.currentUser?.uid},
                        )
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _buildEmptyState();
                      }

                      final groups = snapshot.data!.docs
                          .map((doc) => Group.fromFirestore(doc))
                          .toList();

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: groups.length,
                        itemBuilder: (context, index) {
                          return _buildGroupCard(groups[index]);
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
        onPressed: _showCreateGroupDialog,
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.group_add),
        label: const Text(
          'Create Group',
          style: TextStyle(fontWeight: FontWeight.bold),
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
            'Split Expenses',
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.groups_rounded,
              size: 80,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No groups yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a group to split expenses with friends',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(Group group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () => _openGroupDetails(group),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        group.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${group.members.length} members',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              if (group.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  group.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final emailController = TextEditingController();
    final emails = <String>[];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Create New Group',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Group Name',
                      prefixIcon: const Icon(Icons.group),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    'Add Members',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: 'Member Email',
                            hintText: 'email@example.com',
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          if (emailController.text.isNotEmpty &&
                              emailController.text.contains('@')) {
                            setDialogState(() {
                              emails.add(emailController.text.trim());
                              emailController.clear();
                            });
                          }
                        },
                        icon: const Icon(Icons.add_circle),
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  if (emails.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: emails.map((email) {
                        return Chip(
                          label: Text(email),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () {
                            setDialogState(() => emails.remove(email));
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (nameController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a group name'),
                                ),
                              );
                              return;
                            }

                            await _createGroup(
                              nameController.text,
                              descController.text,
                              emails,
                            );
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          child: const Text(
                            'Create',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createGroup(
    String name,
    String description,
    List<String> memberEmails,
  ) async {
    try {
      final currentUser = _auth.currentUser!;
      final members = <GroupMember>[
        GroupMember(
          userId: currentUser.uid,
          name: currentUser.displayName ?? 'You',
          email: currentUser.email ?? '',
          isAdmin: true,
          joinedAt: DateTime.now(),
        ),
      ];

      // Add other members (in real app, you'd look them up in users collection)
      for (var email in memberEmails) {
        members.add(
          GroupMember(
            userId: email, // Using email as ID for simplicity
            name: email.split('@')[0],
            email: email,
            isAdmin: false,
            joinedAt: DateTime.now(),
          ),
        );
      }

      final group = Group(
        id: '',
        name: name,
        description: description,
        members: members,
        createdBy: currentUser.uid,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('groups').add(group.toFirestore());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _openGroupDetails(Group group) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GroupDetailsScreen(group: group)),
    );
  }
}

class GroupDetailsScreen extends StatefulWidget {
  final Group group;

  const GroupDetailsScreen({super.key, required this.group});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        backgroundColor: AppColors.primary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Balances'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildExpensesTab(), _buildBalancesTab()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseDialog,
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add),
        label: const Text('Split Expense'),
      ),
    );
  }

  Widget _buildExpensesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('split_expenses')
          .where('groupId', isEqualTo: widget.group.id)
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No expenses yet'));
        }

        final expenses = snapshot.data!.docs
            .map((doc) => SplitExpense.fromFirestore(doc))
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            final payer = widget.group.members.firstWhere(
              (m) => m.userId == expense.paidBy,
            );

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: expense.isSettled
                      ? AppColors.success
                      : AppColors.primary,
                  child: Text(
                    expense.category[0],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  expense.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Paid by ${payer.name} • ${DateFormat('MMM d').format(expense.date)}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${NumberFormat('#,##,###').format(expense.totalAmount)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (expense.isSettled)
                      const Text(
                        'Settled',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBalancesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('split_expenses')
          .where('groupId', isEqualTo: widget.group.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No transactions yet'));
        }

        final expenses = snapshot.data!.docs
            .map((doc) => SplitExpense.fromFirestore(doc))
            .toList();

        final settlements = SplitExpense.calculateDebts(expenses);

        if (settlements.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 80, color: AppColors.success),
                SizedBox(height: 16),
                Text(
                  'All settled up!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: settlements.entries.expand((entry) {
            final debtor = widget.group.members.firstWhere(
              (m) => m.userId == entry.key,
            );

            return entry.value.entries.map((settlement) {
              final creditor = widget.group.members.firstWhere(
                (m) => m.userId == settlement.key,
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.warning,
                    child: Icon(Icons.arrow_forward, color: Colors.white),
                  ),
                  title: Text(
                    '${debtor.name} owes ${creditor.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: Text(
                    '₹${NumberFormat('#,##,###').format(settlement.value)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              );
            });
          }).toList(),
        );
      },
    );
  }

  void _showAddExpenseDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    String payer = currentUserId;
    SplitType splitType = SplitType.equal;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Add Split Expense',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
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
                      labelText: 'Total Amount',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: payer,
                    decoration: InputDecoration(
                      labelText: 'Paid By',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: widget.group.members.map((member) {
                      return DropdownMenuItem(
                        value: member.userId,
                        child: Text(member.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() => payer = value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<SplitType>(
                    initialValue: splitType,
                    decoration: InputDecoration(
                      labelText: 'Split Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: SplitType.equal,
                        child: Text('Split Equally'),
                      ),
                      DropdownMenuItem(
                        value: SplitType.custom,
                        child: Text('Custom Amounts'),
                      ),
                      DropdownMenuItem(
                        value: SplitType.percentage,
                        child: Text('By Percentage'),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() => splitType = value!);
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () async {
                            await _addSplitExpense(
                              titleController.text,
                              double.tryParse(amountController.text) ?? 0,
                              payer,
                              splitType,
                            );
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          child: const Text(
                            'Add',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addSplitExpense(
    String title,
    double amount,
    String paidBy,
    SplitType splitType,
  ) async {
    if (title.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    try {
      // Calculate splits
      final Map<String, double> splits = {};
      final settledBy = <String, bool>{};

      if (splitType == SplitType.equal) {
        final splitAmount = amount / widget.group.members.length;
        for (var member in widget.group.members) {
          splits[member.userId] = splitAmount;
          settledBy[member.userId] = member.userId == paidBy;
        }
      }

      final expense = SplitExpense(
        id: '',
        groupId: widget.group.id,
        title: title,
        totalAmount: amount,
        paidBy: paidBy,
        date: DateTime.now(),
        category: 'Food',
        splitType: splitType,
        splits: splits,
        settledBy: settledBy,
      );

      await _firestore.collection('split_expenses').add(expense.toFirestore());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense added!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
