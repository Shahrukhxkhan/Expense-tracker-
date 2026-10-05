import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/notification_service.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _dailyReminderEnabled = true;
  bool _budgetAlertsEnabled = true;
  bool _subscriptionAlertsEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeSettingsProvider);
    final themeNotifier = ref.read(themeSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Customization'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Section 1: Appearance & Theme
          _buildSectionHeader('Appearance & Aesthetics', Icons.palette_outlined),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Theme Mode',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<AppThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: AppThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment(
                        value: AppThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.dark_mode_outlined),
                      ),
                      ButtonSegment(
                        value: AppThemeMode.amoled,
                        label: Text('OLED'),
                        icon: Icon(Icons.nightlight_round),
                      ),
                    ],
                    selected: {themeState.themeMode},
                    onSelectionChanged: (newSelection) {
                      themeNotifier.setThemeMode(newSelection.first);
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Accent Color Palette',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: AccentColorPreset.values.map((preset) {
                      final isSelected = themeState.accentColor == preset;
                      return InkWell(
                        onTap: () => themeNotifier.setAccentColor(preset),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: preset.color.withValues(alpha: isSelected ? 0.2 : 0.08),
                            border: Border.all(
                              color: isSelected ? preset.color : Colors.transparent,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 8,
                                backgroundColor: preset.color,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                preset.label,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected ? preset.color : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Section 2: Notifications & Reminders
          _buildSectionHeader('Notifications & Reminders', Icons.notifications_active_outlined),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Daily Evening Reminder'),
                  subtitle: Text(
                    'Remind to record expenses daily at ${_reminderTime.format(context)}',
                  ),
                  value: _dailyReminderEnabled,
                  onChanged: (val) {
                    setState(() => _dailyReminderEnabled = val);
                    if (val) {
                      NotificationService.instance.scheduleDailyReminder(
                        hour: _reminderTime.hour,
                        minute: _reminderTime.minute,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Evening reminder scheduled!')),
                      );
                    }
                  },
                ),
                if (_dailyReminderEnabled)
                  ListTile(
                    title: const Text('Reminder Time'),
                    trailing: OutlinedButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _reminderTime,
                        );
                        if (picked != null) {
                          setState(() => _reminderTime = picked);
                          NotificationService.instance.scheduleDailyReminder(
                            hour: picked.hour,
                            minute: picked.minute,
                          );
                        }
                      },
                      child: Text(_reminderTime.format(context)),
                    ),
                  ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Budget Limit Alerts'),
                  subtitle: const Text('Alert when 80% or 100% of budget is reached'),
                  value: _budgetAlertsEnabled,
                  onChanged: (val) => setState(() => _budgetAlertsEnabled = val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Subscription Due Alerts'),
                  subtitle: const Text('Notify before recurring subscriptions renew'),
                  value: _subscriptionAlertsEnabled,
                  onChanged: (val) => setState(() => _subscriptionAlertsEnabled = val),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.send_outlined),
                    label: const Text('Send Test Notification'),
                    onPressed: () {
                      NotificationService.instance.showNotification(
                        id: 999,
                        title: 'Test Notification 🔔',
                        body: 'Expense tracker notification engine is operating normally.',
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 3: Home Screen Widget Preview
          _buildSectionHeader('Home Screen Widget', Icons.widgets_outlined),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Preview: Quick Glance Widget',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pin this widget to your home screen for immediate balance preview and 1-tap expense creation.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Widget Simulated Mockup
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          themeState.accentColor.color.withValues(alpha: 0.9),
                          themeState.accentColor.color.withValues(alpha: 0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: themeState.accentColor.color.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.wallet, color: Colors.white, size: 20),
                                SizedBox(width: 6),
                                Text(
                                  'Daily Budget',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Live',
                                style: TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '\$42.50 Left Today',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: themeState.accentColor.color,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {},
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('+ Expense', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
