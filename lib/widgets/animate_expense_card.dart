import 'expense_card.dart';
import 'package:flutter/material.dart';
import '../screens/home_screen.dart';

class AnimatedExpenseCard extends StatefulWidget {
  final ExpenseCardData expense;
  final int index;
  final VoidCallback? onTap;

  const AnimatedExpenseCard({
    required this.expense,
    required this.index,
    this.onTap,
  });

  @override
  State<AnimatedExpenseCard> createState() => AnimatedExpenseCardState();
}

class AnimatedExpenseCardState extends State<AnimatedExpenseCard> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.index * 200), () {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ExpenseCardBase(
          icon: widget.expense.icon,
          category: widget.expense.category,
          amount: widget.expense.amount,
          date: widget.expense.date,
          amountColor: widget.expense.color,
        ),
      ),
    );
  }
}