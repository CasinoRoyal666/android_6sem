import 'package:flutter/material.dart';

class ExpandableItem extends StatefulWidget {
  final String title;
  final Widget? content;
  final bool initiallyExpanded;

  const ExpandableItem({
    super.key,
    required this.title,
    this.content,
    this.initiallyExpanded = false,
  });

  @override
  State<ExpandableItem> createState() => _ExpandableItemState();
}

class _ExpandableItemState extends State<ExpandableItem> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header/Title section
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                Icon(_isExpanded ? Icons.expand_less : Icons.chevron_right),
              ],
            ),
          ),
        ),

        // Expandable content section
        if (_isExpanded && widget.content != null)
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: widget.content,
            ),
          ),
      ],
    );
  }
}