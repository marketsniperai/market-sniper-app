import 'package:flutter/material.dart';
import '../../services/invite_service.dart';
import '../../widgets/war_room_tile.dart';
import '../../config/app_config.dart';
import '../../theme/app_colors.dart';

class InviteLogicTile extends StatefulWidget {
  const InviteLogicTile({super.key});

  @override
  State<InviteLogicTile> createState() => _InviteLogicTileState();
}

class _InviteLogicTileState extends State<InviteLogicTile> {
  List<Map<String, dynamic>> _ledgerTail = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final tail = await InviteService().getLedgerTail();
    if (mounted) {
      setState(() {
        _ledgerTail = tail;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.isFounderBuild) return const SizedBox.shrink();

    return WarRoomTile(
      title: "INVITE / GATE LOGIC",
      subtitle: const ["Local Attribution Ledger"], // Fixed List<String> type
      status: WarRoomTileStatus.nominal,
      customBody: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ENABLED: ${AppConfig.inviteEnabled}  |  BYPASS: ${AppConfig.inviteBypassForFounder}",
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 8),
                const Text("LATEST EVENTS (Local):",
                    style: TextStyle(color: AppColors.textDisabled, fontSize: 10)),
                const SizedBox(height: 4),
                ..._ledgerTail.take(5).map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        "${e['ts_utc']} | ${e['event']} | ${e['valid']}",
                        style: const TextStyle(
                            color: AppColors.stateLive,
                            fontSize: 9,
                            fontFamily: 'RobotoMono'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
                if (_ledgerTail.isEmpty)
                  const Text("No events recorded yet.",
                      style: TextStyle(color: AppColors.textDisabled, fontSize: 10)),
              ],
            ),
    );
  }
}
