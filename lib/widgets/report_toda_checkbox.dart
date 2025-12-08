import 'package:flutter/material.dart';

class ReportTodaCheckbox extends StatefulWidget {
  final String label;
  final bool initialValue;
  final ValueChanged<bool?>? onChanged;

  const ReportTodaCheckbox({
    super.key,
    required this.label,
    this.initialValue = false,
    this.onChanged,
  });

  @override
  State<ReportTodaCheckbox> createState() => _ReportTodaCheckboxState();
}

class _ReportTodaCheckboxState extends State<ReportTodaCheckbox> {
  bool isChecked = false;

  @override
  void initState() {
    super.initState();
    isChecked = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 347,
      height: 86,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: ShapeDecoration(
        color: const Color(0xFFF2F4F5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Checkbox(
            value: isChecked,
            activeColor: const Color(0xFF1B4871), // color when checked
            side: const BorderSide(
              color: Color(0xFF1B4871), // border color
              width: 2, // adjust thickness if needed
            ),
            onChanged: (value) {
              setState(() {
                isChecked = value ?? false;
              });
              if (widget.onChanged != null) {
                widget.onChanged!(value);
              }
            },
          ),
        ],
      ),
    );
  }
}
