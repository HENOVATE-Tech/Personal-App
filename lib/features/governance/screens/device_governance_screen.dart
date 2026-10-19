import 'dart:async';
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
  bool _isSocialShieldActive = true;
  bool _isAlarmPlaying = false;
  final _phoneController = TextEditingController(text: '+234');

  // Governed Apps & Blocked Packages
  final Map<String, String> _allGovernedApps = {
    'Instagram': 'com.instagram.android',
    'TikTok': 'com.zhiliaoapp.musically',
    'Twitter / X': 'com.twitter.android',
    'Facebook': 'com.facebook.katana',
    'Snapchat': 'com.snapchat.android',
    'Reddit': 'com.reddit.frontpage',
    'YouTube': 'com.google.android.youtube',
    'Netflix': 'com.netflix.mediaclient',
    'Telegram': 'org.telegram.messenger',
    'Chrome Browser': 'com.android.chrome',
  };

  final Set<String> _selectedBlockedPackages = {
    'com.instagram.android',
    'com.zhiliaoapp.musically',
    'com.twitter.android',
    'com.facebook.katana',
    'com.snapchat.android',
    'com.reddit.frontpage',
  };

  // Emergency Focus Override
  int _remainingOverrideSeconds = 0;
  String _activeOverrideReason = '';
  Timer? _overrideTimer;

  @override
  void initState() {
    super.initState();
    _checkStatus();
    _syncBlockedPackages();
  }

  Future<void> _checkStatus() async {
    final admin = await DeviceControlService.instance.isDeviceAdminActive();
    final access = await DeviceControlService.instance.isAccessibilityActive();
    final remainingSecs = await DeviceControlService.instance.getEmergencyOverrideRemainingSeconds();
    if (mounted) {
      setState(() {
        _isAdminActive = admin;
        _isAccessibilityActive = access;
        if (remainingSecs > 0) {
          _remainingOverrideSeconds = remainingSecs;
          _startCountdownTimer();
        }
      });
    }
  }

  Future<void> _syncBlockedPackages() async {
    await DeviceControlService.instance.setBlockedPackages(_selectedBlockedPackages.toList());
  }

  void _startCountdownTimer() {
    _overrideTimer?.cancel();
    _overrideTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingOverrideSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingOverrideSeconds = 0;
          _activeOverrideReason = '';
        });
      } else {
        setState(() {
          _remainingOverrideSeconds--;
        });
      }
    });
  }

  @override
  void dispose() {
    _overrideTimer?.cancel();
    _phoneController.dispose();
    super.dispose();
  }

  void _showEmergencyOverrideDialog() {
    final reasonCtrl = TextEditingController();
    int selectedDuration = 15;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFFEA580C)),
                  SizedBox(width: 8),
                  Text('Emergency Override', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Request a temporary window to unlock governed apps. All focus breaks require an explicit, audited reason.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    const Text('Select Override Duration:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [5, 15, 30].map((mins) {
                        final isSel = selectedDuration == mins;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('$mins Mins'),
                            selected: isSel,
                            selectedColor: const Color(0xFFFFECE5),
                            labelStyle: TextStyle(
                              color: isSel ? AppTheme.coralPrimary : AppTheme.darkCharcoal,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            onSelected: (_) => setDialogState(() => selectedDuration = mins),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    const Text('Explicit Reason for Breaking Focus:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: reasonCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. Urgent client delivery call / Family emergency',
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final reason = reasonCtrl.text.trim();
                    if (reason.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please state an explicit reason for the focus override.')),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    await DeviceControlService.instance.requestEmergencyOverride(durationMinutes: selectedDuration);
                    setState(() {
                      _remainingOverrideSeconds = selectedDuration * 60;
                      _activeOverrideReason = reason;
                    });
                    _startCountdownTimer();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✓ Focus shield temporarily lifted for $selectedDuration mins.'),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA580C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Grant Temporary Access'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddCustomAppDialog() {
    final nameCtrl = TextEditingController();
    final packageCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Add App to Shield', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'App Name (e.g. Candy Crush)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: packageCtrl,
                decoration: InputDecoration(
                  labelText: 'Package Name (e.g. com.king.candycrush)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final pkg = packageCtrl.text.trim();
                if (name.isNotEmpty && pkg.isNotEmpty) {
                  setState(() {
                    _allGovernedApps[name] = pkg;
                    _selectedBlockedPackages.add(pkg);
                  });
                  _syncBlockedPackages();
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.coralPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Add to Shield'),
            ),
          ],
        );
      },
    );
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
                // 0. Active Emergency Override Banner (if active)
                if (_remainingOverrideSeconds > 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEA580C), Color(0xFFF97316)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEA580C).withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
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
                                Icon(Icons.timer_outlined, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'FOCUS OVERRIDE ACTIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${(_remainingOverrideSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingOverrideSeconds % 60).toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_activeOverrideReason.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Reason: $_activeOverrideReason',
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFFEA580C),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              _overrideTimer?.cancel();
                              setState(() {
                                _remainingOverrideSeconds = 0;
                                _activeOverrideReason = '';
                              });
                              DeviceControlService.instance.requestEmergencyOverride(durationMinutes: 0);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Focus shield re-engaged.')),
                              );
                            },
                            child: const Text('End Override & Lock Shield Early', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 1. Social Media & Focus Shield Master Switch
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
                                  'Focus Shield & App Lockdown',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: AppTheme.darkCharcoal,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Enforces strict distraction blocking during focus & prayer blocks',
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
                        title: const Text('Active Focus Shield', style: TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          _isSocialShieldActive ? 'Shield active: ${_selectedBlockedPackages.length} apps locked' : 'Shield inactive',
                          style: TextStyle(fontSize: 12, color: _isSocialShieldActive ? const Color(0xFFDC2626) : Colors.grey),
                        ),
                        value: _isSocialShieldActive,
                        activeColor: const Color(0xFFDC2626),
                        onChanged: (val) async {
                          if (!_isAccessibilityActive && val) {
                            await DeviceControlService.instance.openAccessibilitySettings();
                            if (context.mounted) {
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
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.settings_accessibility, size: 16),
                            label: const Text('Enable Accessibility Service in Android Settings'),
                            onPressed: () async {
                              await DeviceControlService.instance.openAccessibilitySettings();
                              await _checkStatus();
                            },
                          ),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _showEmergencyOverrideDialog,
                          icon: const Icon(Icons.lock_open, size: 16, color: Color(0xFFEA580C)),
                          label: const Text('Request Emergency Focus Override', style: TextStyle(color: Color(0xFFEA580C), fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFEA580C)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 1b. Select Governed Applications (Which Apps to Block)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.floatingCardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Select Blocked Apps',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: AppTheme.darkCharcoal,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_selectedBlockedPackages.length} of ${_allGovernedApps.length} apps currently governed',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: AppTheme.coralPrimary),
                            tooltip: 'Add Custom App Package',
                            onPressed: _showAddCustomAppDialog,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      ..._allGovernedApps.entries.map((entry) {
                        final isBlocked = _selectedBlockedPackages.contains(entry.value);
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          subtitle: Text(entry.value, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                          value: isBlocked,
                          activeColor: const Color(0xFFDC2626),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedBlockedPackages.add(entry.value);
                              } else {
                                _selectedBlockedPackages.remove(entry.value);
                              }
                            });
                            _syncBlockedPackages();
                          },
                        );
                      }),
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
