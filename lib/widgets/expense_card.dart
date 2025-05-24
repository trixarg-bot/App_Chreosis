import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:chreosis_app/widgets/animated_expense_list.dart';


class ExpenseCardBase extends StatelessWidget {
  final IconData icon;
  final String category;
  final String amount;
  final String date;
  final Color amountColor;
  

  const ExpenseCardBase({
    super.key,
    required this.icon,
    required this.category,
    required this.amount,
    required this.date,
    required this.amountColor,

  });

  

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFE1F5E9),
            child: Icon(icon, color: const Color(0xFF212121)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color.fromARGB(255, 174, 185, 190),
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}