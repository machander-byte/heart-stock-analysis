import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  final String name;
  const Header({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.substring(0, 1) : 'U';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: const Color(0xFFE0F7FA),
            child: Text(initial, style: const TextStyle(color: Color(0xFF00ACC1), fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Hello,', style: TextStyle(color: Colors.grey)),
              Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
            ],
          ),
          const Spacer(),
          const Icon(Icons.menu, color: Color(0xFF00796B), size: 30),
        ],
      ),
    );
  }
}

