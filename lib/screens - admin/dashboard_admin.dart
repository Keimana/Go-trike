import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/card_builder_admin.dart';
import '../widgets/admin_dashboard_modals.dart';
import '../services/admin_service.dart';

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
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
    
    _scrollController.addListener(() {
      if (_scrollController.offset > 20 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 20 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    final formatted = DateFormat('EEEE • MMMM d, yyyy • h:mma').format(now);
    setState(() => _formattedDate = formatted);
  }

  @override
  void dispose() {
    _timer.cancel();
    _scrollController.dispose();
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

  void _refreshData() {
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Data refreshed'),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 1200;
    final bool isTablet = screenWidth > 700 && screenWidth <= 1200;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshData,
        backgroundColor: const Color(0xFF892CDD),
        foregroundColor: Colors.white,
        child: const Icon(Icons.refresh_rounded),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 200 : isTablet ? 80 : 16,
            vertical: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withOpacity(_isScrolled ? 0.1 : 0),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const GoTrike(),
                    _buildDateTimeCard(),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    _refreshData();
                    await Future.delayed(const Duration(seconds: 1));
                  },
                  child: ListView.separated(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: 6,
                    separatorBuilder: (_, __) => const SizedBox(height: 20),
                    itemBuilder: (context, index) {
                      return _buildCardItem(index);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardItem(int index) {
    final cards = [
      (
        "Reports",
        const ReportsContent(minimal: true),
        const ReportsContent(minimal: false),
      ),
      (
        "Activity Logs", 
        const ActivityLogsContent(minimal: true),
        const ActivityLogsContent(minimal: false),
      ),
      (
        "Ride History",
        const RideHistoryContent(minimal: true),
        const RideHistoryContent(minimal: false),
      ),
      (
        "Account and Terminal Control",
        const AccountControlContent(minimal: true),
        const AccountControlContent(minimal: false),
      ),
      (
        "User List",
        const UserListContent(minimal: true),
        const UserListContent(minimal: false),
      ),
      (
        "Trike Driver List",
        const TrikeDriverListContent(minimal: true),
        const TrikeDriverListContent(minimal: false),
      ),
    ];

    final card = cards[index];
    return _buildCard(
      title: card.$1,
      content: card.$2,
      full: card.$3,
    );
  }

  Widget _buildCard({
    required String title,
    required Widget content,
    required Widget full,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _openModal(title, full),
        child: AdminCard(
          title: title,
          titleColor: const Color(0xFF323232),
          child: content,
          onFullscreenTap: () => _openModal(title, full),
        ),
      ),
    );
  }

  Widget _buildDateTimeCard() => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isScrolled ? 0.08 : 0.05),
              blurRadius: _isScrolled ? 12 : 8,
              offset: Offset(0, _isScrolled ? 4 : 3),
            ),
          ],
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            fontSize: _isScrolled ? 14 : 16,
            color: const Color(0xFF323232),
            fontWeight: _isScrolled ? FontWeight.w500 : FontWeight.normal,
          ),
          child: Text(_formattedDate),
        ),
      );
}

class GoTrike extends StatelessWidget {
  const GoTrike({super.key});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: Column(
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
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ REPORTS CONTENT ============
class ReportsContent extends StatelessWidget {
  final bool minimal;
  const ReportsContent({super.key, this.minimal = false});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdminReport>>(
      stream: AdminService.listenToAllReports(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingWidget(message: 'Loading reports...');
        }

        if (snapshot.hasError) {
          return _buildErrorWidget('Reports');
        }

        final reports = snapshot.data ?? [];
        final displayReports = minimal ? reports.take(5).toList() : reports;

        if (displayReports.isEmpty) {
          return const _EmptyStateWidget(message: 'No reports yet');
        }

        return _buildDataTable(
          headers: const [
            _HeaderConfig('Date', flex: 2),
            _HeaderConfig('Issues', flex: 3),
            _HeaderConfig('Comments', flex: 2),
            _HeaderConfig('Reporter', flex: 2),
            _HeaderConfig('Toda #', flex: 2),
          ],
          rows: displayReports,
          builder: (report, index) => [
            _buildCell(DateFormat('MMM d, yyyy').format(report.reportTime), flex: 2),
            _buildCell(report.cause, flex: 3, maxLines: 2),
            _buildCell(report.additionalComments ?? 'No additional comments', flex: 2, maxLines: 2),
            _buildCell(report.reporter, flex: 2),
          ],
        );
      },
    );
  }
}

