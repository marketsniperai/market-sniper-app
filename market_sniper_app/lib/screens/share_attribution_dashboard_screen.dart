import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../logic/share/share_attribution_aggregator.dart';

class ShareAttributionDashboardScreen extends StatefulWidget {
  const ShareAttributionDashboardScreen({super.key});

  @override
  State<ShareAttributionDashboardScreen> createState() => _ShareAttributionDashboardScreenState();
}

class _ShareAttributionDashboardScreenState extends State<ShareAttributionDashboardScreen> {
  ShareAttributionData? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await ShareAttributionAggregator.aggregate();
    if (mounted) {
      setState(() {
        _data = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeepVoid,
      appBar: AppBar(
        title: Text("GROWTH BLOOMBERG", style: AppTypography.headline(context).copyWith(letterSpacing: 1.5)),
        backgroundColor: AppColors.bgDeepVoid,
        elevation: 0,
        actions: [
          if (_data != null)
             Padding(
               padding: const EdgeInsets.only(right: 16),
               child: Chip(
                 label: Text(_data!.status, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                 backgroundColor: _getStatusColor(_data!.status).withValues(alpha: 0.2),
                 labelStyle: TextStyle(color: _getStatusColor(_data!.status)),
                 side: BorderSide.none,
                 visualDensity: VisualDensity.compact,
               ),
             )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.accentCyan))
        : _data == null || _data!.status == "NO_DATA"
           ? Center(child: Text("NO TELEMETRY DETECTED", style: AppTypography.title(context).copyWith(color: AppColors.textDisabled)))
           : SingleChildScrollView(
               padding: const EdgeInsets.all(16),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   _buildKpiGrid(),
                   const SizedBox(height: 32),
                   _buildDailyTable(),
                   const SizedBox(height: 32),
                   _buildSurfaceTable(),
                 ],
               ),
             ),
    );
  }

  Color _getStatusColor(String status) {
    switch(status) {
      case "LIVE": return AppColors.stateLive;
      case "PARTIAL": return AppColors.accentCyan; // Fallback
      default: return AppColors.textDisabled;
    }
  }

  Widget _buildKpiGrid() {
    return GridView.count(
       crossAxisCount: 3,
       shrinkWrap: true,
       physics: const NeverScrollableScrollPhysics(),
       childAspectRatio: 1.4,
       crossAxisSpacing: 12,
       mainAxisSpacing: 12,
       children: [
         _buildKpiCard("Shares 24h", "${_data!.shares24h}"),
         _buildKpiCard("Shares 7d", "${_data!.shares7d}"),
         _buildKpiCard("Global Rate", "${(_data!.clickRate7d * 100).toStringAsFixed(1)}%"),
         _buildKpiCard("Clicks 24h", "${_data!.clicks24h}"),
         _buildKpiCard("Clicks 7d", "${_data!.clicks7d}"),
       ],
    );
  }

  Widget _buildKpiCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 9, fontFamily: 'RobotoMono')),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: AppColors.accentCyan, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'RobotoMono')),
        ],
      ),
    );
  }

  Widget _buildDailyTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("VOLUME TREND (14D)", style: AppTypography.label(context).copyWith(color: AppColors.textDisabled)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderSubtle),
            color: AppColors.surface1
          ),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
            },
            children: [
              // Header
              TableRow(
                decoration: const BoxDecoration(color: AppColors.surface2),
                children: [
                  _buildCell("DAY ID", isHeader: true),
                  _buildCell("SHARES", isHeader: true, alignRight: true),
                  _buildCell("CLICKS", isHeader: true, alignRight: true),
                ]
              ),
              // Rows
              ..._data!.dailyTable.map((row) => TableRow(
                 children: [
                   _buildCell(row['dayId']),
                   _buildCell("${row['shares']}", alignRight: true),
                   _buildCell("${row['clicks']}", alignRight: true),
                 ]
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSurfaceTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("TOP SURFACES (7D)", style: AppTypography.label(context).copyWith(color: AppColors.textDisabled)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _data!.topSurfaces.entries.map((e) => Chip(
             label: Text("${e.key}: ${e.value}"),
             backgroundColor: AppColors.surface1,
             side: const BorderSide(color: AppColors.borderSubtle),
             labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontFamily: 'RobotoMono'),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildCell(String text, {bool isHeader = false, bool alignRight = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          color: isHeader ? AppColors.textPrimary : AppColors.textSecondary,
          fontSize: 10,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontFamily: 'RobotoMono'
        ),
      ),
    );
  }
}
