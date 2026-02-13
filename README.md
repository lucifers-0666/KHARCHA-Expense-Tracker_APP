# KHARCHA

KHARCHA is a Flutter‑based expense tracking app that helps you record daily spending, monitor budgets, and understand where your money actually goes—so you can make better real‑world decisions with confidence.

## Overview

The app is built for everyday use: quick expense entry, clear monthly summaries, and budget tracking that keeps you aware of overspending before it happens. KHARCHA focuses on simplicity and clarity, so even non‑technical users can understand their spending behavior.

## Real‑World Scenarios

- **Daily spend control:** Log grocery runs, fuel, eating out, and small cash expenses in seconds.
- **Bills and subscriptions:** Track recurring expenses like rent, EMI, and streaming services.
- **Monthly review:** See totals by category to identify where you overspend.
- **Budget awareness:** Compare spending against planned limits to avoid surprises.

## Core Features

- Quick expense entry with categories
- Monthly summaries and category breakdowns
- Budget tracking and progress visibility
- Recurring expense reminders/notifications
- Clean UI optimized for mobile use

## How Data Flows

1. You add an expense (amount, category, date, note).
2. The entry is saved to the cloud database.
3. Dashboards and summaries update automatically.
4. Recurring items trigger reminders so nothing is missed.

## Tech Stack

- **Flutter (Dart)** for the app UI and logic
- **Firebase** for backend services

## Database

KHARCHA uses **Firebase Firestore** to store expenses, budgets, recurring items, and user data securely in the cloud.

## Security Note

Firebase API keys and project configuration are not included in this README. Keep secrets inside your Firebase config files and do not share them publicly.

## Getting Started

1. Install the Flutter SDK.
2. Run `flutter pub get`.
3. Start the app with `flutter run`.