// ============ ACTIVITY LOGS CONTENT ============
class ActivityLogsContent extends StatelessWidget {
  final bool minimal;
  const ActivityLogsContent({super.key, this.minimal = false});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TodaActivityLog>>(
      stream: AdminService.listenToActivityLogs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingWidget(message: 'Loading activity logs...');
        }

        if (snapshot.hasError) {
          return _buildErrorWidget('Activity Logs');
        }

        final logs = snapshot.data ?? [];
        final displayLogs = minimal ? logs.take(5).toList() : logs;

        if (displayLogs.isEmpty) {
          return const _EmptyStateWidget(message: 'No activity logs yet');
        }

        return _buildDataTable(
          headers: const [
            _HeaderConfig('Toda', flex: 3),
            _HeaderConfig('Accepted', flex: 2),
            _HeaderConfig('Rejected', flex: 2),
          ],
          rows: displayLogs,
          builder: (log, index) => [
            _buildCell(log.todaName, flex: 3),
            _buildCell(log.accepted.toString(), flex: 2, isNumber: true),
            _buildCell(log.rejected.toString(), flex: 2, isNumber: true),
          ],
        );
      },
    );
  }
}

// ============ RIDE HISTORY CONTENT ============
class RideHistoryContent extends StatelessWidget {
  final bool minimal;
  const RideHistoryContent({super.key, this.minimal = false});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RideHistoryEntry>>(
      stream: AdminService.listenToRideHistory(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildIndexErrorWidget();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingWidget(message: 'Loading ride history...');
        }

        final rides = snapshot.data ?? [];
        final displayRides = minimal ? rides.take(5).toList() : rides;

        if (displayRides.isEmpty) {
          return const _EmptyStateWidget(message: 'No completed rides yet');
        }

        return _buildDataTable(
          headers: const [
            _HeaderConfig('Rider', flex: 3),
            _HeaderConfig('Price', flex: 2),
          ],
          rows: displayRides,
          builder: (ride, index) => [
            _buildCell(ride.riderName, flex: 3),
            _buildCell('₱${ride.price.toStringAsFixed(2)}', flex: 2, isNumber: true),
          ],
        );
      },
    );
  }
}

// ============ ACCOUNT CONTROL CONTENT ============
class AccountControlContent extends StatelessWidget {
  final bool minimal;
  const AccountControlContent({super.key, this.minimal = false});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdminActivity>>(
      stream: AdminService.listenToAdminActivities(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingWidget(message: 'Loading admin activities...');
        }

        if (snapshot.hasError) {
          return _buildErrorWidget('Admin Activities');
        }

        final activities = snapshot.data ?? [];
        final displayActivities = minimal ? activities.take(5).toList() : activities;

        if (displayActivities.isEmpty) {
          return const _EmptyStateWidget(message: 'No admin activities yet');
        }

        return _buildDataTable(
          headers: const [
            _HeaderConfig('Date', flex: 2),
            _HeaderConfig('Activity', flex: 4),
          ],
          rows: displayActivities,
          builder: (activity, index) => [
            _buildCell(DateFormat('MMM d, yyyy').format(activity.date), flex: 2),
            _buildCell(activity.activity, flex: 4, maxLines: 2),
          ],
        );
      },
    );
  }
}

