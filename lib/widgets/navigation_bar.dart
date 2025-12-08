import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const BottomNavigationBarWidget({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    const inactiveColor = Color(0xFF323232); // #323232

    final icons = [
      'assets/icons/home.svg',
      'assets/icons/description.svg',
      'assets/icons/person.svg',
    ];

    final circleSize = w * 0.13;
    final iconSize = w * 0.07;
    final bottomPadding = h * 0.03;

    final buttonCenters = [
      w * 0.11 + (w * 0.78) / 6,
      w * 0.11 + (w * 0.78) / 2,
      w * 0.11 + (w * 0.78) * 5 / 6,
    ];

    final grayBarWidth = w * 0.78;
    final grayBarHeight = circleSize * 1.2;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        height: circleSize + bottomPadding + 20,
        width: w,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Gray pill background
            Positioned(
              left: (w - grayBarWidth) / 2,
              bottom: bottomPadding + (circleSize - grayBarHeight) / 2,
              child: Container(
                width: grayBarWidth,
                height: grayBarHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(grayBarHeight / 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),
            ),

            // Purple circle animation
            for (int i = 0; i < 3; i++)
              Positioned(
                left: buttonCenters[i] - circleSize / 2,
                bottom: bottomPadding,
                child: AnimatedScale(
                  scale: selectedIndex == i ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.elasticOut,
                  child: Container(
                    width: circleSize,
                    height: circleSize,
                    decoration: const ShapeDecoration(
                      color: Color(0xFF1B4871),
                      shape: OvalBorder(),
                    ),
                  ),
                ),
              ),

            // Icons
            for (int i = 0; i < 3; i++)
              Positioned(
                left: buttonCenters[i] - iconSize / 2,
                bottom: bottomPadding + (circleSize - iconSize) / 2,
                child: GestureDetector(
                  onTap: () => onTap(i),
                  child: SvgPicture.asset(
                    icons[i],
                    width: iconSize,
                    height: iconSize,
                    color: selectedIndex == i ? Colors.white : inactiveColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
