import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Card(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.audio_file_rounded, color: AppColors.primary),
                      title: const Text('Download Quality',
                          style: TextStyle(color: AppColors.textPrimary)),
                      subtitle: const Text('192 kbps MP3 (FFmpeg VBR/CBR)',
                          style: TextStyle(color: AppColors.textSecondary)),
                      trailing: const Icon(Icons.check_circle_rounded, color: AppColors.success),
                    ),
                    const Divider(height: 1, color: AppColors.surfaceVariant),
                    ListTile(
                      leading: const Icon(Icons.storage_rounded, color: AppColors.primary),
                      title: const Text('Storage Architecture',
                          style: TextStyle(color: AppColors.textPrimary)),
                      subtitle: const Text('100% on-device local storage & SQLite',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    const Divider(height: 1, color: AppColors.surfaceVariant),
                    ListTile(
                      leading: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                      title: const Text('About Fann',
                          style: TextStyle(color: AppColors.textPrimary)),
                      subtitle: const Text('Pure Dart YouTube Music Player v1.0.0',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
