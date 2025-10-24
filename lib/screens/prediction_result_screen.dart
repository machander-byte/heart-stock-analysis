import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class PredictionResultScreen extends StatefulWidget {
  final Map<String, dynamic> result;
  final Map<String, dynamic> input; // includes name + key fields
  const PredictionResultScreen({super.key, required this.result, required this.input});

  @override
  State<PredictionResultScreen> createState() => _PredictionResultScreenState();
}

class _PredictionResultScreenState extends State<PredictionResultScreen> {
  @override
  void initState() {
    super.initState();
    _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toIso8601String();
    // Normalize to a fraction [0,1] for assistant screen compatibility
    double? frac;
    final sp = widget.result['stroke_prediction'];
    final spp = widget.result['stroke_probability'];
    if (sp is num) {
      frac = sp.toDouble();
      if (frac > 1) frac = frac / 100.0; // in case backend sends percent here
    } else if (spp is num) {
      frac = spp.toDouble() / 100.0;
    } else if (spp is String) {
      final v = double.tryParse(spp);
      if (v != null) frac = v / 100.0;
    }
    await prefs.setString('last_prediction', (frac ?? 0).toString());
    await prefs.setString('last_prediction_time', now);
  }

  String _stage(double pct) {
    if (pct >= 0.75) return 'Very High Risk';
    if (pct >= 0.50) return 'High Risk';
    if (pct >= 0.25) return 'Moderate Risk';
    return 'Low Risk';
  }

  List<String> _tips(String stage) {
    switch (stage) {
      case 'Very High Risk':
      case 'High Risk':
        return const [
          'Book an appointment with your clinician.',
          'Check blood pressure twice daily and log readings.',
          'Reduce salt, avoid smoking and alcohol, manage stress.',
          'At least 150 minutes/week of moderate exercise.',
        ];
      case 'Moderate Risk':
        return const [
          'Adopt DASH or Mediterranean-style diet.',
          'Exercise 30 minutes most days; add two strength sessions.',
          'Maintain healthy weight and sleep 7-9 hours.',
        ];
      default:
        return const [
          'Keep up healthy habits and regular checkups.',
          'Stay active and limit excess salt and sugar.',
        ];
    }
  }

  Future<void> _downloadPdf(BuildContext context, double prediction) async {
    final doc = pw.Document();
    final name = (widget.input['name'] as String? ?? '').trim();
    final dt = DateTime.now();
    final displayNow = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} - ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final pct = (prediction * 100).toStringAsFixed(0);
    final stage = _stage(prediction);

