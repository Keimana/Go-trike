import 'package:flutter/material.dart';

class AdminCard extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onFullscreenTap;

  const AdminCard({
    super.key,
    required this.title,
    required this.child,
    this.onFullscreenTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + fullscreen
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black),
              ),
              GestureDetector(
                onTap: onFullscreenTap,
                child: const Icon(Icons.fullscreen, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ------------------ Fullscreen Page ------------------
class FullscreenPage extends StatelessWidget {
  final String title;
  final Widget child;

  const FullscreenPage({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: child,
      ),
    );
  }
}

// ------------------ Card Content Helper ------------------
class CardListItem extends StatelessWidget {
  final String text;

  const CardListItem(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, color: Color(0xFF323232)),
      ),
    );
  }
}
