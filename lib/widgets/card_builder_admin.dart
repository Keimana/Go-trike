import 'package:flutter/material.dart';

class AdminCard extends StatefulWidget {
  final String title;
  final Widget child;
  final VoidCallback? onFullscreenTap;
  final Color titleColor;

  const AdminCard({
    super.key,
    required this.title,
    required this.child,
    this.onFullscreenTap,
    this.titleColor = const Color(0xFF323232),
  });

  @override
  State<AdminCard> createState() => _AdminCardState();
}

class _AdminCardState extends State<AdminCard> {
  bool _isHovering = false;

  void _setHover(bool v) {
    if (!mounted) return;
    setState(() => _isHovering = v);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + fullscreen (row)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: widget.titleColor,
                ),
              ),

              // Hoverable fullscreen icon (no bg, just smooth scale)
              MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => _setHover(true),
                onExit: (_) => _setHover(false),
                child: AnimatedScale(
                  scale: _isHovering ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: widget.onFullscreenTap,
                    child: Icon(
                      Icons.fullscreen,
                      size: 22,
                      color: _isHovering
                          ? const Color(0xFF892CDD)
                          : const Color(0xFF333333),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          widget.child,
        ],
      ),
    );
  }
}
