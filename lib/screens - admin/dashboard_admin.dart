import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/card_builder_admin.dart';
import '../widgets/admin_dashboard_modals.dart';

void main() => runApp(const UiAdminSideReports());

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

  void _openModal(String title, Widget content) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: AdminModal(
            title: title,
            content: content,
          ),
        ),
      ),
    );
  }

@override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;

  // ✅ Define breakpoints
  final bool isDesktop = screenWidth > 1200;
  final bool isTablet = screenWidth > 700 && screenWidth <= 1200;
  final bool isMobile = screenWidth <= 700;

  return Scaffold(
    body: SafeArea(
      child: Padding(
        // ✅ Responsive horizontal padding
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 200 : isTablet ? 80 : 16,
          vertical: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const GoTrike(),
                _buildDateTimeCard(),
              ],
            ),
            const SizedBox(height: 40),

            // ✅ Responsive grid
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (isMobile) return _buildSingleColumn();

                  // Adjust number of columns and card height dynamically
                  return GridView.count(
                    crossAxisCount: isDesktop ? 2 : 1,
                    crossAxisSpacing: 50,
                    mainAxisSpacing: 50,
                    childAspectRatio: isDesktop
                        ? 1.7
                        : isTablet
                            ? 1.8
                            : 1.2,
                    children: [
                      _buildCard(
                        title: "Reports",
                        content: const ReportsContent(minimal: true),
                        full: const ReportsContent(minimal: false),
                      ),
                      _buildCard(
                        title: "Activity Logs",
                        content: const ActivityLogsContent(minimal: true),
                        full: const ActivityLogsContent(minimal: false),
                      ),
                      _buildCard(
                        title: "Ride History",
                        content: const RideHistoryContent(minimal: true),
                        full: const RideHistoryContent(minimal: false),
                      ),
                      _buildCard(
                        title: "Account and Terminal Control",
                        content: const AccountControlContent(minimal: true),
                        full: const AccountControlContent(minimal: false),
                      ),
                      _buildCard(
                        title: "User List",
                        content: const UserListContent(minimal: true),
                        full: const UserListContent(minimal: false),
                      ),
                      _buildCard(
                        title: "Trike Driver List",
                        content: const TrikeDriverListContent(minimal: true),
                        full: const TrikeDriverListContent(minimal: false),
                      ),

                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}


Widget _buildSingleColumn() {
  final cards = [
    ("Reports", const ReportsContent(minimal: true),
        const ReportsContent(minimal: false)),
    ("Activity Logs", const ActivityLogsContent(minimal: true),
        const ActivityLogsContent(minimal: false)),
    ("Ride History", const RideHistoryContent(minimal: true),
        const RideHistoryContent(minimal: false)),
    ("Account and Terminal Control",
        const AccountControlContent(minimal: true),
        const AccountControlContent(minimal: false)),
    ("User List", const UserListContent(minimal: true),
        const UserListContent(minimal: false)),
    ("Trike Driver List", const TrikeDriverListContent(minimal: true),
        const TrikeDriverListContent(minimal: false)),
  ];

  return ListView.separated(
    itemCount: cards.length, // ✅ Now includes all 6 cards
    separatorBuilder: (_, __) => const SizedBox(height: 20),
    itemBuilder: (context, i) {
      return _buildCard(
        title: cards[i].$1,
        content: cards[i].$2,
        full: cards[i].$3,
      );
    },
  );
}


  Widget _buildCard({
    required String title,
    required Widget content,
    required Widget full,
  }) {
    return AdminCard(
      title: title,
      titleColor:
          title == "Reports" ? const Color(0xFF323232) : const Color(0xFF323232),

      child: content,
      onFullscreenTap: () => _openModal(title, full),
    );
  }

  Widget _buildDateTimeCard() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          _formattedDate,
          style: const TextStyle(fontSize: 16, color: Color(0xFF323232)),
        ),
      );
}

