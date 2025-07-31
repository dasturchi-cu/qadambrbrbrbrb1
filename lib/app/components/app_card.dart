import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final List<BoxShadow>? boxShadow;

  const AppCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.boxShadow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.grey.withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
      ),
      child: child,
    );
  }
}
