import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MarketSniperApp());
}

class MarketSniperApp extends StatelessWidget {
  const MarketSniperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MarketSniper Day 00',
      theme: ThemeData.dark(),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String status = "CONNECTING...";
  String trace = "NO TRACE";
  bool isFounder = false;

  @override
  void initState() {
    super.initState();
    _fetchHealth();
  }

  Future<void> _fetchHealth() async {
    try {
      // Use 10.0.2.2 for Android Emulator to localhost
      final response = await http.get(Uri.parse('http://10.0.2.2:8000/health_ext'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          status = data['status'];
          isFounder = data['founder_mode'] ?? false;
          trace = "LIVE Connected";
        });
      } else {
        setState(() {
          status = "ERROR ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        status = "OFFLINE";
        trace = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MSR: $status'),
        backgroundColor: isFounder ? Colors.purple[900] : Colors.grey[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: Colors.blueGrey[900],
              child: ListTile(
                title: const Text("SYSTEM STATUS"),
                subtitle: Text(status, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.black54,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("FORENSIC TRACE", style: TextStyle(color: Colors.redAccent, fontFamily: "Monospace")),
                    const Divider(color: Colors.redAccent),
                    Text("API: http://10.0.2.2:8000", style: const TextStyle(fontFamily: "Monospace")),
                    Text("FLAGS: FOUNDER_ALWAYS_ON", style: const TextStyle(fontFamily: "Monospace")),
                    Text("TRACE: $trace", style: const TextStyle(fontFamily: "Monospace", fontSize: 10)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
