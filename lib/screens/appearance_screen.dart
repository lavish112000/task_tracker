import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_tracker/utils/app_colors.dart';
import 'package:task_tracker/utils/theme_provider.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'THEME',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            _buildThemeOption(
              context: context,
              title: 'System',
              icon: Icons.settings_brightness_outlined,
              currentMode: themeProvider.themeMode,
              mode: ThemeMode.system,
            ),
            _buildThemeOption(
              context: context,
              title: 'Light',
              icon: Icons.wb_sunny_outlined,
              currentMode: themeProvider.themeMode,
              mode: ThemeMode.light,
            ),
            _buildThemeOption(
              context: context,
              title: 'Dark',
              icon: Icons.nightlight_round,
              currentMode: themeProvider.themeMode,
              mode: ThemeMode.dark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required String title,
    required IconData icon,
    required ThemeMode currentMode,
    required ThemeMode mode,
  }) {
    final isSelected = currentMode == mode;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return GestureDetector(
      onTap: () => themeProvider.setThemeMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor.withAlpha((255 * 0.1).round()) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.textSecondary.withAlpha(100),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primaryColor : AppColors.textSecondary),
            const SizedBox(width: 15),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isSelected ? AppColors.primaryColor : AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primaryColor,
              ),
          ],
        ),
      ),
    );
  }
}
