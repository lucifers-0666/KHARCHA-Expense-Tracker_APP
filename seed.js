const admin = require('firebase-admin');

// Place your Firebase service account JSON in the same folder as this script.
const serviceAccount = require('./service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const { Timestamp } = admin.firestore;

function iso(dateString) {
  return new Date(dateString).toISOString().replace(/Z$/, '');
}

function ts(dateString) {
  return Timestamp.fromDate(new Date(dateString));
}

async function seedDatabase() {
  try {
    console.log('🌱 Starting KHARCHA Firestore seeding...');

    const expenseDocs = [
      {
        title: 'Lunch at Subway',
        amount: 320,
        category: 'Food',
        date: iso('2026-05-14T13:00:00.000Z'),
        description: 'Quick lunch during work break',
        receiptUrl: null,
      },
      {
        title: 'Uber to Office',
        amount: 180,
        category: 'Transport',
        date: iso('2026-05-13T08:15:00.000Z'),
        description: 'Morning commute',
        receiptUrl: null,
      },
      {
        title: 'Amazon Order',
        amount: 1299,
        category: 'Shopping',
        date: iso('2026-05-11T19:45:00.000Z'),
        description: 'Household essentials',
        receiptUrl: null,
      },
      {
        title: 'Electricity Bill',
        amount: 850,
        category: 'Utilities',
        date: iso('2026-05-09T10:20:00.000Z'),
        description: 'Monthly power bill payment',
        receiptUrl: null,
      },
      {
        title: 'Movie Tickets',
        amount: 600,
        category: 'Entertainment',
        date: iso('2026-05-07T21:10:00.000Z'),
        description: 'Weekend movie plan',
        receiptUrl: null,
      },
    ];

    const budgetDoc = {
      id: '2026-05',
      monthlyLimit: 20000,
      year: 2026,
      month: 5,
    };

    const incomeDocs = [
      {
        title: 'Monthly Salary',
        amount: 35000,
        category: 'Salary',
        date: iso('2026-05-01T09:00:00.000Z'),
        note: 'May 2026 salary credited',
      },
      {
        title: 'Freelance Project',
        amount: 8000,
        category: 'Freelance',
        date: iso('2026-05-10T15:30:00.000Z'),
        note: 'Website redesign payment',
      },
      {
        title: 'Stock Dividend',
        amount: 1500,
        category: 'Investment',
        date: iso('2026-05-12T11:00:00.000Z'),
        note: 'Quarterly dividend payout',
      },
    ];

    const recurringDocs = [
      {
        title: 'Netflix',
        amount: 649,
        category: 'Entertainment',
        frequency: 'monthly',
        nextDueDate: iso('2026-06-01T00:00:00.000Z'),
        isActive: true,
        lastCreatedDate: iso('2026-05-01T00:00:00.000Z'),
        lastReminderDate: null,
      },
      {
        title: 'Gym Membership',
        amount: 999,
        category: 'Health',
        frequency: 'monthly',
        nextDueDate: iso('2026-06-05T00:00:00.000Z'),
        isActive: true,
        lastCreatedDate: iso('2026-05-05T00:00:00.000Z'),
        lastReminderDate: null,
      },
      {
        title: 'Sunday Market',
        amount: 500,
        category: 'Food',
        frequency: 'weekly',
        nextDueDate: iso('2026-05-17T00:00:00.000Z'),
        isActive: true,
        lastCreatedDate: null,
        lastReminderDate: null,
      },
    ];

    const groupDoc = {
      name: 'Goa Trip 2026',
      description: 'Friends trip expenses for May 2026',
      members: [
        { userId: 'uid_zaid', name: 'Zaid', email: 'zaid@email.com' },
        { userId: 'uid_ali', name: 'Ali', email: 'ali@email.com' },
      ],
      createdBy: 'uid_zaid',
      createdAt: ts('2026-05-14T18:30:00.000Z'),
      totalAmount: 5700,
      settledAmount: 0,
      isSettled: false,
    };

    const userDoc = {
      uid: 'seed_user_001',
      fullName: 'Zaid Khan',
      email: 'zaid@example.com',
      createdAt: Timestamp.fromDate(new Date()),
      profileImageUrl: null,
      totalMonthlyBudget: 20000.0,
    };

    console.log('Adding users...');
    await db.collection('users').doc(userDoc.uid).set(userDoc);

    console.log('Adding expenses...');
    for (const expense of expenseDocs) {
      await db.collection('expenses').add(expense);
    }

    console.log('Adding budget...');
    await db.collection('budgets').doc(budgetDoc.id).set(budgetDoc);

    console.log('Adding income...');
    for (const income of incomeDocs) {
      await db.collection('income').add(income);
    }

    console.log('Adding recurring expenses...');
    for (const recurringExpense of recurringDocs) {
      await db.collection('recurring_expenses').add(recurringExpense);
    }

    console.log('Adding group and group expenses...');
    const groupRef = await db.collection('groups').add(groupDoc);

    await groupRef.collection('group_expenses').add({
      title: 'Hotel Booking',
      amount: 4500,
      paidBy: 'uid_zaid',
      splitAmong: ['uid_zaid', 'uid_ali'],
      date: ts('2026-05-14T19:00:00.000Z'),
      isSettled: false,
    });

    await groupRef.collection('group_expenses').add({
      title: 'Dinner at Beach',
      amount: 1200,
      paidBy: 'uid_ali',
      splitAmong: ['uid_zaid', 'uid_ali'],
      date: ts('2026-05-14T21:00:00.000Z'),
      isSettled: false,
    });

    console.log('🎉 KHARCHA Firestore seeding completed successfully.');
  } catch (error) {
    console.error('❌ Error seeding KHARCHA Firestore data:', error);
    process.exitCode = 1;
  }
}

seedDatabase();
