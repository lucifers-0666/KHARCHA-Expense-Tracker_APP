import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_application_1/firebase_options.dart';
import 'package:flutter_application_1/services/firestore_services.dart';
import 'package:flutter_application_1/services/notification_service.dart';
import 'package:workmanager/workmanager.dart';

const String recurringTaskName = 'kharchaRecurringExpenseTask';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {
      // Ignore "already initialized" scenarios.
    }

    final firestore = FirestoreServices();
    final notifications = NotificationService.instance;

    await notifications.initialize();
    await firestore.processDueRecurringExpenses();

    final dueSoonItems = await firestore.getRecurringDueSoon();
    for (final recurring in dueSoonItems) {
      await notifications.showDueSoonReminder(
        id: recurring.id.hashCode,
        title: 'Upcoming expense: ${recurring.title}',
        body:
            'Due on ${recurring.nextDueDate.day}/${recurring.nextDueDate.month}/${recurring.nextDueDate.year} (Rs ${recurring.amount.toStringAsFixed(2)})',
      );
      await firestore.markRecurringReminderSent(recurring.id, DateTime.now());
    }

    return true;
  });
}

class RecurringBackgroundService {
  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher);

    await Workmanager().registerPeriodicTask(
      recurringTaskName,
      recurringTaskName,
      frequency: const Duration(hours: 24),
      initialDelay: const Duration(minutes: 10),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
  }
}
