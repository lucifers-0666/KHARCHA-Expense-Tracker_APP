import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/expense.dart';
import 'package:flutter_application_1/screens/expense_card.dart';
import 'package:flutter_application_1/services/firestore_services.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchAndFilterScreen extends StatefulWidget {
  const SearchAndFilterScreen({super.key});

  @override
  State<SearchAndFilterScreen> createState() => _SearchAndFilterScreenState();
}

class _SearchAndFilterScreenState extends State<SearchAndFilterScreen> {
  final _searchController = TextEditingController();
  final _service = FirestoreServices();

  List<Expense> _allExpenses = [];
  List<Expense> _filteredExpenses = [];
  List<String> _searchHistory = [];

  // Filter parameters
  DateTimeRange? _dateRange;
  double _minAmount = 0;
  double _maxAmount = 100000;
  Set<String> _selectedCategories = {};
  String _searchQuery = '';

  static const List<String> categories = [
    'Food',
    'Transport',
    'Shopping',
    'Entertainment',
    'Bills',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _loadExpenses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('search_history') ?? [];
    });
  }

  Future<void> _saveSearchQuery(String query) async {
    if (query.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    _searchHistory.remove(query);
    _searchHistory.insert(0, query);
    if (_searchHistory.length > 10) {
      _searchHistory = _searchHistory.sublist(0, 10);
    }
    await prefs.setStringList('search_history', _searchHistory);
  }

  Future<void> _clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
    setState(() {
      _searchHistory = [];
    });
  }

  void _loadExpenses() {
    _service.getAllExpenses().listen((expenses) {
      setState(() {
        _allExpenses = expenses;
        _applyFilters();
      });
    });
  }

  void _applyFilters() {
    List<Expense> filtered = List.from(_allExpenses);

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((expense) {
        return expense.title.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            expense.category.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply date range
    if (_dateRange != null) {
      filtered = filtered.where((expense) {
        return expense.date.isAfter(_dateRange!.start) &&
            expense.date.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Apply amount range
    filtered = filtered.where((expense) {
      return expense.amount >= _minAmount && expense.amount <= _maxAmount;
    }).toList();

    // Apply category filter
    if (_selectedCategories.isNotEmpty) {
      filtered = filtered.where((expense) {
        return _selectedCategories.contains(expense.category);
      }).toList();
    }

    setState(() {
      _filteredExpenses = filtered;
    });
  }

  void _search(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
    if (query.isNotEmpty) {
      _saveSearchQuery(query);
      _loadSearchHistory();
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _dateRange = null;
                            _minAmount = 0;
                            _maxAmount = 100000;
                            _selectedCategories.clear();
                          });
                          setState(() {
                            _dateRange = null;
                            _minAmount = 0;
                            _maxAmount = 100000;
                            _selectedCategories.clear();
                          });
                          _applyFilters();
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Date Range
                  const Text(
                    'Date Range',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final range = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                        initialDateRange: _dateRange,
                      );
                      if (range != null) {
                        setModalState(() => _dateRange = range);
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _dateRange == null
                          ? 'Select Date Range'
                          : '${DateFormat('dd MMM').format(_dateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_dateRange!.end)}',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Amount Range
                  const Text(
                    'Amount Range',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Min',
                            prefixText: '₹',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          controller: TextEditingController(
                            text: _minAmount.toStringAsFixed(0),
                          ),
                          onChanged: (value) {
                            setModalState(() {
                              _minAmount = double.tryParse(value) ?? 0;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Max',
                            prefixText: '₹',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          controller: TextEditingController(
                            text: _maxAmount.toStringAsFixed(0),
                          ),
                          onChanged: (value) {
                            setModalState(() {
                              _maxAmount = double.tryParse(value) ?? 100000;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Categories
                  const Text(
                    'Categories',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: categories.map((category) {
                      final isSelected = _selectedCategories.contains(category);
                      return FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            if (selected) {
                              _selectedCategories.add(category);
                            } else {
                              _selectedCategories.remove(category);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                      _applyFilters();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Apply Filters'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  int get _activeFiltersCount {
    int count = 0;
    if (_dateRange != null) count++;
    if (_minAmount > 0 || _maxAmount < 100000) count++;
    if (_selectedCategories.isNotEmpty) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search & Filter'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search expenses...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _search('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _search,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter chips bar
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Filter button
                        ActionChip(
                          avatar: Badge(
                            label: Text(_activeFiltersCount.toString()),
                            isLabelVisible: _activeFiltersCount > 0,
                            child: const Icon(Icons.filter_list, size: 18),
                          ),
                          label: const Text('Filters'),
                          onPressed: _showFilterDialog,
                        ),
                        const SizedBox(width: 8),

                        // Active filter chips
                        if (_dateRange != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Chip(
                              label: Text(
                                '${DateFormat('dd MMM').format(_dateRange!.start)} - ${DateFormat('dd MMM').format(_dateRange!.end)}',
                              ),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () {
                                setState(() => _dateRange = null);
                                _applyFilters();
                              },
                            ),
                          ),
                        if (_selectedCategories.isNotEmpty)
                          ..._selectedCategories.map(
                            (cat) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Chip(
                                label: Text(cat),
                                deleteIcon: const Icon(Icons.close, size: 18),
                                onDeleted: () {
                                  setState(
                                    () => _selectedCategories.remove(cat),
                                  );
                                  _applyFilters();
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Results
          Expanded(child: _buildResultsList()),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    if (_searchQuery.isEmpty && _activeFiltersCount == 0) {
      return _buildSearchHistory();
    }

    if (_filteredExpenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _dateRange = null;
                  _minAmount = 0;
                  _maxAmount = 100000;
                  _selectedCategories.clear();
                });
                _applyFilters();
              },
              child: const Text('Clear all filters'),
            ),
          ],
        ),
      );
    }

    final totalAmount = _filteredExpenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    return Column(
      children: [
        // Summary card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    _filteredExpenses.length.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Expenses',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              Container(width: 1, height: 40, color: Colors.white30),
              Column(
                children: [
                  Text(
                    '₹${NumberFormat('#,##,###').format(totalAmount)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Total',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Expense list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredExpenses.length,
            itemBuilder: (context, index) {
              return ExpenseCard(expense: _filteredExpenses[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchHistory() {
    if (_searchHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No search history',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Start searching to see your history',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Searches',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _clearSearchHistory,
                child: const Text('Clear All'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _searchHistory.length,
            itemBuilder: (context, index) {
              final query = _searchHistory[index];
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(query),
                trailing: IconButton(
                  icon: const Icon(Icons.north_west),
                  onPressed: () {
                    _searchController.text = query;
                    _search(query);
                  },
                ),
                onTap: () {
                  _searchController.text = query;
                  _search(query);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
