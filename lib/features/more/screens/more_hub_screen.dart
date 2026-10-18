import 'package:flutter/material.dart';
import '../../../core/config/theme.dart';
import '../../spiritual/screens/spiritual_overview_screen.dart';
import '../../lifestyle/screens/lifestyle_hub_screen.dart';
import '../../professional/screens/workspaces_overview_screen.dart';
import '../../learning/screens/reading_library_screen.dart';
import '../../health/screens/health_hub_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../analytics/screens/insights_screen.dart';

class MoreHubScreen extends StatelessWidget {
  const MoreHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Modules & Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHubTile(
            context,
            icon: Icons.church,
            iconColor: const Color(0xFF6366F1),
            title: 'Spiritual Life',
            subtitle: 'Prayer journal, Bible study passage planner, fasting calendar',
            destination: const SpiritualOverviewScreen(),
          ),
          _buildHubTile(
            context,
            icon: Icons.checkroom,
            iconColor: const Color(0xFFEC4899),
            title: 'Personal Care, Chores & Wardrobe',
            subtitle: 'Daily hygiene, weekend cleaning, Sunday outfits (Mon–Sun)',
            destination: const LifestyleHubScreen(),
          ),
          _buildHubTile(
            context,
            icon: Icons.business_center,
            iconColor: AppTheme.colorBems,
            title: 'Professional Workspaces',
            subtitle: 'Bems Group (COO) & Henovate (Founder) segregated projects',
            destination: const WorkspacesOverviewScreen(),
          ),
          _buildHubTile(
            context,
            icon: Icons.menu_book,
            iconColor: const Color(0xFFF59E0B),
            title: 'Reading, Learning & Checklists',
            subtitle: 'Book library, study notes, pre-deliverable review checklist',
            destination: const ReadingLibraryScreen(),
          ),
          _buildHubTile(
            context,
            icon: Icons.favorite,
            iconColor: const Color(0xFF10B981),
            title: 'Health, Relationships & Character',
            subtitle: 'Sleep opportunities, wellbeing logs, relationship reminders',
            destination: const HealthHubScreen(),
          ),
          _buildHubTile(
            context,
            icon: Icons.insights,
            iconColor: AppTheme.sereneTeal,
            title: 'Reviews & Insights Analytics',
            subtitle: 'Sunday weekly review, month-end closing, genuine trends',
            destination: const InsightsScreen(),
          ),
          _buildHubTile(
            context,
            icon: Icons.settings,
            iconColor: AppTheme.slateNavy,
            title: 'Settings, Security & Backups',
            subtitle: 'Local PIN gate, encrypted backups (.plos), storage usage',
            destination: const SettingsScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildHubTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget destination,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.12),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.mutedGray),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => destination),
          );
        },
      ),
    );
  }
}
