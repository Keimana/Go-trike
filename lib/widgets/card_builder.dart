import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CardBuilder extends StatelessWidget {
  final double cardWidth;
  final String title;
  final String? iconPath;
  final VoidCallback? onTap;

  const CardBuilder({
    super.key,
    required this.cardWidth,
    required this.title,
    this.iconPath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(20),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        clipBehavior: Clip.antiAlias, // 👈 ensures InkWell ripple is clipped
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap, // 👈 tappable here
          child: Container(
            width: cardWidth,
            height: cardWidth * 0.16,
            padding: EdgeInsets.symmetric(horizontal: cardWidth * 0.04),
            child: Row(
              children: [
                if (iconPath != null) ...[
                  SvgPicture.asset(
                    iconPath!,
                    width: cardWidth * 0.07,
                    height: cardWidth * 0.07,
                  ),
                  SizedBox(width: cardWidth * 0.03),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: cardWidth * 0.04,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: cardWidth * 0.045),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
