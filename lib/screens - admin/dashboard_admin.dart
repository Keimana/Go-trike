import 'package:flutter/material.dart';
import 'dart:async'; // <-- add this
import 'package:intl/intl.dart';
import '../widgets/card_builder_admin.dart'; // Import the card

void main() {
  runApp(const UiAdminSideReports());
}

class UiAdminSideReports extends StatelessWidget {
  const UiAdminSideReports({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFF8FAFB),
      ),
      home: const UiAdminDashboard(),
    );
  }
}

class UiAdminDashboard extends StatefulWidget {
  const UiAdminDashboard({super.key});

  @override
  State<UiAdminDashboard> createState() => _UiAdminDashboardState();
}

class _UiAdminDashboardState extends State<UiAdminDashboard> {
  late Timer _timer;
  String _formattedDate = "";

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    final formatted = DateFormat('EEEE • MMMM d, yyyy • h:mma').format(now);
    setState(() => _formattedDate = formatted);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double width = constraints.maxWidth;

            // Desktop
            if (width >= 1200) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 1, child: _buildLeftColumn(width)),
                  Expanded(flex: 2, child: _buildRightColumn(width)),
                ],
              );
            }

            // Tablet
            if (width >= 800) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildCards(width),
                ),
              );
            }

            // Mobile
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildCards(width),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildCards(double width) => [
        _buildHeader(width),
        const SizedBox(height: 20),
        AdminCard(title: "Reports", child: const CardListItem("Lorem ipsum")),
        const SizedBox(height: 20),
        AdminCard(
          title: "Activity Logs",
          child: Column(
            children: const [
              CardListItem("Log #1"),
              SizedBox(height: 10),
              CardListItem("Log #2"),
              SizedBox(height: 10),
              CardListItem("Log #3"),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AdminCard(title: "Ride History", child: const CardListItem("Lorem ipsum ride")),
        const SizedBox(height: 20),
        AdminCard(
          title: "Account and Terminal Control",
          child: const CardListItem("Manage users and terminals"),
        ),
      ];

  Widget _buildHeader(double width) {
    bool isMobile = width < 600;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 24),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GoTrike(),
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerRight, child: _buildDateTimeCard()),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const GoTrike(),
                _buildDateTimeCard(),
              ],
            ),
    );
  }

  Widget _buildDateTimeCard() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(_formattedDate, style: const TextStyle(fontSize: 16, color: Color(0xFF323232))),
      );

  Widget _buildLeftColumn(double width) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildCards(width).sublist(0, 3), // first half cards
      ),
    );
  }

  Widget _buildRightColumn(double width) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildCards(width).sublist(3), // remaining cards
      ),
    );
  }
}

// ---------------- GO TRIKE LOGO ----------------
class GoTrike extends StatelessWidget {
  const GoTrike({super.key});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: const [
          TextSpan(
            text: 'Go',
            style: TextStyle(color: Color(0xFF892CDD), fontSize: 32, fontFamily: 'Roboto', fontWeight: FontWeight.w700),
          ),
          TextSpan(
            text: ' ',
            style: TextStyle(color: Color(0xFF34C759), fontSize: 32, fontFamily: 'Roboto', fontWeight: FontWeight.w700),
          ),
          TextSpan(
            text: 'Trike',
            style: TextStyle(color: Color(0xFFFF9500), fontSize: 32, fontFamily: 'Roboto', fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
