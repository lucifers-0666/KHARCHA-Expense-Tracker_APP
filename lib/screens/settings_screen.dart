import 'package:flutter/material.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:flutter_application_1/theme/theme_provider.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColorsDark.primaryDark,
                    AppColorsDark.primary,
                    AppColorsDark.accent,
                  ]
                : [AppColors.primaryDark, AppColors.primary, AppColors.accent],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, isDark),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColorsDark.surface : AppColors.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildThemeSection(context, themeProvider, isDark),
                      const SizedBox(height: 24),
                      _buildAppInfoSection(context, isDark),
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

  Widget _buildHeader(BuildContext context, bool isDark) {
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
            'Settings',
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

  Widget _buildThemeSection(
    BuildContext context,
    ThemeProvider themeProvider,
    bool isDark,
  ) {
    return Card(
      elevation: 2,
      color: isDark ? AppColorsDark.card : AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColorsDark.accent : AppColors.accent)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.palette,
                    color: isDark ? AppColorsDark.accent : AppColors.accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Appearance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildThemeOption(
            context,
            themeProvider,
            isDark,
            ThemePreference.light,
            'Light Mode',
            'Use light theme',
            Icons.light_mode,
          ),
          _buildThemeOption(
            context,
            themeProvider,
            isDark,
            ThemePreference.dark,
            'Dark Mode',
            'Use dark theme',
            Icons.dark_mode,
          ),
          _buildThemeOption(
            context,
            themeProvider,
            isDark,
            ThemePreference.system,
            'System Default',
            'Follow system settings',
            Icons.brightness_auto,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeProvider themeProvider,
    bool isDark,
    ThemePreference preference,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final bool isSelected = themeProvider.themePreference == preference;

    return InkWell(
      onTap: () => themeProvider.setThemePreference(preference),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColorsDark.accent : AppColors.accent).withValues(
                  alpha: 0.1,
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? (isDark ? AppColorsDark.accent : AppColors.accent)
                  : (isDark
                        ? AppColorsDark.textSecondary
                        : AppColors.textSecondary),
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? (isDark ? AppColorsDark.accent : AppColors.accent)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColorsDark.textSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: isDark ? AppColorsDark.accent : AppColors.accent,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoSection(BuildContext context, bool isDark) {
    return Card(
      elevation: 2,
      color: isDark ? AppColorsDark.card : AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColorsDark.info : AppColors.info)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.info,
                    color: isDark ? AppColorsDark.info : AppColors.info,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'About',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            subtitle: const Text('1.0.0'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (isDark ? AppColorsDark.success : AppColors.success)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Latest',
                style: TextStyle(
                  color: isDark ? AppColorsDark.success : AppColors.success,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.business),
            title: const Text('Developer'),
            subtitle: const Text('KHARCHA Team'),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('License'),
            subtitle: const Text('MIT License'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('License Information'),
                  content: const Text(
                    'This app is licensed under the MIT License.\n\n'
                    'Permission is hereby granted, free of charge, to any person obtaining a copy of this software.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
