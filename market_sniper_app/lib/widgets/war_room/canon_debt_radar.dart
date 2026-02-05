import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:crypto/crypto.dart'; // V2.1 Fingerprint
import '../../config/app_config.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class CanonDebtRadar extends StatefulWidget {
  const CanonDebtRadar({super.key});

  @override
  State<CanonDebtRadar> createState() => _CanonDebtRadarState();
}

class _CanonDebtRadarState extends State<CanonDebtRadar> {
  bool _loading = true;
  bool _unavailable = false;
  Map<String, dynamic>? _index;
  Map<String, dynamic>? _snapshot;
  List<dynamic> _modules = [];
  
  // V2: Delta Engine
  Map<String, dynamic> _delta = {
    'added': [],
    'removed': [],
    'changed': [],
    'is_valid': false,
  };

  // V2.1: Fingerprint Guard
  String? _calculatedHash;
  String? _indexHash;
  String? _snapshotHash;
  String _integrityStatus = "VALIDATING"; // STABLE, DRIFT, NO_BASELINE, INCONSISTENT

  // Filters
  String? _filterModule;
  String? _filterKind;
  String? _filterPriority;
  String? _filterImpact;
  
  // V2: Sorting & New Toggle
  String _sortBy = "Priority"; 
  bool _showNewOnly = false;
  bool _showAllStates = false; // V2.1: Default to Active Debt Only (OPEN/IN_PROGRESS)
  
  // ignore: unused_field
  String _dataSourceUsed = "UNKNOWN";

  @override
  void initState() {
    super.initState();
    // D56.01.5: Snapshot-Only Enforcement. No internal fetching.
    // If pendingIndexSnapshot is passed (future), we use it. 
    // Otherwise, we remain UNAVAILABLE.
    _loading = false;
    _unavailable = true; 
    _dataSourceUsed = "SNAPSHOT_ONLY_WAITING";
    
    // Future V3: Hydrate from `widget.pendingIndexSnapshot` if added to USP.
  }

