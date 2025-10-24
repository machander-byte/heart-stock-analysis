import 'package:flutter/material.dart';
import '../widgets/tip_card.dart';

class RecommendedTipsScreen extends StatelessWidget {
  const RecommendedTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recommended Tips'), backgroundColor: Colors.transparent, elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          TipCard(icon: Icons.monitor_heart, title: 'Monitor Blood Pressure', description: 'High blood pressure is a major risk factor. Monitor it regularly and consult your doctor.'),
          TipCard(icon: Icons.smoking_rooms, title: 'Avoid Smoking', description: 'Smoking thickens your blood and increases the amount of plaque buildup in the arteries.'),
          TipCard(icon: Icons.fitness_center, title: 'Regular Exercise', description: 'Aim for at least 30 minutes of moderate-intensity exercise most days of the week.'),
          TipCard(icon: Icons.restaurant_menu, title: 'Healthy Diet', description: 'Eat plenty of fruits, vegetables, and whole grains. Limit saturated fats and salt.'),
          TipCard(icon: Icons.no_drinks, title: 'Limit Alcohol', description: 'Excessive alcohol consumption can raise your blood pressure and increase your risk of stroke.'),
        ],
      ),
    );
  }
}

