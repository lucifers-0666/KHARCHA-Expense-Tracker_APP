# Contributing to KHARCHA 🚀

Thank you for considering contributing to KHARCHA! We welcome contributions from everyone. This document provides guidelines and instructions for contributing to our project.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Ways to Contribute](#ways-to-contribute)
- [Development Setup](#development-setup)
- [Branch Naming Conventions](#branch-naming-conventions)
- [Commit Message Format](#commit-message-format)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Testing Requirements](#testing-requirements)
- [Documentation](#documentation)
- [Review Process](#review-process)

---

## 💼 Code of Conduct

We are committed to providing a welcoming and inspiring community for all. Please read and adhere to our [Code of Conduct](CODE_OF_CONDUCT.md).

### Our Pledge

In the interest of fostering an open and welcoming environment, we as contributors and maintainers pledge to make participation in our project and our community a harassment-free experience for everyone.

---

## 🎯 Ways to Contribute

### 🐛 Report Bugs

- Check if the bug has already been reported in [Issues](https://github.com/lucifers-0666/KHARCHA-Expense-Tracker_APP/issues)
- If not, create a new issue using the **Bug Report** template
- Provide clear steps to reproduce, expected behavior, and actual behavior
- Include device info, app version, and screenshots

### 💡 Suggest Features

- Check if the feature has been discussed in [Discussions](https://github.com/lucifers-0666/KHARCHA-Expense-Tracker_APP/discussions)
- Create a new discussion with the **Feature Request** template
- Explain the problem it solves and how it benefits users
- Provide use case examples

### 🔧 Submit Code

- Fix bugs, implement features, or improve performance
- All code changes must go through pull requests
- Each PR should address a single concern
- Large changes should be discussed in an issue first

### 📖 Improve Documentation

- Fix typos, clarify instructions, add examples
- Improve README, API docs, or code comments
- Add missing documentation for features

### 🌍 Translate

- Help translate KHARCHA to more languages
- Contribute translations for UI strings
- Help translate documentation

---

## 🛠️ Development Setup

### Prerequisites

- Flutter SDK 3.10.7 or higher
- Dart 3.0 or higher
- Android Studio or VS Code with Flutter extension
- Git

### Setup Steps

1. **Fork the repository**
   ```bash
   # Click "Fork" on GitHub
   ```

2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR_USERNAME/KHARCHA-Expense-Tracker_APP.git
   cd KHARCHA-Expense-Tracker_APP
   ```

3. **Add upstream remote**
   ```bash
   git remote add upstream https://github.com/lucifers-0666/KHARCHA-Expense-Tracker_APP.git
   ```

4. **Install dependencies**
   ```bash
   flutter pub get
   ```

5. **Configure Firebase** (for development)
   ```bash
   flutterfire configure
   ```

6. **Verify setup**
   ```bash
   flutter doctor -v
   flutter test
   ```

---

## 🌿 Branch Naming Conventions

Use clear, descriptive branch names:

```
feature/<feature-name>       # New features
bugfix/<issue-number>        # Bug fixes
hotfix/<critical-fix>        # Critical fixes for production
refactor/<component>         # Code refactoring
docs/<topic>                 # Documentation updates
test/<test-type>             # Test additions
chore/<task>                 # Build, dependencies, maintenance
```

### Examples

```bash
git checkout -b feature/recurring-expense-reminders
git checkout -b bugfix/123-chart-rendering-crash
git checkout -b hotfix/authentication-token-expired
git checkout -b refactor/expense-provider-optimization
git checkout -b docs/firebase-setup-guide
git checkout -b test/add-budget-widget-tests
```

---

## 💬 Commit Message Format

We follow **Conventional Commits** specification for clarity and automated changelog generation.

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation only changes
- `style`: Changes that don't affect code meaning (formatting, missing semicolons, etc)
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `perf`: Code change that improves performance
- `test`: Adding missing tests or correcting existing tests
- `chore`: Changes to build process, dependencies, etc

### Subject

- Use imperative mood ("add", not "added" or "adds")
- Don't capitalize first letter
- No period (.) at the end
- Limit to 50 characters
- Clear, specific, and meaningful

### Body (Optional)

- Explain what and why, not how
- Wrap at 72 characters
- Separate from subject with blank line
- Use bullet points for multiple points

### Footer (Optional)

- Reference issue: `Closes #123`
- Breaking changes: `BREAKING CHANGE: description`

### Examples

```
feat(expense): add OCR scanning for receipts

Implement optical character recognition to automatically
extract amount and category from receipt photos. Reduces
manual entry time by 80%.

- Uses ML Vision Firebase service
- Fallback to manual entry if OCR fails
- Cache scanned receipts for offline access

Closes #456
```

```
fix(auth): resolve Firebase token expiration crash

Fixed issue where app crashed when Firebase auth token
expired. Now properly refreshes token and re-authenticates.

Fixes #789
```

```
docs(setup): add macOS build instructions

Added comprehensive guide for building on M1/M2 Macs
including CocoaPods setup and architecture considerations.
```

---

## 📤 Pull Request Process

### Before Creating a PR

1. **Update your fork**
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Create feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Code your feature or fix
   - Add/update tests
   - Update documentation
   - Lint your code

4. **Test thoroughly**
   ```bash
   flutter clean
   flutter pub get
   flutter analyze
   flutter test --coverage
   flutter run
   ```

5. **Commit changes**
   ```bash
   git add .
   git commit -m "feat(scope): your clear message"
   ```

### Creating the PR

1. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create Pull Request on GitHub**
   - Use the provided pull request template
   - Write a clear, descriptive title
   - Link related issues using `Closes #issue-number`
   - Provide context and screenshots if applicable

### PR Checklist

Your PR should include:

- ✅ Clear description of changes
- ✅ Related issue number(s)
- ✅ Tests for new features
- ✅ Updated documentation
- ✅ No breaking changes (or clearly documented if intentional)
- ✅ Screenshots/GIFs for UI changes
- ✅ Passes all CI checks
- ✅ Follows code style guidelines

### PR Template

```markdown
## 📝 Description
Brief description of changes

## 🔗 Related Issues
Closes #issue-number

## 🧪 Testing
- [ ] Unit tests added/updated
- [ ] Manual testing on Android
- [ ] Manual testing on iOS
- [ ] No regressions observed

## 📸 Screenshots (if applicable)
[Paste screenshots/GIFs here]

## 📋 Checklist
- [ ] Code follows style guidelines
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] No breaking changes
- [ ] All tests passing
- [ ] Commit messages are clear

## 🔄 Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Refactoring
- [ ] Documentation
```

---

## 📐 Coding Standards

### Dart/Flutter Code Style

We follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines:

#### Naming Conventions

```dart
// Files: snake_case
// lib/models/expense_model.dart

// Classes: PascalCase
class ExpenseModel { }
class BudgetProvider { }

// Methods & Variables: camelCase
void addExpense() { }
int expenseCount = 0;

// Constants: CONSTANT_STYLE
const int MAX_DAILY_EXPENSES = 100;
const String APP_NAME = 'KHARCHA';

// Enums: PascalCase
enum ExpenseCategory { Food, Transport, Bills }

// Private members: prefix with _
class ExpenseProvider {
  String _privateVariable;
  void _privateMethod() { }
}
```

#### Code Organization

1. **Imports**
   ```dart
   // Dart imports first
   import 'dart:async';
   import 'dart:convert';
   
   // Package imports
   import 'package:flutter/material.dart';
   import 'package:firebase_core/firebase_core.dart';
   
   // Relative imports
   import 'models/expense_model.dart';
   import 'services/firebase_service.dart';
   ```

2. **Class Structure**
   ```dart
   class MyClass {
     // Constants
     static const String CONSTANT = 'value';
     
     // Static variables
     static int _staticVar;
     
     // Instance variables
     String _privateVar;
     String publicVar;
     
     // Constructors
     MyClass(this.publicVar);
     
     factory MyClass.fromJson(Map<String, dynamic> json) { }
     
     // Getters and setters
     String get name => _privateVar;
     set name(String value) => _privateVar = value;
     
     // Public methods
     void publicMethod() { }
     
     // Private methods
     void _privateMethod() { }
   }
   ```

#### Documentation Comments

```dart
/// Adds a new expense to the database.
///
/// This method validates the expense data and syncs with Firebase.
/// Returns true if successful, false otherwise.
///
/// Example:
/// ```dart
/// final expense = Expense(amount: 450, category: 'Food');
/// final success = await addExpense(expense);
/// ```
bool addExpense(Expense expense) { }

/// Private helper method.
void _helperMethod() { }
```

#### Code Formatting

- Use `dart format` to format code
- Line length: 80-100 characters
- Use 2 spaces for indentation
- No trailing whitespace

#### Anti-Patterns to Avoid

```dart
// ❌ Don't use dynamic
dynamic value = 10;

// ✅ Use specific types
int value = 10;

// ❌ Don't use var for complex types
var expense = Expense(amount: 450);

// ✅ Use explicit types for clarity
final Expense expense = Expense(amount: 450);

// ❌ Don't catch generic exceptions
try { } catch (e) { }

// ✅ Catch specific exceptions
try { } on FirebaseException catch (e) { }

// ❌ Don't ignore lint warnings
// ignore: avoid_empty_else
if (condition) { } else { }

// ✅ Fix the code instead
if (condition) { }
```

### File Organization

```
lib/
├── models/              # Data models
│   ├── expense_model.dart
│   ├── budget_model.dart
│   └── income_model.dart
├── services/            # Business logic & API
│   ├── firebase_service.dart
│   ├── database_service.dart
│   └── notification_service.dart
├── screens/             # UI pages
│   ├── home/
│   ├── add_expense/
│   ├── analytics/
│   └── settings/
├── widgets/             # Reusable components
│   ├── charts/
│   ├── expense_card.dart
│   └── common/
├── providers/           # State management
│   ├── expense_provider.dart
│   ├── budget_provider.dart
│   └── auth_provider.dart
├── theme/               # Styling
│   ├── colors.dart
│   ├── text_styles.dart
│   └── theme_data.dart
├── utils/               # Helpers
│   ├── constants.dart
│   ├── validators.dart
│   └── extensions.dart
├── main.dart            # App entry point
└── firebase_options.dart
```

---

## 🧪 Testing Requirements

### Unit Tests

Test business logic, models, and services:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/models/expense_model.dart';

void main() {
  group('Expense Model', () {
    test('should create expense with valid data', () {
      final expense = Expense(
        amount: 450,
        category: 'Food',
        date: DateTime.now(),
      );
      
      expect(expense.amount, 450);
      expect(expense.category, 'Food');
    });
    
    test('should validate negative amounts', () {
      expect(
        () => Expense(amount: -100, category: 'Food'),
        throwsArgumentError,
      );
    });
  });
}
```

### Widget Tests

Test UI components:

```dart
testWidgets('ExpenseCard displays correctly', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ExpenseCard(expense: testExpense),
    ),
  );
  
  expect(find.byType(ExpenseCard), findsOneWidget);
  expect(find.text('₹450'), findsOneWidget);
});
```

### Running Tests

```bash
# Run all tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/models/expense_model_test.dart

# Run tests matching pattern
flutter test --name "Expense Model"

# View coverage report
lcov --list coverage/lcov.info
```

### Coverage Targets

- **Models & Services:** 90%
- **Providers:** 85%
- **Widgets:** 75%

---

## 📖 Documentation

### Code Documentation

- Add documentation comments (///) for public APIs
- Explain complex algorithms
- Provide usage examples for non-obvious code

### Update Documentation Files

When making changes, update relevant docs:

- **README.md** - Features, setup changes
- **CONTRIBUTING.md** - Process updates
- **Code comments** - Implementation details

### API Documentation

For new features, add docs to relevant sections:

```markdown
### New Feature Name

**Description:** Clear description of what it does

**Usage:**
\`\`\`dart
// Example code
\`\`\`

**Parameters:**
- `param1`: Description
- `param2`: Description

**Returns:** Description of return value

**Throws:** Exceptions that might be thrown
```

---

## 🔍 Review Process

### What Reviewers Look For

1. **Code Quality**
   - Follows coding standards
   - No bugs or edge cases missed
   - Efficient algorithms
   - Proper error handling

2. **Testing**
   - Tests included for new code
   - Test coverage maintained
   - No broken existing tests

3. **Documentation**
   - Code is self-documenting
   - Complex logic has comments
   - Docs are updated

4. **Performance**
   - No significant performance regressions
   - Efficient database queries
   - Proper resource management

5. **UI/UX**
   - Follows app design guidelines
   - Works on Android and iOS
   - Accessible (colors, text size, etc.)

### Review Timeline

- Simple changes: 1-2 days
- Medium changes: 2-3 days
- Large changes: 3-5 days

### After Review

- **Approved & No Changes Needed:** Maintainer merges your PR ✅
- **Requested Changes:** Update your code and request re-review
- **No Changes After 7 Days:** PR may be closed

---

## 🎓 Resources

### Learning Resources

- [Dart Documentation](https://dart.dev)
- [Flutter Documentation](https://flutter.dev)
- [Firebase for Flutter](https://firebase.flutter.dev)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Material Design 3](https://m3.material.io)

### Tools & Extensions

- [Dart Analyzer](https://dart.dev/tools/analysis)
- [Flutter DevTools](https://flutter.dev/docs/development/tools/devtools)
- [Firebase Emulator Suite](https://firebase.google.com/docs/emulator-suite)

---

## ❓ Questions?

- 💬 Ask in [GitHub Discussions](https://github.com/lucifers-0666/KHARCHA-Expense-Tracker_APP/discussions)
- 📧 Email: your.email@example.com
- 🐦 Twitter: [@lucifers-0666](https://twitter.com/lucifers-0666)

---

## 🙏 Thank You

Thank you for contributing to KHARCHA! Your efforts help us create a better expense tracking experience for everyone. We appreciate your time and dedication.

---

<div align="center">

**Happy Contributing! 🚀**

Made with ❤️ by the KHARCHA community

</div>
