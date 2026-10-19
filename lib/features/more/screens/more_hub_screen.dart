import 'package:flutter/material.dart';
import '../../../core/config/theme.dart';
import '../../spiritual/screens/spiritual_overview_screen.dart';
import '../../lifestyle/screens/lifestyle_hub_screen.dart';
import '../../professional/screens/workspaces_overview_screen.dart';
import '../../learning/screens/reading_library_screen.dart';
import '../../health/screens/health_hub_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../analytics/screens/insights_screen.dart';
import '../../governance/screens/device_governance_screen.dart';
import '../../notes/screens/notes_workstation_screen.dart';

class MoreHubScreen extends StatelessWidget {
  const MoreHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamCanvas,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.of(context).padding.top > 0
                    ? MediaQuery.of(context).padding.top + 16
                    : 56,
                20,
                24,
              ),
              decoration: const BoxDecoration(
                gradient: AppTheme.coralMeshGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.35)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.widgets_outlined, size: 14, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'Ecosystem Modules',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.tune, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Hub & Settings',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Segregated workspaces, spiritual life, habits & encryption',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 110 + MediaQuery.of(context).padding.bottom),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildHubCard(
                  context,
                  icon: Icons.draw_outlined,
                  iconColor: const Color(0xFF9333EA),
                  badge: 'OMNI NOTES',
                  title: 'Notes & Revelations Hub',
                  subtitle: 'Prophetic revelations, visions, bible study, strategic blueprints & convert to tasks',
                  destination: const NotesWorkstationScreen(),
                ),
                _buildHubCard(
                  context,
                  icon: Icons.church,
                  iconColor: const Color(0xFF6366F1),
                  badge: 'DEVOTION',
                  title: 'Spiritual Life',
                  subtitle: 'Prayer journal, Scripture passage planner, 3-day fasting engine',
                  destination: const SpiritualOverviewScreen(),
                ),
                _buildHubCard(
                  context,
                  icon: Icons.checkroom,
                  iconColor: const Color(0xFFEC4899),
                  badge: 'LIFESTYLE',
                  title: 'Personal Care & Wardrobe',
                  subtitle: 'Daily grooming, weekend cleaning, Sunday outfits rotation',
                  destination: const LifestyleHubScreen(),
                ),
                _buildHubCard(
                  context,
                  icon: Icons.business_center,
                  iconColor: AppTheme.colorBems,
                  badge: 'WORKSPACES',
                  title: 'Professional Workspaces',
                  subtitle: 'Bems Group (COO) & Henovate (Founder) segregated projects',
                  destination: const WorkspacesOverviewScreen(),
                ),
                _buildHubCard(
                  context,
                  icon: Icons.menu_book,
                  iconColor: const Color(0xFFF59E0B),
                  badge: 'KNOWLEDGE',
                  title: 'Reading Library & Checklists',
                  subtitle: 'Curated books, study notes, pre-deliverable review checklist',
                  destination: const ReadingLibraryScreen(),
                ),
                _buildHubCard(
                  context,
                  icon: Icons.favorite,
                  iconColor: const Color(0xFF10B981),
                  badge: 'WELLBEING',
                  title: 'Health, Relationships & Sleep',
                  subtitle: 'Cross-midnight sleep validator, wellbeing, character logs',
                  destination: const HealthHubScreen(),
                ),
                _buildHubCard(
                  context,
                  icon: Icons.insights,
                  iconColor: AppTheme.sereneTeal,
                  badge: 'ANALYTICS',
                  title: 'Reviews & Insights Analytics',
                  subtitle: 'Sunday weekly review, month-end closing, authentic trends',
                  destination: const InsightsScreen(),
                ),
                _buildHubCard(
                  context,
                  icon: Icons.security,
                  iconColor: const Color(0xFFDC2626),
                  badge: 'DEVICE CONTROL',
                  title: 'Phone Governance & Focus Shield',
                  subtitle: 'Device administrator lockdown, social handles shutdown, alarm triggers',
                  destination: const DeviceGovernanceScreen(),
                ),
                _buildHubCard(
                  context,
                  icon: Icons.shield_outlined,
                  iconColor: AppTheme.slateNavy,
                  badge: 'SECURITY',
                  title: 'Settings, Security & Backups',
                  subtitle: 'Local biometric/PIN, encrypted backups (.plos), zero telemetry',
                  destination: const SettingsScreen(),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHubCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String badge,
    required String title,
    required String subtitle,
    required Widget destination,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: AppTheme.floatingCardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => destination),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.peachPillBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.coralPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppTheme.darkCharcoal,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppTheme.offWhiteBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.darkCharcoal),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
