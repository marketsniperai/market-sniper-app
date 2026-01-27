import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:market_sniper_app/theme/app_colors.dart';
import 'package:market_sniper_app/widgets/war_room/war_room_tile_wrapper.dart';
import 'package:http/http.dart' as http;
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
    _fetchIntegrity();
  }

  Future<void> _fetchIntegrity() async {
    try {
      const baseUrl = "http://10.0.2.2:8000"; // Android Emulator Localhost
      final response =
          await http.get(Uri.parse('$baseUrl/lab/os/iron/replay_integrity'));

      if (mounted) {
        setState(() {
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            bool corrupted = data['corrupted'] ?? false;
            bool truncated = data['truncated'] ?? false;
            if (corrupted || truncated) {
              _integritySafe = false;
              _integrityStatus = "RISK: ${corrupted ? 'CORRUPT' : 'TRUNCATED'}";
            } else {
              _integritySafe = true;
              _integrityStatus = "OK";
            }
          } else {
            _integrityStatus = "UNKNOWN (No Artifact)";
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _integrityStatus = "UNKNOWN (Net Err)");
    }
  }

  Future<void> _runReplay() async {
    if (!_integritySafe && widget.isFounder) {
      setState(() => _message = "BLOCKED: Integrity Risk");
      return;
    }

    setState(() {
      _isLoading = true;
      _status = "RUNNING";
      _message =
          "Replaying ${_selectedDate.toIso8601String().split('T')[0]}...";
    });

    try {
      const baseUrl = "http://10.0.2.2:8000";

      final response = await http.post(
        Uri.parse('$baseUrl/lab/replay/day'),
        headers: {
          "Content-Type": "application/json",
          if (widget.isFounder) "X-Founder-Key": "mz_founder_888"
        },
        body: jsonEncode(
            {"day_id": _selectedDate.toIso8601String().split('T')[0]}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _status = data['status'] ?? "UNKNOWN";
          _message = data['reason'] ?? "Replay complete";
        });
      } else {
        setState(() {
          _status = "FAILED";
          _message = "Server error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _status = "FAILED";
        _message = "Connection failed";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025, 1),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.neonCyan,
              onPrimary: AppColors.bgPrimary,
              surface: AppColors.surface1,
              onSurface: AppColors.textPrimary,
            ),
            dialogTheme:
                const DialogThemeData(backgroundColor: AppColors.surface1),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _status = "READY";
        _message = "Ready to replay ${picked.toIso8601String().split('T')[0]}";
      });
    }
  }

  Future<void> _showTimeMachine(BuildContext context) async {
    List<dynamic> history = [];
    try {
      const baseUrl = "http://10.0.2.2:8000";
      final response = await http
          .get(Uri.parse('$baseUrl/lab/replay/archive/tail?limit=30'));
      if (response.statusCode == 200) {
        history = jsonDecode(response.body);
      }
    } catch (e) {
      // quiet fail
    }

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
              child: Text(
                "TIME MACHINE ARCHIVE (LAST 30)",
                style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textPrimary, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(color: AppColors.borderSubtle, height: 1),
            Expanded(
              child: history.isEmpty
                  ? Center(
                      child: Text("No Replay History",
                          style:
                              GoogleFonts.inter(color: AppColors.textDisabled)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: history.length,
                      separatorBuilder: (c, i) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = history[index];
                        final ts = item['timestamp_utc'] ?? "";
                        final day = item['day_id'] ?? "UNKNOWN";
                        final status = item['status'] ?? "UNKNOWN";
                        final summary = item['summary'] ?? "";

                        Color statusColor = AppColors.textSecondary;
                        if (status == "SUCCESS") {
                          statusColor = AppColors.marketBull;
                        }
                        if (status == "FAILED") {
                          statusColor = AppColors.marketBear;
                        }
                        if (status == "UNAVAILABLE") {
                          statusColor = AppColors.stateStale;
                        }

                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (day != "UNKNOWN") {
                                try {
                                  _selectedDate = DateTime.parse(day);
                                  _status = "READY";
                                  _message = "Selected from Time Machine";
                                } catch (e) {}
                              }
                            });
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface1,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(day,
                                        style: GoogleFonts.jetBrainsMono(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.bold)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                            color:
                                                statusColor.withOpacity(0.3)),
                                      ),
                                      child: Text(status,
                                          style: GoogleFonts.jetBrainsMono(
                                              fontSize: 10,
                                              color: statusColor)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(summary,
                                    style: GoogleFonts.inter(
                                        color: AppColors.textSecondary,
                                        fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                Text(ts,
                                    style: GoogleFonts.jetBrainsMono(
                                        color: AppColors.textDisabled,
                                        fontSize: 10)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRollback() async {
    final TextEditingController confirmCtrl = TextEditingController();

    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              backgroundColor: AppColors.surface1,
              title: Row(children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.marketBear),
                const SizedBox(width: 8),
                Text("DANGER: OS ROLLBACK",
                    style:
                        GoogleFonts.jetBrainsMono(color: AppColors.marketBear))
              ]),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      "This will revert Iron OS state to the last Known Good (LKG) snapshot.",
                      style: GoogleFonts.inter(color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  Text("Type 'ROLLBACK' to confirm:",
                      style: GoogleFonts.jetBrainsMono(
                          color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmCtrl,
                    style:
                        GoogleFonts.jetBrainsMono(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        focusedBorder: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: AppColors.marketBear)),
                        hintText: "ROLLBACK",
                        hintStyle: GoogleFonts.jetBrainsMono(
                            color: AppColors.textDisabled)),
                  )
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("CANCEL",
                        style: GoogleFonts.jetBrainsMono(
                            color: AppColors.textSecondary))),
                TextButton(
                    onPressed: () {
                      if (confirmCtrl.text == "ROLLBACK") {
                        Navigator.pop(context);
                        _executeRollback();
                      }
                    },
                    child: Text("CONFIRM",
                        style: GoogleFonts.jetBrainsMono(
                            color: AppColors.marketBear))),
              ],
            ));
  }

  Future<void> _executeRollback() async {
    setState(() {
      _isLoading = true;
      _status = "ROLLBACK";
      _message = "Initiating Rollback Procedure...";
    });

    try {
      const baseUrl = "http://10.0.2.2:8000";

      final response = await http.post(
        Uri.parse('$baseUrl/lab/os/rollback'),
        headers: {
          "Content-Type": "application/json",
          if (widget.isFounder) "X-Founder-Key": "mz_founder_888"
        },
        body: jsonEncode(
            {"target_hash": "LATEST_LKG", "reason": "Founder Manual Trigger"}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _status = data['status'] ?? "UNKNOWN";
          _message = data['reason'] ?? "Rollback command sent";
        });
      } else {
        setState(() {
          _status = "FAILED";
          _message = "Rollback Error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _status = "FAILED";
        _message = "Network Error";
      });
    } finally {
      setState(() => _isLoading = false);
    }
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
