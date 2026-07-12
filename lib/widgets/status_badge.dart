import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {

    Color bgColor = Colors.orange.shade100;
    Color textColor = Colors.orange;

    if (status == "Approved") {
      bgColor = Colors.green.shade100;
      textColor = Colors.green;
    }

    if (status == "Rejected") {
      bgColor = Colors.red.shade100;
      textColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}