  // Legacy fetch removed for D56.01.5 compliance.
  // Future implementation should pass data via constructor.

  
  void _computeIntegrity() {
      if (_index == null) return;
      
      // 1. Calculate Hash of loaded items
      final allItems = <dynamic>[];
      for(var m in _modules) {
          allItems.addAll((m['items'] as List?)?.cast<dynamic>() ?? const []);
      }
      
      // Sort deterministically by ID (critical for SHA consistency with Python)
      allItems.sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));
      
      final buffer = StringBuffer();
      for (var it in allItems) {
          // Normalize Impact
          final impactList = (it['impact_area'] as List?)?.cast<String>() ?? [];
          impactList.sort();
          final impactStr = impactList.join(",");
          
          // Origin (first only)
          final origins = (it['origins'] as List?) ?? [];
          String originStr = "";
          if (origins.isNotEmpty) {
             originStr = "${origins[0]['path']}:${origins[0]['locator']}";
          }
          
          // Canonical String: id|module|kind|priority|impact|effort|status|origin
          // Must match Python generator exactly
          buffer.write("${it['id']}|${it['module_id']}|${it['kind']}|${it['priority']}|${impactStr}|${it['estimated_effort']}|${it['status']}|$originStr");
          // Python uses "\n".join, so we need a separator if we iterate, OR add \n after each EXCEPT last?
          // Actually Python: full_str = "\n".join(canonical_items)
          // So we need to join with \n.
          buffer.write("\n");
      }
      
      // Remove trailing newline if loop added it
      String fullStr = buffer.toString();
      if (fullStr.isNotEmpty && fullStr.endsWith("\n")) {
         fullStr = fullStr.substring(0, fullStr.length - 1);
      }
      
      final digest = sha256.convert(utf8.encode(fullStr));
      _calculatedHash = digest.toString();
      
      // 2. Compare
      _indexHash = _index?['fingerprint']?['hash'];
      _snapshotHash = _snapshot?['fingerprint']?['hash'];
      
      if (_snapshotHash == null) {
          _integrityStatus = "NO_BASELINE";
      } else if (_calculatedHash != _indexHash) {
          _integrityStatus = "INCONSISTENT"; // Client calc != Server claim
      } else if (_calculatedHash != _snapshotHash) {
          _integrityStatus = "DRIFT_DETECTED";
      } else {
          _integrityStatus = "STABLE";
      }
  }

  void _handleError() {
    if (mounted) {
      setState(() {
        _unavailable = true;
        _loading = false;
      });
    }
  }

  void _computeDelta() {
    if (_index == null || _snapshot == null) return;
    
    // Flatten current items
    final currentItems = <String, dynamic>{};
    for (var m in _modules) {
      final items = (m['items'] as List?) ?? [];
      for (var i in items) {
        currentItems[i['id']] = i;
      }
    }

    // Flatten snapshot items
    final snapItems = <String, dynamic>{};
    final snapList = <dynamic>[];
    
    // V2.1: Snapshot structure check (Root items vs Modules?)
    // Python generator V2 puts items in 'modules'.
    // If we copied index v2 to snapshot, snapshot has 'modules'.
    if (_snapshot!.containsKey('modules')) {
        final mods = (_snapshot!['modules'] as List?) ?? [];
        for (var m in mods) {
            snapList.addAll((m['items'] as List?) ?? []);
        }
    } else if (_snapshot!.containsKey('items')) {
        // Fallback for V1/V2 stub
        snapList.addAll((_snapshot!['items'] as List?) ?? []);
    }

    for (var s in snapList) {
      snapItems[s['id']] = s;
    }

    final added = <dynamic>[];
    final removed = <dynamic>[];
    final changed = <dynamic>[];

    // Detect Added & Changed
    currentItems.forEach((id, item) {
      if (!snapItems.containsKey(id)) {
        added.add(item);
      } else {
        // Simple change detection
        if (item['status'] != snapItems[id]['status']) {
          changed.add(item);
        }
      }
    });

    // Detect Removed
    snapItems.forEach((id, item) {
      if (!currentItems.containsKey(id)) {
        removed.add(item);
      }
    });

    _delta = {
      'added': added,
      'removed': removed,
      'changed': changed,
      'is_valid': true,
    };
  }

  List<dynamic> _getFilteredItems(List<dynamic> items) {
    var filtered = items.where((item) {
      if (_showNewOnly) {
        // Must be in _delta['added']
        final added = _delta['added'] as List;
        final isNew = added.any((x) => x['id'] == item['id']);
        if (!isNew) return false;
      }
      
      if (_filterKind != null && item['kind'] != _filterKind) return false;
      if (_filterPriority != null && item['priority'] != _filterPriority) return false;
      if (_filterImpact != null) {
        final impacts = (item['impact_area'] as List?)?.cast<String>() ?? [];
        if (!impacts.contains(_filterImpact)) return false;
      }
      
      // Status Filter (Canon Rule: Active Debt = OPEN or IN_PROGRESS)
      if (!_showAllStates) {
          final status = item['status'] ?? "OPEN";
          if (status != "OPEN" && status != "IN_PROGRESS") return false;
      }

      return true;
    }).toList();
    
    // Sort
    filtered.sort((a, b) {
      switch (_sortBy) {
        case "Priority":
           int pA = _prioVal(a['priority']);
           int pB = _prioVal(b['priority']);
           return pB.compareTo(pA); // Descending
           
        case "Last Seen":
           final tA = a['last_seen_at_utc'] ?? "";
           final tB = b['last_seen_at_utc'] ?? "";
           return tB.compareTo(tA); // Newest first
           
        case "Effort (L->S)":
             int eA = _effortVal(a['estimated_effort']);
             int eB = _effortVal(b['estimated_effort']);
             return eB.compareTo(eA);

        case "Effort (S->L)":
             int eA = _effortVal(a['estimated_effort']);
             int eB = _effortVal(b['estimated_effort']);
             return eA.compareTo(eB);
             
        default:
          return 0;
      }
    });

    return filtered;
  }
  
  int _prioVal(String? p) {
    if (p == "HIGH") return 3;
    if (p == "MED") return 2;
    return 1;
  }
  
  int _effortVal(String? e) {
     if (e == "L") return 3;
     if (e == "M") return 2;
     return 1;
  }
  
  Color _getStatusColor() {
      switch(_integrityStatus) {
          case "STABLE": return AppColors.stateLive;
          case "DRIFT_DETECTED": return AppColors.stateStale; // Yellow/Amber
          case "INCONSISTENT": return AppColors.stateLocked;
          case "NO_BASELINE": return AppColors.textDisabled;
          default: return AppColors.textSecondary;
      }
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.isFounderBuild) return const SizedBox.shrink();
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.neonCyan));
    
    // Header Stats
    final counts = _index?['meta']?['counts'] ?? {};
    final totalPending = counts['pending_total'] ?? 0;
    
    final int addedCount = (_delta['added'] as List?)?.length ?? 0;

    return Container(
      margin: const EdgeInsets.only(top: 32),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // V2.1 Fingerprint Strip
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
             decoration: BoxDecoration(
                 color: _getStatusColor().withOpacity(0.1),
                 borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                 border: Border(bottom: BorderSide(color: _getStatusColor().withOpacity(0.3))),
             ),
             child: Row(
               children: [
                   Icon(Icons.fingerprint, size: 14, color: _getStatusColor()),
                   const SizedBox(width: 8),
                   Text(
                       "GUARD: $_integrityStatus", 
                       style: AppTypography.caption(context).copyWith(
                           color: _getStatusColor(), fontWeight: FontWeight.bold, fontSize: 10
                       )
                   ),
                   const Spacer(),
                   if (_calculatedHash != null)
                     Text(
                         "HASH: ${_calculatedHash!.substring(0, 6)}...",
                         style: AppTypography.caption(context).copyWith(
                             fontFamily: GoogleFonts.robotoMono().fontFamily,
                             color: _getStatusColor(),
                             fontSize: 10
                         ),
                     ),
               ],
             ),
          ),
        
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "CANON DEBT RADAR V2.1",
                      style: AppTypography.headline(context).copyWith(
                        color: AppColors.neonCyan,
                        fontSize: 16,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Institutional visibility + Integrity Guard",
                      style: AppTypography.caption(context).copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (_unavailable)
                  Container(
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     decoration: BoxDecoration(
                       color: AppColors.stateLocked.withOpacity(0.2),
                       borderRadius: BorderRadius.circular(4),
                       border: Border.all(color: AppColors.stateLocked),
                     ),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.end,
                       children: [
                         Text("UNAVAILABLE", style: AppTypography.caption(context).copyWith(color: AppColors.stateLocked)),
                         if (AppConfig.isFounderBuild)
                            Text(_dataSourceUsed.length > 30 ? "...${_dataSourceUsed.substring(_dataSourceUsed.length - 30)}" : _dataSourceUsed, 
                                style: TextStyle(fontSize: 8, color: AppColors.textDisabled, fontFamily: GoogleFonts.robotoMono().fontFamily)
                            )
                       ],
                     ),
                  )
                else
                  Row(
                    children: [
                       if (addedCount > 0)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              "+$addedCount NEW",
                              style: AppTypography.caption(context).copyWith(color: AppColors.neonCyan, fontWeight: FontWeight.bold),
                            ),
                          ),
                       Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                         Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surface2,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.neonCyan.withOpacity(0.3)),
                            ),
                            child: Text(
                              "READ-ONLY",
                              style: AppTypography.caption(context).copyWith(
                                color: AppColors.neonCyan,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$totalPending PENDING",
                            style: AppTypography.caption(context).copyWith(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
          
          if (!_unavailable) ...[
             const Divider(color: AppColors.borderSubtle, height: 1),
            // Filter Bar with Sort and Toggle
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Status Toggle (Active Debt vs All)
                  FilterChip(
                    label: Text(_showAllStates ? "SHOW: ALL (AUDIT)" : "SHOW: ACTIVE DEBT"),
                    selected: _showAllStates,
                    onSelected: (v) => setState(() => _showAllStates = v),
                    checkmarkColor: AppColors.textPrimary,
                    selectedColor: AppColors.stateLocked.withOpacity(0.3),
                    labelStyle: TextStyle(
                            fontSize: 10,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontFamily: GoogleFonts.robotoMono().fontFamily
                    ),
                    backgroundColor: AppColors.surface2,
                  ),
                  const SizedBox(width: 12),
                  // New Filter
                  FilterChip(
                    label: Text("NEW SINCE SEAL ($addedCount)"),
                    selected: _showNewOnly,
                    onSelected: (v) => setState(() => _showNewOnly = v),
                    checkmarkColor: AppColors.surface1,
                    selectedColor: AppColors.neonCyan,
                    labelStyle: TextStyle(
                            fontSize: 10, 
                            color: _showNewOnly ? AppColors.surface1 : AppColors.textPrimary,
                            fontFamily: GoogleFonts.robotoMono().fontFamily
                    ),
                    backgroundColor: AppColors.surface2,
                  ),
                  const SizedBox(width: 12),
                  // Sort
                  DropdownButton<String>(
                    value: _sortBy,
                    dropdownColor: AppColors.surface2,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.sort, color: AppColors.textSecondary, size: 16),
                    style: AppTypography.caption(context).copyWith(color: AppColors.textPrimary),
                    items: const [
                      DropdownMenuItem(value: "Priority", child: Text("Priority (High First)")),
                      DropdownMenuItem(value: "Last Seen", child: Text("Last Seen (Newest)")),
                      DropdownMenuItem(value: "Effort (L->S)", child: Text("Effort (L->S)")),
                      DropdownMenuItem(value: "Effort (S->L)", child: Text("Effort (S->L)")),
                    ],
                    onChanged: (v) => setState(() => _sortBy = v!),
                  ),
                  const SizedBox(width: 12),
                  _buildFilterDropdown("Module", _filterModule, _getModulesList(), (v) => setState(() => _filterModule = v)),
                  const SizedBox(width: 8),
                  _buildFilterDropdown("Kind", _filterKind, const ["PENDING_FEATURE", "PENDING_TECH_DEBT", "PENDING_GOVERNANCE", "PENDING_BUG"], (v) => setState(() => _filterKind = v)),
                  const SizedBox(width: 8),
                  _buildFilterDropdown("Priority", _filterPriority, const ["HIGH", "MED", "LOW"], (v) => setState(() => _filterPriority = v)),
                  const SizedBox(width: 8),
                  _buildFilterDropdown("Impact", _filterImpact, const ["Reliability", "UX", "Revenue", "Safety", "Governance"], (v) => setState(() => _filterImpact = v)),
                  if (_hasActiveFilters())
                    IconButton(
                      icon: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                      onPressed: () => setState(() {
                        _filterModule = null;
                        _filterKind = null;
                        _filterPriority = null;
                        _filterImpact = null;
                        _showNewOnly = false;
                        _showAllStates = false;
                      }),
                      tooltip: "Reset",
                    ),
                ],
              ),
            ),
            
            const Divider(color: AppColors.borderSubtle, height: 1),

            // Modules List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _modules.length,
              itemBuilder: (context, index) {
                final module = _modules[index];
                final modId = module['module_id'];
                if (_filterModule != null && _filterModule != modId) return const SizedBox.shrink();

                final items = (module['items'] as List?) ?? [];
                final filteredItems = _getFilteredItems(items);

                if (filteredItems.isEmpty && (_hasActiveFilters() || _showNewOnly)) return const SizedBox.shrink();

                return ExpansionTile(
                  key: PageStorageKey(modId),
                  collapsedIconColor: AppColors.textSecondary,
                  iconColor: AppColors.neonCyan,
                  initiallyExpanded: _showNewOnly && filteredItems.isNotEmpty,
                  title: Row(
                    children: [
                      Text(
                        modId.toString(),
                        style: AppTypography.body(context).copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surface2,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "${filteredItems.length}",
                          style: AppTypography.caption(context).copyWith(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  children: filteredItems.map<Widget>((item) => _buildItemRow(item)).toList(),
                );
              },
            ),
          ] else
            Padding(
               padding: const EdgeInsets.all(32),
               child: Center(
                 child: Text(
                   "CANON DEBT INDEX UNAVAILABLE",
                   style: AppTypography.caption(context).copyWith(color: AppColors.textDisabled),
                 ),
               ),
            ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _filterModule != null || _filterKind != null || _filterPriority != null || _filterImpact != null;
  }

  List<String> _getModulesList() {
    return _modules.map((m) => m['module_id'] as String).toSet().toList()..sort();
  }

  Widget _buildFilterDropdown(String label, String? value, List<String> options, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: value != null ? AppColors.neonCyan.withOpacity(0.1) : AppColors.surface2,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: value != null ? AppColors.neonCyan.withOpacity(0.5) : AppColors.borderSubtle),
      ),
      child: DropdownButton<String>(
        value: value,
        hint: Text(label, style: AppTypography.caption(context).copyWith(color: AppColors.textSecondary)),
        dropdownColor: AppColors.surface2,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 16),
        style: AppTypography.caption(context).copyWith(color: AppColors.textPrimary),
        items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildItemRow(dynamic item) {
    final title = item['title'] ?? "Untitled";
    final kind = item['kind'] ?? "UNKNOWN";
    final priority = item['priority'] ?? "MED";
    final effort = item['estimated_effort'] ?? "M";
    final desc = item['description'] ?? "";
    final id = item['id'];

    Color kindColor = AppColors.textSecondary;
    if (kind == "PENDING_FEATURE") kindColor = AppColors.neonCyan; // Was neonBlue
    if (kind == "PENDING_TECH_DEBT") kindColor = AppColors.stateStale; // Was purpleAccent
    if (kind == "PENDING_BUG") kindColor = AppColors.stateLocked;
    
    
    // Fallback colors if tokens missing
    if (kindColor == Colors.transparent) kindColor = AppColors.stateStale; // Fallback

    // Delta highlight
    final bool isAdded = (_delta['added'] as List?)?.any((x) => x['id'] == id) ?? false;

    return Container(
      decoration: BoxDecoration(
        color: isAdded ? AppColors.neonCyan.withOpacity(0.05) : null,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle.withOpacity(0.5))),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTypography.body(context).copyWith(fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _buildBadge(kind.split('_').last, kindColor),
             if (isAdded) ...[
                const SizedBox(width: 8),
                _buildBadge("NEW", AppColors.neonCyan),
             ]
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             const SizedBox(height: 4),
             Text(
               desc,
               style: AppTypography.caption(context).copyWith(color: AppColors.textSecondary, fontSize: 11),
               maxLines: 2,
               overflow: TextOverflow.ellipsis,
             ),
             const SizedBox(height: 6),
             Row(
               children: [
                 _buildChip("PRIORITY: $priority", _getPriorityColor(priority)),
                 const SizedBox(width: 6),
                 _buildChip("EFFORT: $effort", AppColors.textDisabled),
               ],
             ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String p) {
    if (p == "HIGH") return AppColors.stateLocked;
    if (p == "MED") return AppColors.stateStale;
    return AppColors.textSecondary;
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

   Widget _buildChip(String text, Color color) {
    return Text(
      text,
      style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600, fontFamily: GoogleFonts.robotoMono().fontFamily),
    );
  }
}