class GoTrike extends StatelessWidget {
  const GoTrike({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Go',
                style: TextStyle(
                  color: Color(0xFF892CDD),
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(text: ' '),
              TextSpan(
                text: 'Trike',
                style: TextStyle(
                  color: Color(0xFFFF9500),
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Admin Dashboard',
          style: TextStyle(
            fontSize: 50, // ✅ Slightly bigger
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 0, 0, 0),
          ),
        ),
      ],
    );
  }
}


// ---------------- Reports Modal ----------------
class ReportsContent extends StatelessWidget {
  final bool minimal;
  const ReportsContent({super.key, this.minimal = false});

  final List<Map<String, String>> _reports = const [
    {
      "date": "Aug 3, 2025",
      "time": "4:40 PM",
      "cause": "Reckless Driving",
      "reporter": "User123",
      "reportedToda": "Toda 43"
    },
    {
      "date": "Aug 3, 2025",
      "time": "4:40 PM",
      "cause": "Reckless Driving",
      "reporter": "User123",
      "reportedToda": "Toda 43"
    },
    {
      "date": "Aug 3, 2025",
      "time": "4:40 PM",
      "cause": "Reckless Driving",
      "reporter": "User123",
      "reportedToda": "Toda 43"
    },
    {
      "date": "Aug 3, 2025",
      "time": "4:40 PM",
      "cause": "Reckless Driving",
      "reporter": "User123",
      "reportedToda": "Toda 43"
    },
    {
      "date": "Aug 3, 2025",
      "time": "4:40 PM",
      "cause": "Reckless Driving",
      "reporter": "User123",
      "reportedToda": "Toda 43"
    },
    {
      "date": "Aug 3, 2025",
      "time": "4:40 PM",
      "cause": "Reckless Driving",
      "reporter": "User123",
      "reportedToda": "Toda 43"
    },
    {
      "date": "Aug 3, 2025",
      "time": "4:40 PM",
      "cause": "Reckless Driving",
      "reporter": "User123",
      "reportedToda": "Toda 43"
    },
    {
      "date": "Aug 3, 2025",
      "time": "4:40 PM",
      "cause": "Reckless Driving",
      "reporter": "User123",
      "reportedToda": "Toda 43"
    },
    {
      "date": "Aug 3, 2025",
      "time": "4:40 PM",
      "cause": "Reckless Driving",
      "reporter": "User123",
      "reportedToda": "Toda 43"
    },
    {
      "date": "Aug 3, 2025",
      "time": "4:40 PM",
      "cause": "Reckless Driving",
      "reporter": "User123",
      "reportedToda": "Toda 43"
    },


    
  ];

@override
Widget build(BuildContext context) {
  final reports = minimal ? _reports.take(5).toList() : _reports;

  return Container(
    padding: const EdgeInsets.all(15),
    child: SingleChildScrollView( // ✅ Added scrollable wrapper
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          _buildTableHeader(),
          const SizedBox(height: 8),
          ...List.generate(reports.length, (index) {
            final r = reports[index];
            final isGray = index % 2 == 0;
            return Container(
              color: isGray ? const Color(0xFFF9F9F9) : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  _cell(r["date"]!, flex: 2),
                  _cell(r["cause"]!, flex: 3),
                  _cell(r["reporter"]!, flex: 2),
                ],
              ),
            );
          }),
          if (minimal)
            const Padding(
              padding: EdgeInsets.only(top: 8),
            ),
        ],
      ),
    ),
  );
}

Widget _buildTableHeader() {
  return Row(children: const [
    Expanded(flex: 2, child: Center(child: Text('Date', style: _headerStyle))),
    Expanded(flex: 3, child: Center(child: Text('Cause', style: _headerStyle))),
    Expanded(flex: 2, child: Center(child: Text('Reporter', style: _headerStyle))),
  ]);
}


  static const _headerStyle = TextStyle(
      fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF323232));

