import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../models/calendar/economic_calendar_model.dart';
import '../../widgets/calendar_event_card.dart';
import '../../services/api_client.dart'; // HF35
import '../../theme/app_colors.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // Mode state
  bool _isWeekly = false; // default false -> Daily

  // Data State
  EconomicCalendarViewModel _data = EconomicCalendarViewModel.offline();
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      if (mounted) setState(() => _isLoading = true);
      // Use ApiClient (Service Locator or direct import)
      // Assuming simple instantiation for now or provider if available.
      // In this codebase, we often see ApiClient().fetch... or similar.
      // Let's import ApiClient.
      final payload = await ApiClient().fetchEconomicCalendar(); 
      final vm = EconomicCalendarViewModel.fromJson(payload);
      
      if (mounted) {
        setState(() {
          _data = vm;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgPrimary,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSelector(),
            Expanded(
              child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: AppColors.neonCyan))
                  : _data.events.isEmpty 
                      ? _buildEmptyState() 
                      : _buildEventList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final timeStr = DateFormat('HH:mm').format(_data.asOfUtc);
    Color freshnessColor;
    String freshnessLabel;

    switch (_data.freshness) {
      case CalendarFreshness.live:
        freshnessColor = AppColors.stateLive;
        freshnessLabel = "LIVE";
        break;
      case CalendarFreshness.delayed:
      case CalendarFreshness.stale:
        freshnessColor = AppColors.stateStale;
        freshnessLabel = "DATA DELAYED";
        break;
      case CalendarFreshness.offline:
        freshnessColor = AppColors.textDisabled;
        freshnessLabel = "OFFLINE";
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ECONOMIC CALENDAR",
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: freshnessColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border:
                      Border.all(color: freshnessColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  freshnessLabel,
                  style: TextStyle(
                      color: freshnessColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "SOURCE: ${_data.source.name.toUpperCase()} • AS OF $timeStr UTC",
            style: GoogleFonts.robotoMono(
              color: AppColors.textDisabled,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          _buildSelectorOption("DAILY", !_isWeekly),
          _buildSelectorOption("WEEKLY", _isWeekly),
        ],
      ),
    );
  }

  Widget _buildSelectorOption(String label, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (label == "WEEKLY" && !_isWeekly) setState(() => _isWeekly = true);
          if (label == "DAILY" && _isWeekly) setState(() => _isWeekly = false);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.surface2 : AppColors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isActive) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.neonCyan,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  color:
                      isActive ? AppColors.textPrimary : AppColors.textDisabled,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool isOffline = _data.freshness == CalendarFreshness.offline;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today,
              size: 48, color: AppColors.textDisabled.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            isOffline ? "Calendar unavailable" : "No high-impact events today",
            style: GoogleFonts.inter(color: AppColors.textDisabled),
          ),
          if (isOffline)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "System is offline",
                style: GoogleFonts.inter(
                    color: AppColors.textDisabled, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    // Basic list for now
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _data.events.length,
      itemBuilder: (context, index) =>
          CalendarEventCard(event: _data.events[index]),
    );
  }
}