// ============ USER LIST CONTENT ============
class UserListContent extends StatelessWidget {
  final bool minimal;
  const UserListContent({super.key, this.minimal = false});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserEntry>>(
      stream: AdminService.listenToUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingWidget(message: 'Loading users...');
        }

        if (snapshot.hasError) {
          return _buildErrorWidget('User List');
        }

        final users = snapshot.data ?? [];
        final displayUsers = minimal ? users.take(5).toList() : users;

        if (displayUsers.isEmpty) {
          return const _EmptyStateWidget(message: 'No users yet');
        }

        return _buildDataTable(
          headers: const [
            _HeaderConfig('Name', flex: 3),
            _HeaderConfig('Email', flex: 4),
            _HeaderConfig('Status', flex: 2),
          ],
          rows: displayUsers,
          builder: (user, index) => [
            _buildCell(user.name, flex: 3),
            _buildCell(user.email, flex: 4),
            _buildCell(
              user.status,
              flex: 2,
              textColor: user.status == 'Active' ? Colors.green : Colors.orange,
            ),
          ],
        );
      },
    );
  }
}

// ============ TRIKE DRIVER LIST CONTENT ============
class TrikeDriverListContent extends StatelessWidget {
  final bool minimal;
  const TrikeDriverListContent({super.key, this.minimal = false});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DriverEntry>>(
      stream: AdminService.listenToDrivers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingWidget(message: 'Loading drivers...');
        }

        if (snapshot.hasError) {
          return _buildErrorWidget('Driver List');
        }

        final drivers = snapshot.data ?? [];
        final displayDrivers = minimal ? drivers.take(5).toList() : drivers;

        if (displayDrivers.isEmpty) {
          return const _EmptyStateWidget(message: 'No drivers yet');
        }

        return _buildDataTable(
          headers: const [
            _HeaderConfig('Driver', flex: 3),
            _HeaderConfig('Toda', flex: 3),
          ],
          rows: displayDrivers,
          builder: (driver, index) => [
            _buildCell(driver.name, flex: 3),
            _buildCell(driver.todaNumber, flex: 3),
          ],
        );
      },
    );
  }
}

// ============ REUSABLE UI COMPONENTS ============

class _LoadingWidget extends StatelessWidget {
  final String message;
  const _LoadingWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Color(0xFF892CDD)),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateWidget extends StatelessWidget {
  final String message;
  const _EmptyStateWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderConfig {
  final String text;
  final int flex;
  const _HeaderConfig(this.text, {required this.flex});
}

Widget _buildDataTable<T>({
  required List<_HeaderConfig> headers,
  required List<T> rows,
  required List<Widget> Function(T item, int index) builder,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: headers.map((header) => 
              Expanded(
                flex: header.flex,
                child: Center(
                  child: Text(
                    header.text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF323232),
                    ),
                  ),
                ),
              ),
            ).toList(),
          ),
        ),
        ...List.generate(rows.length, (index) {
          final row = rows[index];
          final isGray = index % 2 == 0;
          return Container(
            color: isGray ? const Color(0xFFF9F9F9) : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: builder(row, index),
            ),
          );
        }),
      ],
    ),
  );
}

Widget _buildCell(String text, {
  required int flex,
  int maxLines = 1,
  bool isNumber = false,
  Color textColor = const Color(0xFF323232),
}) {
  return Expanded(
    flex: flex,
    child: Center(
      child: Text(
        text,
        style: TextStyle(
          fontSize: isNumber ? 15 : 14,
          color: textColor,
          fontWeight: isNumber ? FontWeight.w600 : FontWeight.normal,
        ),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    ),
  );
}

Widget _buildErrorWidget(String section) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          Text(
            '$section Error',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please check your connection',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    ),
  );
}

Widget _buildIndexErrorWidget() {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          const Text(
            'Index Required',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Firestore needs to create an index for this query.',
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            'This usually happens automatically and takes 5-10 minutes.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}