Widget _cell(String text, {int flex = 1}) {
  return Expanded(
    flex: flex,
    child: Center(
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, color: Color(0xFF323232)),
        maxLines: 1, // ✅ limit to 1 line only
        overflow: TextOverflow.ellipsis, // ✅ add "..." when it’s too long
        softWrap: false, // ✅ prevent wrapping
      ),
    ),
  );
}
}

// ---------------- Activity Logs ----------------
class ActivityLogsContent extends StatelessWidget {
  final bool minimal;
  const ActivityLogsContent({super.key, this.minimal = false});

  final List<Map<String, dynamic>> logs = const [
    {"name": "Toda 43", "accepted": 5, "rejected": 2},
    {"name": "Toda 43", "accepted": 5, "rejected": 2},
    {"name": "Toda 43", "accepted": 5, "rejected": 2},
    {"name": "Toda 43", "accepted": 5, "rejected": 2},
    {"name": "Toda 43", "accepted": 5, "rejected": 2},
  ];

  @override
  Widget build(BuildContext context) {
    final data = minimal ? logs.take(5).toList() : logs;

    return Container(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          _headerRow(),
          const SizedBox(height: 8),
          ...List.generate(data.length, (index) {
            final log = data[index];
            final isGray = index % 2 == 0;
            return Container(
              color: isGray ? const Color(0xFFF9F9F9) : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  _cell(log["name"].toString(), flex: 3, align: TextAlign.center),
                  _cell(log["accepted"].toString(), flex: 2, align: TextAlign.center),
                  _cell(log["rejected"].toString(), flex: 2, align: TextAlign.center),
                ],
              ),
            );
          }),
          if (minimal) const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _headerRow() {
    return Row(children: const [
      Expanded(
        flex: 3,
        child: Center(child: Text('Toda', style: _headerStyle)),
      ),
      Expanded(
        flex: 2,
        child: Center(child: Text('Accepted', style: _headerStyle)),
      ),
      Expanded(
        flex: 2,
        child: Center(child: Text('Rejected', style: _headerStyle)),
      ),
    ]);
  }

  static const _headerStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Color(0xFF323232),
  );

  Widget _cell(String text, {int flex = 1, TextAlign align = TextAlign.center}) {
    return Expanded(
      flex: flex,
      child: Center(
        child: Text(
          text,
          textAlign: align,
          style: const TextStyle(fontSize: 15, color: Color(0xFF323232)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        ),
      ),
    );
  }
}

// ---------------- Ride History ----------------
class RideHistoryContent extends StatelessWidget {
  final bool minimal;
  const RideHistoryContent({super.key, this.minimal = false});

  final List<Map<String, String>> rides = const [
    {"name": "Toda 1", "pickup": "Station A", "dropoff": "Station B", "price": "₱15.00"},
    {"name": "Toda 1", "pickup": "Station A", "dropoff": "Station B", "price": "₱15.00"},
    {"name": "Toda 1", "pickup": "Station A", "dropoff": "Station B", "price": "₱15.00"},
    {"name": "Toda 1", "pickup": "Station A", "dropoff": "Station B", "price": "₱15.00"},
    {"name": "Toda 1", "pickup": "Station A", "dropoff": "Station B", "price": "₱15.00"},
    {"name": "Toda 1", "pickup": "Station A", "dropoff": "Station B", "price": "₱15.00"},
    {"name": "Toda 1", "pickup": "Station A", "dropoff": "Station B", "price": "₱15.00"},
    {"name": "Toda 1", "pickup": "Station A", "dropoff": "Station B", "price": "₱15.00"},
    {"name": "Toda 1", "pickup": "Station A", "dropoff": "Station B", "price": "₱15.00"},
    {"name": "Toda 1", "pickup": "Station A", "dropoff": "Station B", "price": "₱15.00"},
    {"name": "Toda 1", "pickup": "Station A", "dropoff": "Station B", "price": "₱15.00"},
    {"name": "Toda 1", "pickup": "Station A", "dropoff": "Station B", "price": "₱15.00"},
    {"name": "Toda 1", "pickup": "Station A", "dropoff": "Station B", "price": "₱15.00"},
    {"name": "Toda 1", "pickup": "Station A", "dropoff": "Station B", "price": "₱15.00"},
    {"name": "Toda 1", "pickup": "Station A", "dropoff": "Station B", "price": "₱15.00"},
    {"name": "Toda 1", "pickup": "Station A", "dropoff": "Station B", "price": "₱15.00"},
    {"name": "Toda 1", "pickup": "Station A", "dropoff": "Station B", "price": "₱15.00"},
    {"name": "Toda 1", "pickup": "Station A", "dropoff": "Station B", "price": "₱15.00"},



  ];

