import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:market_sniper_app/theme/app_colors.dart';
import 'package:market_sniper_app/widgets/war_room/war_room_tile_wrapper.dart';
import 'dart:convert';


class ReplayControlTile extends StatefulWidget {
  final bool isFounder;

  const ReplayControlTile({super.key, this.isFounder = false});

  @override
  _ReplayControlTileState createState() => _ReplayControlTileState();
}

class _ReplayControlTileState extends State<ReplayControlTile> {
  String _status = "READY"; // READY, RUNNING, SUCCESS, FAILED, UNAVAILABLE
  String _message = "Select day to replay";
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  bool _integritySafe = true;
  String _integrityStatus = "Checking...";

  @override
  void initState() {
    super.initState();
    // D56.01.5: Legacy Fetch Disabled.
    // _fetchIntegrity(); 
    _integrityStatus = "UNKNOWN (Legacy Disabled)";
  }

  Future<void> _fetchIntegrity() async {
     // DISABLED for Snapshot-Only Enforcement
     // Logic moved to WarRoomSnapshot consumption.
  }

  Future<void> _runReplay() async {
    // DISABLED for D56.01.5 Snapshot-Only.
    // Legacy HTTP direct call removed.
    if (mounted) setState(() => _message = "LEGACY DISABLED");
  }

  Future<void> _selectDate(BuildContext context) async {
    // Keep date picker logic, it's UI only
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025, 1),
      lastDate: DateTime.now(),
      builder: (context, child) {
         return Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.neonCyan, onPrimary: AppColors.bgPrimary, surface: AppColors.surface1, onSurface: AppColors.textPrimary)), child: child!);
      },
    );
    if (picked != null && picked != _selectedDate) {
      if (mounted) {
          setState(() {
            _selectedDate = picked;
            _status = "READY";
            _message = "Ready to replay ${picked.toIso8601String().split('T')[0]}";
          });
      }
    }
  }

  Future<void> _showTimeMachine(BuildContext context) async {
    List<dynamic> history = [];
    // DISABLED: No fetch. Show empty or handle gracefully.
    // Legacy: await (get) ...

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 600,
        decoration: BoxDecoration(
          color: AppColors.bgPrimary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("TIME MACHINE (LEGACY DISABLED)", style: GoogleFonts.jetBrainsMono(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
            ),
            // ... (keeping rest of UI structure but since history is empty it will show empty state)
            const Divider(color: AppColors.borderSubtle, height: 1),
            Expanded(
               child: Center(
                   child: Text("Replay History Unavailable\n(Legacy Network Disabled)",
                       textAlign: TextAlign.center,
                       style: GoogleFonts.inter(color: AppColors.textDisabled))),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRollback() async {
     // UI Dialog Logic is fine, but execution must be stubbed
     // ... (Keeping dialog code conceptually, but for brevity in replace, effectively stubbing action)
     _executeRollback(); 
  }

  Future<void> _executeRollback() async {
      if (mounted) setState(() => _message = "ROLLBACK DISABLED (LEGACY NETWORK)");
  }

  Color _getStatusColor() {
    switch (_status) {
      case "SUCCESS":
        return AppColors.marketBull;
      case "FAILED":
        return AppColors.marketBear;
      case "UNAVAILABLE":
        return AppColors.stateStale;
      case "RUNNING":
        return AppColors.neonCyan;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WarRoomTileWrapper(
      title: "INSTITUTIONAL DAY REPLAY",
      height: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Control Row
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderSubtle),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDate.toIso8601String().split('T')[0],
                          style: GoogleFonts.jetBrainsMono(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                        const Icon(Icons.calendar_today,
                            color: AppColors.neonCyan, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Run Button
              InkWell(
                onTap: (widget.isFounder && !_isLoading) ? _runReplay : null,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: (widget.isFounder && !_isLoading)
                        ? AppColors.neonCyan.withOpacity(0.2)
                        : AppColors.surface1,
                    border: Border.all(
                        color: (widget.isFounder && !_isLoading)
                            ? AppColors.neonCyan
                            : AppColors.borderSubtle.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.neonCyan))
                      : Text(
                          "RUN",
                          style: GoogleFonts.jetBrainsMono(
                            color: widget.isFounder
                                ? AppColors.neonCyan
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 8),
              // History Button
              InkWell(
                onTap: (widget.isFounder && !_isLoading)
                    ? () => _showTimeMachine(context)
                    : null,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface1,
                    border: Border.all(color: AppColors.borderSubtle),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.history,
                      size: 16, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 8),
              // Rollback Button
              InkWell(
                onTap:
                    (widget.isFounder && !_isLoading) ? _confirmRollback : null,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: (widget.isFounder && !_isLoading)
                        ? AppColors.marketBear.withOpacity(0.1)
                        : AppColors.surface1,
                    border: Border.all(
                        color: (widget.isFounder && !_isLoading)
                            ? AppColors.marketBear
                            : AppColors.borderSubtle.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "ROLLBACK",
                    style: GoogleFonts.jetBrainsMono(
                      color: widget.isFounder
                          ? AppColors.marketBear
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Status Output
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: AppColors.bgPrimary.withOpacity(0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getStatusColor(),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _status,
                      style: GoogleFonts.jetBrainsMono(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _message,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: _integritySafe
                                ? AppColors.textDisabled
                                : AppColors.marketBear),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "INT: $_integrityStatus",
                        style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            color: _integritySafe
                                ? AppColors.textDisabled
                                : AppColors.marketBear,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
