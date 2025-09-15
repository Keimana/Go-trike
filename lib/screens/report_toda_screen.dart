import 'package:flutter/material.dart';
import '../widgets/report_toda_checkbox.dart';

class ReportTodaScreen extends StatefulWidget {
  final String toda;

  const ReportTodaScreen({
    super.key,
    required this.toda,
  });

  @override
  State<ReportTodaScreen> createState() => _ReportTodaScreenState();
}

class _ReportTodaScreenState extends State<ReportTodaScreen> {
  final List<String> issues = [
    "Late arrival",
    "Wrong route taken",
    "Overcharging",
    "Rude behavior",
  ];

  final Map<String, bool> selectedIssues = {};

  @override
  void initState() {
    super.initState();
    for (var issue in issues) {
      selectedIssues[issue] = false;
    }
  }

  void _showSuccessModal() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 327,
          height: 316,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Stack(
            children: [
              // Trike image
              Positioned(
                left: 124,
                top: 27,
                child: Container(
                  width: 80,
                  height: 75,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/images/trike.png"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              // Success text
              Positioned(
                left: 65,
                top: 146,
                child: const Text(
                  'Thanks for Reporting!',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Close button
              Positioned(
                left: 107,
                top: 224,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 113.38,
                    height: 60,
                    decoration: ShapeDecoration(
                      color: const Color(0xFF0097B2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Close',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Report a Toda',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(w * 0.05),
        child: ListView(
          children: [
            // TODA number
            Text(
              widget.toda,
              style: TextStyle(
                fontSize: w * 0.05,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: w * 0.04),

            // Checkboxes
            ...issues.map(
              (issue) => ReportTodaCheckbox(
                label: issue,
                initialValue: selectedIssues[issue]!,
                onChanged: (value) {
                  setState(() {
                    selectedIssues[issue] = value ?? false;
                  });
                },
              ),
            ),

            SizedBox(height: w * 0.04),
            GestureDetector(
              onTap: _showSuccessModal,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: w * 0.04),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'Submit Report',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: w * 0.045,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