  @override
Widget build(BuildContext context) {
  final data = minimal ? rides.take(5).toList() : rides;

  return Container(
    padding: const EdgeInsets.all(15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        Row(children: const [
          Expanded(
            flex: 3,
            child: Center(
              child: Text('Rider', style: _headerStyle),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text('Price', style: _headerStyle),
            ),
          ),
        ]),
        ...List.generate(data.length, (index) {
          final ride = data[index];
          final isGray = index % 2 == 0;
          return Container(
            color: isGray ? const Color(0xFFF9F9F9) : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                _cell(ride["name"]!, flex: 3),
                _cell(ride["price"]!, flex: 2),
              ],
            ),
          );
        }),
        if (minimal)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            
          ),
      ],
    ),
  );
}


  static const _headerStyle = TextStyle(
      fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF323232));

Widget _cell(String text, {int flex = 1}) {
  return Expanded(
    flex: flex,
    child: Center( // ✅ This ensures true center alignment horizontally
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, color: Color(0xFF323232)),
      ),
    ),
  );
}
}

// ---------------- Account Control ----------------
class AccountControlContent extends StatelessWidget {
  final bool minimal;
  const AccountControlContent({super.key, this.minimal = false});

  final List<Map<String, String>> adminActivities = const [
    {"date": "Oct 10, 2025", "activity": "Added new terminal"},
    {"date": "Oct 10, 2025", "activity": "Added new terminal"},
    {"date": "Oct 10, 2025", "activity": "Added new terminal"},
    {"date": "Oct 10, 2025", "activity": "Added new terminal"},
    {"date": "Oct 10, 2025", "activity": "Added new terminal"},

  ];

  @override
  Widget build(BuildContext context) {
    final activities = minimal ? adminActivities.take(5).toList() : adminActivities;

    return Container(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          Row(children: const [
            Expanded(
              flex: 2,
              child: Center(child: Text('Date', style: _headerStyle)),
            ),
            Expanded(
              flex: 4,
              child: Center(child: Text('Activity', style: _headerStyle)),
            ),
          ]),
          ...List.generate(activities.length, (index) {
            final a = activities[index];
            final isGray = index % 2 == 0;
            return Container(
              color: isGray ? const Color(0xFFF9F9F9) : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  _cell(a["date"]!, flex: 2),
                  _cell(a["activity"]!, flex: 4),
                ],
              ),
            );
          }),
          if (minimal)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              
            ),
        ],
      ),
    );
  }
}

// ---------------- User List ----------------
class UserListContent extends StatelessWidget {
  final bool minimal;
  const UserListContent({super.key, this.minimal = false});