    pw.Widget row(String k, String v) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(width: 0.2, color: PdfColors.grey300)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [pw.Text(k, style: pw.TextStyle(color: PdfColors.grey800)), pw.Text(v, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))],
          ),
        );

    final fields = <MapEntry<String, String>>[
      MapEntry('Name', name.isEmpty ? '-' : name),
      MapEntry('Age', (widget.input['age'] ?? '-').toString()),
      MapEntry('Gender', (widget.input['gender'] ?? '-').toString()),
      MapEntry('Systolic BP', (widget.input['systolic_bp'] ?? '-').toString()),
      MapEntry('Diastolic BP', (widget.input['diastolic_bp'] ?? '-').toString()),
      MapEntry('BMI', (widget.input['bmi'] ?? '-').toString()),
      MapEntry('Glucose', (widget.input['avg_glucose_level'] ?? '-').toString()),
      MapEntry('Smoking', (widget.input['smoking_status'] ?? '-').toString()),
      MapEntry('Alcoholic', ((widget.input['alcoholic'] ?? 0) == 1) ? 'Yes' : 'No'),
      MapEntry('Family History', ((widget.input['family_history'] ?? 0) == 1) ? 'Yes' : 'No'),
      MapEntry('Residence', (widget.input['Residence_type'] ?? '-').toString()),
      MapEntry('Work Type', (widget.input['work_type'] ?? '-').toString()),
    ];

    doc.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Heart Stroke Risk Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.Text(displayNow, style: const pw.TextStyle(color: PdfColors.grey600)),
              ],
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.cyan50,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('Risk Percentage', style: const pw.TextStyle(color: PdfColors.grey700)),
                  pw.Text('$pct%', style: pw.TextStyle(fontSize: 42, fontWeight: pw.FontWeight.bold, color: PdfColors.cyan800)),
                ]),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: stage.contains('Low') ? PdfColors.green100 : (stage.contains('Moderate') ? PdfColors.orange100 : PdfColors.red100),
                    borderRadius: pw.BorderRadius.circular(24),
                  ),
                  child: pw.Text(stage, style: pw.TextStyle(color: stage.contains('Low') ? PdfColors.green900 : (stage.contains('Moderate') ? PdfColors.orange900 : PdfColors.red900), fontWeight: pw.FontWeight.bold)),
                )
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text('Patient Details', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Column(children: fields.map((e) => row(e.key, e.value)).toList()),
          ),
          pw.SizedBox(height: 16),
          pw.Text('Recommendations', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Bullet(text: _tips(stage)[0]),
          ..._tips(stage).skip(1).map((t) => pw.Bullet(text: t)),
          pw.SizedBox(height: 8),
          pw.Text('This report is informational and not a medical diagnosis.', style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 10)),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save(), name: 'heart_stroke_risk_$pct.pdf');
  }

  @override
  Widget build(BuildContext context) {
    // Normalize to fraction [0,1]
    double prediction = 0.0;
    final sp = widget.result['stroke_prediction'];
    final spp = widget.result['stroke_probability'];
    if (sp is num) {
      prediction = sp.toDouble();
      if (prediction > 1) prediction = prediction / 100.0;
    } else if (spp is num) {
      prediction = spp.toDouble() / 100.0;
    } else if (spp is String) {
      final v = double.tryParse(spp);
      if (v != null) prediction = v / 100.0;
    }
    final percentage = (prediction * 100).toStringAsFixed(0);
    final apiStage = widget.result['risk_label'] as String?; // e.g., "🔵 Low Risk"
    final stage = apiStage == null || apiStage.isEmpty ? _stage(prediction) : apiStage;
    final isHighRisk = prediction > 0.5;
    final name = (widget.input['name'] as String? ?? '').trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Prediction Result')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(colors: [Colors.cyan.shade50, Colors.white]),
              border: Border.all(color: const Color(0xFFB2EBF2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name.isEmpty ? 'Result' : 'Result for $name', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      const Text('Risk Percentage', style: TextStyle(color: Colors.black54)),
                      const SizedBox(height: 4),
                      const SizedBox(height: 2),
                      Text('$percentage%', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF00796B))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isHighRisk
                        ? Colors.red.shade50
                        : (prediction >= 0.25 ? Colors.orange.shade50 : Colors.green.shade50),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isHighRisk ? Colors.red.shade200 : (prediction >= 0.25 ? Colors.orange.shade200 : Colors.green.shade200)),
                  ),
                  child: Text(
                    stage,
                    style: TextStyle(
                      color: isHighRisk ? Colors.red.shade800 : (prediction >= 0.25 ? Colors.orange.shade800 : Colors.green.shade800),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Summary', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _kv('Age', '${widget.input['age'] ?? '-'}'),
                  _kv('Gender', '${widget.input['gender'] ?? '-'}'),
                  _kv('Blood Pressure', '${widget.input['systolic_bp'] ?? '-'}/${widget.input['diastolic_bp'] ?? '-'}'),
                  _kv('BMI', '${widget.input['bmi'] ?? '-'}'),
                  _kv('Glucose', '${widget.input['avg_glucose_level'] ?? '-'}'),
                  _kv('Smoking', '${widget.input['smoking_status'] ?? '-'}'),
                  _kv('Alcoholic', ((widget.input['alcoholic'] ?? 0) == 1) ? 'Yes' : 'No'),
                  _kv('Family History', ((widget.input['family_history'] ?? 0) == 1) ? 'Yes' : 'No'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recommendations', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ..._tips(stage).map((t) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle, size: 18, color: Color(0xFF00ACC1)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(t)),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  onPressed: () => _downloadPdf(context, prediction),
                  label: const Text('Download PDF'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back to Form'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(k, style: const TextStyle(color: Colors.black54)), Text(v, style: const TextStyle(fontWeight: FontWeight.w600))],
      ),
    );
  }
}
