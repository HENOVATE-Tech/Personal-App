import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/config/theme.dart';
import '../../../core/database/local_database.dart';
import '../../../core/database/schema_models.dart';
import '../../../core/utils/date_utils.dart';
import '../../tasks/screens/quick_capture_sheet.dart';

class WorkspacesOverviewScreen extends StatefulWidget {
  const WorkspacesOverviewScreen({super.key});

  @override
  State<WorkspacesOverviewScreen> createState() => _WorkspacesOverviewScreenState();
}

class _WorkspacesOverviewScreenState extends State<WorkspacesOverviewScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _uuid = const Uuid();
  String _taskFilter = 'all'; // 'all', 'active', 'priority', 'completed'

  @override
  void initState() {
    super.initState();
    final workspaces = LocalDatabase.instance.getWorkspaces();
    _tabController = TabController(length: workspaces.length + 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _reinitTabController(int count) {
    if (_tabController.length != count) {
      _tabController.dispose();
      _tabController = TabController(length: count, vsync: this);
    }
  }

  void _showAddOrEditWorkspaceDialog(BuildContext context, [Workspace? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    String selectedType = existing?.type ?? 'professional';
    int selectedColor = existing?.colorValue ?? 0xFF0D9488;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 20,
              right: 20,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      existing == null ? 'Create New Workspace' : 'Edit Workspace',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Workspace Name',
                    hintText: 'e.g. Strategic Advisory, Venture Studio',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: InputDecoration(
                    labelText: 'Workspace Category / Role',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'professional', child: Text('💼 Professional / Executive')),
                    DropdownMenuItem(value: 'personal', child: Text('🏠 Personal Life & Foundation')),
                    DropdownMenuItem(value: 'venture', child: Text('🚀 Technology Venture / Founder')),
                    DropdownMenuItem(value: 'advisory', child: Text('👔 Client Advisory & Consulting')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedType = val);
                  },
                ),
                const SizedBox(height: 14),
                const Text('Accent Theme Color', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    0xFF0D9488, // Teal
                    0xFF7C3AED, // Violet
                    0xFF0284C7, // Sky
                    0xFFDC2626, // Rose
                    0xFFD97706, // Amber
                    0xFF059669, // Emerald
                  ].map((colorVal) {
                    final isSel = selectedColor == colorVal;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedColor = colorVal),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Color(colorVal),
                          shape: BoxShape.circle,
                          border: isSel ? Border.all(color: Colors.black, width: 3) : null,
                        ),
                        child: isSel ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.darkCharcoal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;

                    final ws = Workspace(
                      id: existing?.id ?? 'ws-${_uuid.v4().substring(0, 8)}',
                      name: name,
                      type: selectedType,
                      colorValue: selectedColor,
                      isDefault: existing?.isDefault ?? false,
                    );

                    LocalDatabase.instance.upsertWorkspace(ws);
                    Navigator.of(ctx).pop();
                    setState(() {});
                  },
                  child: Text(
                    existing == null ? 'Create Workspace' : 'Save Changes',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddFollowUpDialog(BuildContext context) {
    final contactCtrl = TextEditingController();
    final deliverableCtrl = TextEditingController();
    DateTime dueDate = DateTime.now().add(const Duration(days: 3));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 20,
              right: 20,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Record Delegated Follow-Up (FR-WK-05)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contactCtrl,
                  decoration: InputDecoration(
                    labelText: 'Delegate / Recipient Name',
                    hintText: 'e.g. Lead Engineer, Finance Officer, Vendor',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: deliverableCtrl,
                  decoration: InputDecoration(
                    labelText: 'Expected Deliverable & Success Criteria',
                    hintText: 'e.g. Audit reconciliation sheet signed',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text('Due: ${AppDateUtils.formatShortDate(dueDate)}'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setModalState(() => dueDate = picked);
                  },
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.darkCharcoal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: () {
                    final contact = contactCtrl.text.trim();
                    final deliverable = deliverableCtrl.text.trim();
                    if (contact.isEmpty || deliverable.isEmpty) return;

                    final workspaces = LocalDatabase.instance.getWorkspaces();
                    final wsId = workspaces.isNotEmpty ? workspaces.first.id : AppConstants.workspaceBemsId;

                    final followUp = FollowUp(
                      id: _uuid.v4(),
                      workspaceId: wsId,
                      personName: contact,
                      commitment: deliverable,
                      requestedDate: DateTime.now(),
                      expectedDate: dueDate,
                      status: 'pending',
                    );

                    LocalDatabase.instance.upsertFollowUp(followUp);
                    Navigator.of(ctx).pop();
                    setState(() {});
                  },
                  child: const Text('Save Delegated Follow-Up', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: LocalDatabase.instance.changes,
      builder: (context, _) {
        final db = LocalDatabase.instance;
        final workspaces = db.getWorkspaces();
        final followUps = db.getFollowUps();

        _reinitTabController(workspaces.length + 1);

        return Scaffold(
          backgroundColor: AppTheme.creamCanvas,
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      MediaQuery.of(context).padding.top > 0 ? MediaQuery.of(context).padding.top + 16 : 56,
                      20,
                      20,
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
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.add, color: Colors.white, size: 16),
                                  label: const Text('Add Workspace', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.white.withOpacity(0.4)),
                                    backgroundColor: Colors.white.withOpacity(0.2),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  onPressed: () => _showAddOrEditWorkspaceDialog(context),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Professional Workspaces',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Segregated operational silos for Bems Group (COO), Henovate (Founder) & Custom Roles',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // TabBar Pill
                        Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            indicator: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelColor: AppTheme.darkCharcoal,
                            unselectedLabelColor: Colors.white,
                            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                            dividerColor: Colors.transparent,
                            tabs: [
                              ...workspaces.map((ws) => Tab(text: ws.name)),
                              const Tab(text: 'Delegated Follow-Ups ⏳'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                ...workspaces.map((ws) => _buildWorkspaceContent(context, ws, db)),
                _buildFollowUpsContent(context, followUps, db),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWorkspaceContent(BuildContext context, Workspace ws, LocalDatabase db) {
    final tasks = db.getTasks(workspaceId: ws.id);
    final pendingTasks = tasks.where((t) => t.status != TaskStatus.completed).toList();
    final completedTasks = tasks.where((t) => t.status == TaskStatus.completed).toList();
    final totalMins = pendingTasks.fold<int>(0, (sum, t) => sum + t.estimateMinutes);

    List<Task> displayedTasks = tasks;
    if (_taskFilter == 'active') displayedTasks = pendingTasks;
    if (_taskFilter == 'completed') displayedTasks = completedTasks;
    if (_taskFilter == 'priority') displayedTasks = tasks.where((t) => t.isTopPriority).toList();

    final completionPct = tasks.isNotEmpty ? (completedTasks.length / tasks.length) : 0.0;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Workspace Summary Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.floatingCardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Color(ws.colorValue),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ws.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.darkCharcoal),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.textSecondary),
                        tooltip: 'Edit Workspace',
                        onPressed: () => _showAddOrEditWorkspaceDialog(context, ws),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_task, color: AppTheme.coralPrimary),
                        tooltip: 'Add Task to Workspace',
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const QuickCaptureSheet(),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Role partition: ${ws.type.toUpperCase()} • ${tasks.length} total commitments',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 14),

              // Progress bar
              LinearProgressIndicator(
                value: completionPct,
                backgroundColor: const Color(0xFFF3F4F6),
                color: Color(ws.colorValue),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(completionPct * 100).toInt()}% commitments closed',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  Text(
                    '${(totalMins / 60).toStringAsFixed(1)} hrs active backlog',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('all', 'All (${tasks.length})'),
              const SizedBox(width: 8),
              _buildFilterChip('active', 'Active (${pendingTasks.length})'),
              const SizedBox(width: 8),
              _buildFilterChip('priority', 'Top Priority (${tasks.where((t) => t.isTopPriority).length})'),
              const SizedBox(width: 8),
              _buildFilterChip('completed', 'Done (${completedTasks.length})'),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Tasks list
        if (displayedTasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: AppTheme.floatingCardDecoration,
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.assignment_turned_in, size: 40, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  Text(
                    'No tasks matching this filter in ${ws.name}.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Task'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.coralPrimary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const QuickCaptureSheet(),
                      );
                    },
                  ),
                ],
              ),
            ),
          )
        else
          ...displayedTasks.map((t) => _buildTaskTile(context, t, db)),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSel = _taskFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSel,
      selectedColor: AppTheme.darkCharcoal,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
        color: isSel ? Colors.white : AppTheme.textPrimary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isSel ? Colors.transparent : const Color(0xFFE5E7EB)),
      ),
      onSelected: (_) => setState(() => _taskFilter = key),
    );
  }

  Widget _buildFollowUpsContent(BuildContext context, List<FollowUp> followUps, LocalDatabase db) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Follow-Up Banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF334155)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.softCardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Delegated Accountability',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Colors.white),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Follow-Up'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.darkCharcoal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => _showAddFollowUpDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Tracks who owes you deliverables across Bems Group, Henovate, and external contractors without cognitive load.',
                style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        if (followUps.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: AppTheme.floatingCardDecoration,
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.handshake_outlined, size: 44, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  const Text(
                    'No pending delegated follow-ups.',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap "+ Add Follow-Up" when you assign a deliverable to a colleague or contractor.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          )
        else
          ...followUps.map((f) {
            final isResolved = f.status == 'closed' || f.status == 'received';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: AppTheme.floatingCardDecoration,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: isResolved ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                  child: Icon(
                    isResolved ? Icons.check_circle : Icons.hourglass_top,
                    color: isResolved ? const Color(0xFF059669) : const Color(0xFFD97706),
                    size: 20,
                  ),
                ),
                title: Text(
                  f.personName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 3),
                    Text(f.commitment, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                    const SizedBox(height: 4),
                    Text(
                      'Due: ${AppDateUtils.formatShortDate(f.expectedDate)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                trailing: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: isResolved ? const Color(0xFFF3F4F6) : const Color(0xFFD1FAE5),
                    foregroundColor: isResolved ? Colors.grey : const Color(0xFF065F46),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    db.upsertFollowUp(
                      f.copyWith(
                        status: isResolved ? 'pending' : 'closed',
                      ),
                    );
                  },
                  child: Text(
                    isResolved ? 'Re-open' : 'Resolve',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildTaskTile(BuildContext context, Task t, LocalDatabase db) {
    final isDone = t.status == TaskStatus.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.floatingCardDecoration,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Checkbox(
          value: isDone,
          activeColor: AppTheme.coralPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          onChanged: (_) => db.toggleTaskComplete(t.id),
        ),
        title: Text(
          t.title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            decoration: isDone ? TextDecoration.lineThrough : null,
            color: isDone ? Colors.grey : AppTheme.darkCharcoal,
          ),
        ),
        subtitle: t.nextAction.isNotEmpty
            ? Text(t.nextAction, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))
            : null,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: t.isTopPriority ? const Color(0xFFFFECE5) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            t.isTopPriority ? 'TOP PRIORITY' : '${t.estimateMinutes}m',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: t.isTopPriority ? AppTheme.coralPrimary : AppTheme.darkCharcoal,
            ),
          ),
        ),
      ),
    );
  }
}