  final List<Map<String, String>> users = const [
    {"name": "Juan Dela Cruz", "email": "juan@gmail.com", "status": "Active"},
    {"name": "Maria Santos", "email": "maria@gmail.com", "status": "Inactive"},
    {"name": "Carlos Reyes", "email": "carlos@gmail.com", "status": "Active"},
    {"name": "Juan Dela Cruz", "email": "juan@gmail.com", "status": "Active"},
    {"name": "Maria Santos", "email": "maria@gmail.com", "status": "Inactive"},
    {"name": "Carlos Reyes", "email": "carlos@gmail.com", "status": "Active"},
    {"name": "Juan Dela Cruz", "email": "juan@gmail.com", "status": "Active"},
    {"name": "Maria Santos", "email": "maria@gmail.com", "status": "Inactive"},
    {"name": "Carlos Reyes", "email": "carlos@gmail.com", "status": "Active"},
    {"name": "Juan Dela Cruz", "email": "juan@gmail.com", "status": "Active"},
    {"name": "Maria Santos", "email": "maria@gmail.com", "status": "Inactive"},
    {"name": "Carlos Reyes", "email": "carlos@gmail.com", "status": "Active"},
    {"name": "Juan Dela Cruz", "email": "juan@gmail.com", "status": "Active"},
    {"name": "Maria Santos", "email": "maria@gmail.com", "status": "Inactive"},
    {"name": "Carlos Reyes", "email": "carlos@gmail.com", "status": "Active"},
    {"name": "Juan Dela Cruz", "email": "juan@gmail.com", "status": "Active"},
    {"name": "Maria Santos", "email": "maria@gmail.com", "status": "Inactive"},
    {"name": "Carlos Reyes", "email": "carlos@gmail.com", "status": "Active"},
    {"name": "Juan Dela Cruz", "email": "juan@gmail.com", "status": "Active"},
    {"name": "Maria Santos", "email": "maria@gmail.com", "status": "Inactive"},
    {"name": "Carlos Reyes", "email": "carlos@gmail.com", "status": "Active"},

  ];

  @override
  Widget build(BuildContext context) {
    final data = minimal ? users.take(5).toList() : users;

    return Container(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          Row(children: const [
            Expanded(
              flex: 3,
              child: Center(child: Text('Name', style: _headerStyle)),
            ),
            Expanded(
              flex: 4,
              child: Center(child: Text('Email', style: _headerStyle)),
            ),
            Expanded(
              flex: 2,
              child: Center(child: Text('Status', style: _headerStyle)),
            ),
          ]),
          ...List.generate(data.length, (index) {
            final user = data[index];
            final isGray = index % 2 == 0;
            return Container(
              color: isGray ? const Color(0xFFF9F9F9) : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  _cell(user["name"]!, flex: 3),
                  _cell(user["email"]!, flex: 4),
                  _cell(user["status"]!, flex: 2),
                ],
              ),
            );
          }),
          if (minimal)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              
            ),
        ],
      ),
    );
  }
}

// ---------------- Trike Driver List ----------------
class TrikeDriverListContent extends StatelessWidget {
  final bool minimal;
  const TrikeDriverListContent({super.key, this.minimal = false});

  final List<Map<String, String>> drivers = const [
    {"name": "Pedro Cruz", "toda": "Toda 1"},
    {"name": "Jose Dela Rosa", "toda": "Toda 3"},
    {"name": "Mark David", "toda": "Toda 5"},
    {"name": "Mark David", "toda": "Toda 5"},
    {"name": "Mark David", "toda": "Toda 5"},
    {"name": "Mark David", "toda": "Toda 5"},
    {"name": "Mark David", "toda": "Toda 5"},

  ];

  @override
  Widget build(BuildContext context) {
    final data = minimal ? drivers.take(5).toList() : drivers;

    return Container(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          Row(children: const [
            Expanded(
              flex: 3,
              child: Center(child: Text('Driver', style: _headerStyle)),
            ),
            Expanded(
              flex: 3,
              child: Center(child: Text('Toda', style: _headerStyle)),
            ),

          ]),
          ...List.generate(data.length, (index) {
            final d = data[index];
            final isGray = index % 2 == 0;
            return Container(
              color: isGray ? const Color(0xFFF9F9F9) : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  _cell(d["name"]!, flex: 3),
                  _cell(d["toda"]!, flex: 3),
                ],
              ),
            );
          }),
          if (minimal)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              
            ),
        ],
      ),
    );
  }
}

// ---------------- Shared Styles ----------------
const _headerStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.bold,
  color: Color(0xFF323232),
);

Widget _cell(String text, {int flex = 1}) {
  return Expanded(
    flex: flex,
    child: Center(
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, color: Color(0xFF323232)),
      ),
    ),
  );
}
