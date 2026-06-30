import 'package:flutter/material.dart';
import 'home_dashboard_screen.dart';

class PlacementResultScreen extends StatelessWidget {
  final String cefrLevel;
  final String rationale;
  final List<Map<String, dynamic>> review;

  const PlacementResultScreen({
    super.key,
    required this.cefrLevel,
    required this.rationale,
    required this.review,
  });

  @override
  Widget build(BuildContext context) {
    final correct = review.where((r) => r['isCorrect'] == true).length;
    return Scaffold(
      appBar: AppBar(title: const Text('תוצאות מבחן הרמה'), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('הרמה שלך', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(cefrLevel, style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 8),
                  Text('ענית נכון על $correct מתוך ${review.length}'),
                  const SizedBox(height: 8),
                  Text(rationale, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('סקירת תשובות', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...review.map(_reviewTile),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeDashboardScreen()),
              (r) => false,
            ),
            child: const Text('בוא נתחיל ללמוד'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _reviewTile(Map<String, dynamic> r) {
    final ok = r['isCorrect'] == true;
    final promptHe = r['promptHe']?.toString() ?? '';
    final explanationHe = r['explanationHe']?.toString() ?? '';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(ok ? Icons.check_circle : Icons.cancel,
                    color: ok ? Colors.green : Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(r['prompt']?.toString() ?? '',
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            if (promptHe.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(promptHe,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            const SizedBox(height: 6),
            Text('התשובה שלך: ${r['chosen']}', textDirection: TextDirection.ltr),
            if (!ok)
              Text('התשובה הנכונה: ${r['correct']}',
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            if (explanationHe.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('הסבר: $explanationHe',
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(fontStyle: FontStyle.italic)),
              ),
          ],
        ),
      ),
    );
  }
}
