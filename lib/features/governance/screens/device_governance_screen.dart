import 'package:flutter/material.dart';
import '../../../core/config/theme.dart';
import '../../../core/services/device_control_service.dart';

class DeviceGovernanceScreen extends StatefulWidget {
  const DeviceGovernanceScreen({super.key});

  @override
  State<DeviceGovernanceScreen> createState() => _DeviceGovernanceScreenState();
}

class _DeviceGovernanceScreenState extends State<DeviceGovernanceScreen> {
  bool _isAdminActive = false;
  bool _isAccessibilityActive = false;
  bool _isSocialShieldActive = false;
  bool _isAlarmPlaying = false;
  final _phoneController = TextEditingController(text: '+234');

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final admin = await DeviceControlService.instance.isDeviceAdminActive();
    final access = await DeviceControlService.instance.isAccessibilityActive();
    if (mounted) {
      setState(() {
        _isAdminActive = admin;
        _isAccessibilityActive = access;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamCanvas,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
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
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.35)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.security, size: 14, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'Device Control Center',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Phone Governance',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Device admin lockdown, social media shutdown & hardware triggers',
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
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. Social Media Override Shield
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.floatingCardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.block, color: Color(0xFFDC2626), size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Social Handles Shutdown',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: AppTheme.darkCharcoal,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Overrides & locks Instagram, TikTok, Twitter/X, Facebook',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Active Social Media Shield', style: TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          _isSocialShieldActive ? 'Shutdown active: distracting apps blocked' : 'Shield inactive',
                          style: TextStyle(fontSize: 12, color: _isSocialShieldActive ? const Color(0xFFDC2626) : Colors.grey),
                        ),
                        value: _isSocialShieldActive,
                        activeColor: const Color(0xFFDC2626),
                        onChanged: (val) async {
                          if (!_isAccessibilityActive && val) {
                            await DeviceControlService.instance.openAccessibilitySettings();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enable "Personal Life OS" in Accessibility Settings to enforce app shutdown.')),
                              );
                            }
                            return;
                          }
                          await DeviceControlService.instance.setSocialMediaShield(val);
                          setState(() => _isSocialShieldActive = val);
                        },
                      ),
                      if (!_isAccessibilityActive)
                        OutlinedButton.icon(
                          icon: const Icon(Icons.settings_accessibility, size: 16),
                          label: const Text('Enable Accessibility Service'),
                          onPressed: () async {
                            await DeviceControlService.instance.openAccessibilitySettings();
                            await _checkStatus();
                          },
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 2. Full Device Administrator Lockdown
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.floatingCardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.peachPillBg,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.admin_panel_settings, color: AppTheme.coralPrimary, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Device Administrator',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: AppTheme.darkCharcoal,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isAdminActive ? 'Admin mode granted' : 'Grant admin to force-lock device',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (!_isAdminActive)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.verified_user, size: 16),
                          label: const Text('Activate Device Administrator'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.darkCharcoal,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            await DeviceControlService.instance.requestDeviceAdmin();
                            await _checkStatus();
                          },
                        )
                      else ...[
                        OutlinedButton.icon(
                          icon: const Icon(Icons.lock, color: AppTheme.coralPrimary, size: 16),
                          label: const Text('Force Lock Phone Now', style: TextStyle(color: AppTheme.coralPrimary)),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.coralPrimary)),
                          onPressed: () async {
                            await DeviceControlService.instance.lockPhone();
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Hardware Ringtone & Alarm Trigger
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.floatingCardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.alarm, color: Color(0xFFD97706), size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Alarm & Ringtone Trigger',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: AppTheme.darkCharcoal,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Loud hardware sound & vibration for urgent routines',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: Icon(_isAlarmPlaying ? Icons.stop : Icons.play_arrow, size: 16),
                              label: Text(_isAlarmPlaying ? 'Stop Ringtone' : 'Sound Alarm Ringtone'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isAlarmPlaying ? const Color(0xFFDC2626) : AppTheme.darkCharcoal,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () async {
                                if (_isAlarmPlaying) {
                                  await DeviceControlService.instance.stopAlarmRingtone();
                                  setState(() => _isAlarmPlaying = false);
                                } else {
                                  await DeviceControlService.instance.playAlarmRingtone();
                                  setState(() => _isAlarmPlaying = true);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 4. Trigger Direct Phone Call
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.floatingCardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.call, color: Color(0xFF059669), size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Trigger Phone Call',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: AppTheme.darkCharcoal,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Launch system dialer for accountability partners',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.phone_forwarded, color: Color(0xFF059669)),
                            onPressed: () {
                              final num = _phoneController.text.trim();
                              if (num.isNotEmpty) {
                                DeviceControlService.instance.triggerCall(num);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
