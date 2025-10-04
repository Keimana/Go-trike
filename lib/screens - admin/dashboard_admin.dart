import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../widgets/card_builder_admin.dart'; // AdminCard + FullscreenPage + CardListItem

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

  late final List<Map<String, dynamic>> cardsData;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());

    cardsData = [
      {"title": "Reports", "child": const CardListItem("Lorem ipsum")},
      {
        "title": "Activity Logs",
        "child": Column(
          children: const [
            CardListItem("Log #1"),
            SizedBox(height: 10),
            CardListItem("Log #2"),
            SizedBox(height: 10),
            CardListItem("Log #3"),
          ],
        ),
      },
      {"title": "Ride History", "child": const CardListItem("Lorem ipsum ride")},
      {
        "title": "Account and Terminal Control",
        "child": const CardListItem("Manage users and terminals")
      },
    ];
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

  List<Widget> _buildCardsWidgets() {
    final List<Widget> widgets = [
      _buildHeader(MediaQuery.of(context).size.width),
      const SizedBox(height: 20)
    ];

    for (int i = 0; i < cardsData.length; i++) {
      final data = cardsData[i];
      widgets.add(
        AdminCard(
          title: data["title"],
          child: data["child"],
          onFullscreenTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FullscreenPage(
                  title: data["title"],
                  child: data["child"],
                ),
              ),
            );
          },
        ),
      );
      if (i != cardsData.length - 1) widgets.add(const SizedBox(height: 20));
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final currentCards = _buildCardsWidgets();

    return Scaffold(
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (screenWidth >= 1200) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 1, child: _buildLeftColumn(currentCards)),
                  Expanded(flex: 2, child: _buildRightColumn(currentCards)),
                ],
              );
            }

            return SingleChildScrollView(
              padding: EdgeInsets.all(screenWidth >= 800 ? 24 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: currentCards,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLeftColumn(List<Widget> cards) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: cards.sublist(1, 4),
      ),
    );
  }

  Widget _buildRightColumn(List<Widget> cards) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: cards.sublist(4),
      ),
    );
  }

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
        child: Text(
          _formattedDate,
          style: const TextStyle(fontSize: 16, color: Color(0xFF323232)),
        ),
      );
}

// ---------------- GO TRIKE LOGO ----------------
class GoTrike extends StatelessWidget {
  const GoTrike({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Go',
            style: TextStyle(
                color: Color(0xFF892CDD), fontSize: 32, fontFamily: 'Roboto', fontWeight: FontWeight.w700),
          ),
          TextSpan(
            text: ' ',
            style: TextStyle(
                color: Color(0xFF34C759), fontSize: 32, fontFamily: 'Roboto', fontWeight: FontWeight.w700),
          ),
          TextSpan(
            text: 'Trike',
            style: TextStyle(
                color: Color(0xFFFF9500), fontSize: 32, fontFamily: 'Roboto', fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
