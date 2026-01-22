import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:market_sniper_app/theme/app_colors.dart';
import 'package:market_sniper_app/widgets/war_room/war_room_tile_wrapper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:market_sniper_app/services/api_service.dart'; // Assume exists for base URL

class ReplayControlTile extends StatefulWidget {
  final bool isFounder;
  
  const ReplayControlTile({Key? key, this.isFounder = false}) : super(key: key);

  @override
  _ReplayControlTileState createState() => _ReplayControlTileState();
}

class _ReplayControlTileState extends State<ReplayControlTile> {
  String _status = "READY"; // READY, RUNNING, SUCCESS, FAILED, UNAVAILABLE
  String _message = "Select day to replay";
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  Future<void> _runReplay() async {
    setState(() {
      _isLoading = true;
      _status = "RUNNING";
      _message = "Replaying ${_selectedDate.toIso8601String().split('T')[0]}...";
    });

    try {
      // Direct call or via ApiService - using direct http for clarity in this stub logic
      // In real app, verify base URL source. 
      // Leveraging existing Release Guard logic if possible, or just standard http.
      // For D41.03 we assume standard deviation is acceptable for this isolated lab tool.
       
      // Using localhost for dev/lab loop if not PROD
      final baseUrl = "http://127.0.0.1:8000"; 
      
      final response = await http.post(
        Uri.parse('$baseUrl/lab/replay/day'),
        headers: {
            "Content-Type": "application/json",
            if (widget.isFounder) "X-Founder-Key": "mz_founder_888" 
        },
        body: jsonEncode({
          "day_id": _selectedDate.toIso8601String().split('T')[0]
        }),
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
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.background,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
            dialogBackgroundColor: AppColors.surface,
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

  Color _getStatusColor() {
    switch (_status) {
      case "SUCCESS": return AppColors.success;
      case "FAILED": return AppColors.error;
      case "UNAVAILABLE": return AppColors.warning;
      case "RUNNING": return AppColors.primary;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WarRoomTileWrapper(
      title: "INSTITUTIONAL DAY REPLAY",
      height: 160, // Fixed height for consistency
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.divider),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDate.toIso8601String().split('T')[0],
                          style: GoogleFonts.jetbrainsMono(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                        Icon(Icons.calendar_today, color: AppColors.primary, size: 16),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: (widget.isFounder && !_isLoading) ? AppColors.primary.withOpacity(0.2) : AppColors.surface,
                    border: Border.all(
                      color: (widget.isFounder && !_isLoading) ? AppColors.primary : AppColors.divider.withOpacity(0.3)
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _isLoading 
                    ? SizedBox(
                        width: 16, height: 16, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)
                      )
                    : Text(
                        "RUN",
                        style: GoogleFonts.jetbrainsMono(
                          color: widget.isFounder ? AppColors.primary : AppColors.textSecondary,
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
            color: AppColors.background.withOpacity(0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: _getStatusColor(),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _status,
                      style: GoogleFonts.jetbrainsMono(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _message,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
