import 'package:flutter/material.dart';
import '../widgets/report_toda_checkbox.dart';
import '../services/report_service.dart';

class ReportTodaScreen extends StatefulWidget {
  final String rideId;
  final String toda;
  final String userAddress;
  final String destinationAddress;

  const ReportTodaScreen({
    super.key,
    required this.rideId,
    required this.toda,
    required this.userAddress,
    required this.destinationAddress,
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
  final TextEditingController _commentsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    for (var issue in issues) {
      selectedIssues[issue] = false;
    }
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    // Get selected issues
    final selected = selectedIssues.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one issue'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await ReportService.submitReport(
        rideId: widget.rideId,
        todaNumber: widget.toda,
        userAddress: widget.userAddress,
        destinationAddress: widget.destinationAddress,
        issues: selected,
        additionalComments: _commentsController.text.trim().isNotEmpty
            ? _commentsController.text.trim()
            : null,
      );

      if (success && mounted) {
        _showSuccessModal();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit report. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSuccessModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
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
              const Positioned(
                left: 65,
                top: 146,
                child: Text(
                  'Thanks for Reporting!',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Subtitle
              const Positioned(
                left: 40,
                top: 175,
                right: 40,
                child: Text(
                  'We will review your report',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              // Close button
              Positioned(
                left: 107,
                top: 224,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to activity logs
                  },
                  child: Container(
                    width: 113.38,
                    height: 60,
                    decoration: ShapeDecoration(
                      color: const Color(0xFF1B4871),
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
      body: Stack(
        children: [
          Padding(
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
                SizedBox(height: w * 0.02),

                // Route info
                Container(
                  padding: EdgeInsets.all(w * 0.03),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Color(0xFF1B4871)),
                          SizedBox(width: w * 0.02),
                          Expanded(
                            child: Text(
                              widget.userAddress,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: w * 0.02),
                      Row(
                        children: [
                          const Icon(Icons.flag, size: 16, color: Colors.red),
                          SizedBox(width: w * 0.02),
                          Expanded(
                            child: Text(
                              widget.destinationAddress,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: w * 0.04),

                // Issues label
                const Text(
                  'What went wrong?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: w * 0.02),

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

                // Additional comments
                const Text(
                  'Additional Comments (Optional)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: w * 0.02),
                TextField(
                  controller: _commentsController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Provide more details about your experience...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF1B4871)),
                    ),
                  ),
                ),

                SizedBox(height: w * 0.04),

                // Submit button
                GestureDetector(
                  onTap: _isSubmitting ? null : _submitReport,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: w * 0.04),
                    decoration: BoxDecoration(
                      color: _isSubmitting 
                          ? Colors.grey 
                          : const Color(0xFFFF3B30),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: _isSubmitting
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          )
                        : Text(
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
        ],
      ),
    );
  }
}