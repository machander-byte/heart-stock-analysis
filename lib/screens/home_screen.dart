import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

import '../utils/ui.dart';
import '../widgets/header.dart';
import 'prediction_result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Jade West');
  final _ageController = TextEditingController();
  String? _gender = 'Male';
  int? _hypertension = 0;
  final _systolicBpController = TextEditingController();
  final _diastolicBpController = TextEditingController();
  int? _heartDisease = 0;
  int? _isMarried = 0;
  String? _workType = 'Private';
  String? _residenceType = 'Urban';
  String? _smokingStatus = 'never smoked';
  int? _isAlcoholic = 0;
  int? _familyHistory = 0;
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _bmiController = TextEditingController();
  final _glucoseController = TextEditingController();
  final _sleepController = TextEditingController();
  final _exerciseController = TextEditingController();
  int? _excessSalt = 0;
  bool _isLoading = false;
  static const _draftKey = 'form_draft_v1';

  @override
  void initState() {
    super.initState();
    _heightController.addListener(_calculateBmi);
    _weightController.addListener(_calculateBmi);
    _loadProfileName();
    _restoreDraft();
  }

  Future<void> _loadProfileName() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('user_name');
    if (saved != null && saved.isNotEmpty) {
      _nameController.text = saved;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _heightController.removeListener(_calculateBmi);
    _weightController.removeListener(_calculateBmi);
    _nameController.dispose();
    _ageController.dispose();
    _systolicBpController.dispose();
    _diastolicBpController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _bmiController.dispose();
    _glucoseController.dispose();
    _sleepController.dispose();
    _exerciseController.dispose();
    super.dispose();
  }

  void _calculateBmi() {
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);
    if (height != null && weight != null && height > 0) {
      final heightInMeters = height / 100;
      final bmi = weight / (heightInMeters * heightInMeters);
      _bmiController.text = bmi.toStringAsFixed(2);
    }
  }

  Future<void> _restoreDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _ageController.text = (data['age'] ?? '').toString();
      _gender = data['gender'] as String? ?? _gender;
      _hypertension = data['hypertension'] as int? ?? _hypertension;
      _systolicBpController.text = (data['systolic_bp'] ?? '').toString();
      _diastolicBpController.text = (data['diastolic_bp'] ?? '').toString();
      _heartDisease = data['heart_disease'] as int? ?? _heartDisease;
      _isMarried = data['is_married'] as int? ?? _isMarried;
      _workType = data['work_type'] as String? ?? _workType;
      _residenceType = data['residence_type'] as String? ?? _residenceType;
      _smokingStatus = data['smoking_status'] as String? ?? _smokingStatus;
      _isAlcoholic = data['alcoholic'] as int? ?? _isAlcoholic;
      _familyHistory = data['family_history'] as int? ?? _familyHistory;
      _heightController.text = (data['height'] ?? '').toString();
      _weightController.text = (data['weight'] ?? '').toString();
      _bmiController.text = (data['bmi'] ?? '').toString();
      _glucoseController.text = (data['avg_glucose_level'] ?? '').toString();
      _sleepController.text = (data['sleep_hours'] ?? '').toString();
      _exerciseController.text = (data['exercise_mins'] ?? '').toString();
      _excessSalt = data['excess_salt'] as int? ?? _excessSalt;
      if (mounted) setState(() {});
    } catch (_) {
      // ignore corrupt draft
    }
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      "age": _ageController.text,
      "gender": _gender,
      "hypertension": _hypertension,
      "systolic_bp": _systolicBpController.text,
      "diastolic_bp": _diastolicBpController.text,
      "heart_disease": _heartDisease,
      "is_married": _isMarried,
      "work_type": _workType,
      "residence_type": _residenceType,
      "smoking_status": _smokingStatus,
      "alcoholic": _isAlcoholic,
      "family_history": _familyHistory,
      "height": _heightController.text,
      "weight": _weightController.text,
      "bmi": _bmiController.text,
      "avg_glucose_level": _glucoseController.text,
      "sleep_hours": _sleepController.text,
      "exercise_mins": _exerciseController.text,
      "excess_salt": _excessSalt,
    };
    await prefs.setString(_draftKey, jsonEncode(data));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Draft saved')));
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
    _ageController.clear();
    _gender = 'Male';
    _hypertension = 0;
    _systolicBpController.clear();
    _diastolicBpController.clear();
    _heartDisease = 0;
    _isMarried = 0;
    _workType = 'Private';
    _residenceType = 'Urban';
    _smokingStatus = 'never smoked';
    _isAlcoholic = 0;
    _familyHistory = 0;
    _heightController.clear();
    _weightController.clear();
    _bmiController.clear();
    _glucoseController.clear();
    _sleepController.clear();
    _exerciseController.clear();
    _excessSalt = 0;
    if (mounted) setState(() {});
  }

  Future<void> _getPrediction() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    String yesNo(int? v) => v == 1 ? 'Yes' : 'No';
    String mapSmoking(String? v) {
      switch (v) {
        case 'never smoked':
          return 'Never';
        case 'formerly smoked':
          return 'Formerly';
        case 'smokes':
          return 'Smokes';
        default:
          return 'Never';
      }
    }
    String mapWork(String? v) => v ?? 'Private';

    final requestData = {
      "age": int.tryParse(_ageController.text) ?? 0,
      "gender": _gender,
      "hypertension": yesNo(_hypertension),
      "heart_disease": yesNo(_heartDisease),
      "ever_married": _isMarried == 1 ? "Yes" : "No",
      "work_type": mapWork(_workType),
      "Residence_type": _residenceType,
      "avg_glucose_level": double.tryParse(_glucoseController.text) ?? 0.0,
      "bmi": double.tryParse(_bmiController.text) ?? 0.0,
      "smoking_status": mapSmoking(_smokingStatus),
      "systolic_bp": int.tryParse(_systolicBpController.text) ?? 0,
      "diastolic_bp": int.tryParse(_diastolicBpController.text) ?? 0,
      "alcoholic": yesNo(_isAlcoholic),
      "family_history": yesNo(_familyHistory),
      "sleep_hours": int.tryParse(_sleepController.text) ?? 0,
      "exercise_mins": int.tryParse(_exerciseController.text) ?? 0,
      "excess_salt": yesNo(_excessSalt),
    };

    // For report generation (not sent to API)
    final reportInput = {
      "name": _nameController.text.trim(),
      ...requestData,
    };

    try {
      // Wake up server quickly (non-fatal) for cold starts.
      try { await http.get(Uri.parse(apiBaseUrl)).timeout(const Duration(seconds: 2)); } catch (_) {}
      final response = await http
          .post(
            Uri.parse('$apiBaseUrl/predict'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestData),
          )
          .timeout(const Duration(seconds: 25));
      if (response.statusCode == 200 && mounted) {
        final decoded = jsonDecode(response.body);
        Map<String, dynamic> result;
        if (decoded is List && decoded.isNotEmpty) {
          result = Map<String, dynamic>.from(decoded[0] as Map);
        } else if (decoded is Map) {
          result = Map<String, dynamic>.from(decoded as Map);
        } else {
          throw const FormatException('Unexpected response format');
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PredictionResultScreen(result: result, input: reportInput),
          ),
        );
      } else {
        // Try to surface server-provided error text if available
        String details = '';
        try { details = ': ' + (response.body.isNotEmpty ? response.body : ''); } catch (_) {}
        _showError('Server error ${response.statusCode}$details');
      }
    } on http.ClientException catch (e) {
      _showError('Network error: ${e.message}');
    } on FormatException {
      _showError('Invalid response from server.');
    } on TimeoutException {
      _showError('Request timed out. Please try again.');
    } catch (_) {
      _showError('Failed to connect. Please check your internet connection.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Header(name: _nameController.text),
                    const SizedBox(height: 24),
                    const Text('Inputs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
                    const SizedBox(height: 16),
                    _buildInputField(controller: _ageController, label: 'Age', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                    _buildDropdownField(label: 'Gender', value: _gender, options: const ['Male', 'Female', 'Other'], onChanged: (val) => setState(() => _gender = val)),
                    _buildYesNoField(label: 'Hypertension', groupValue: _hypertension, onChanged: (val) => setState(() => _hypertension = val)),
                    _buildInputField(controller: _systolicBpController, label: 'Systolic BP', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                    _buildInputField(controller: _diastolicBpController, label: 'Diastolic BP', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                    _buildYesNoField(label: 'Heart Disease', groupValue: _heartDisease, onChanged: (val) => setState(() => _heartDisease = val)),
                    _buildYesNoField(label: 'Married?', groupValue: _isMarried, onChanged: (val) => setState(() => _isMarried = val)),
                    _buildDropdownField(label: 'Work Type', value: _workType, options: const ['Private', 'Self-employed', 'Govt', 'Children', 'Never worked'], onChanged: (val) => setState(() => _workType = val)),
                    _buildDropdownField(label: 'Residence Type', value: _residenceType, options: const ['Urban', 'Rural'], onChanged: (val) => setState(() => _residenceType = val)),
                    _buildDropdownField(label: 'Smoking Status', value: _smokingStatus, options: const ['never smoked', 'formerly smoked', 'smokes'], onChanged: (val) => setState(() => _smokingStatus = val)),
                    _buildYesNoField(label: 'Alcoholic', groupValue: _isAlcoholic, onChanged: (val) => setState(() => _isAlcoholic = val)),
                    _buildYesNoField(label: 'Family History of Stroke', groupValue: _familyHistory, onChanged: (val) => setState(() => _familyHistory = val)),
                    _buildInputField(controller: _heightController, label: 'Height (cm)', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]),
                    _buildInputField(controller: _weightController, label: 'Weight (kg)', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]),
                    _buildInputField(controller: _bmiController, label: 'Body Mass Index (BMI)', readOnly: true),
                    _buildInputField(controller: _glucoseController, label: 'Average Glucose Level', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]),
                    _buildInputField(controller: _sleepController, label: 'Sleep (hours/day)', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                    _buildInputField(controller: _exerciseController, label: 'Exercise (mins/day)', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                    _buildYesNoField(label: 'Do you consume Excess Salt?', groupValue: _excessSalt, onChanged: (val) => setState(() => _excessSalt = val)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _getPrediction,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: const Color(0xFF26C6DA), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('Heart Stroke Prediction', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saveDraft,
                            child: const Text('Save Draft'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _clearDraft,
                            child: const Text('Clear'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ].map((w) => Padding(padding: const EdgeInsets.only(bottom: 16), child: w)).toList(),
                ),
              ),
            ),
            if (_isLoading) Container(color: Colors.black54, child: const Center(child: CircularProgressIndicator())),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String label, TextInputType keyboardType = TextInputType.text, bool readOnly = false, List<TextInputFormatter>? inputFormatters}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      inputFormatters: inputFormatters,
      decoration: inputDecoration().copyWith(labelText: label),
      validator: (v) => v!.isEmpty ? 'Please enter $label' : null,
    );
  }

  Widget _buildDropdownField({required String label, required String? value, required List<String> options, required ValueChanged<String?> onChanged}) {
    return DropdownButtonFormField<String>(
      value: value,
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
      onChanged: onChanged,
      decoration: inputDecoration().copyWith(labelText: label),
    );
  }

  Widget _buildYesNoField({required String label, required int? groupValue, required ValueChanged<int?> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(children: [
          _buildYesNoOption(label: 'Yes', value: 1, groupValue: groupValue, onChanged: onChanged),
          const SizedBox(width: 16),
          _buildYesNoOption(label: 'No', value: 0, groupValue: groupValue, onChanged: onChanged),
        ]),
      ],
    );
  }

  Widget _buildYesNoOption({required String label, required int value, required int? groupValue, required ValueChanged<int?> onChanged}) {
    final bool isSelected = value == groupValue;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00ACC1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFB2EBF2)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF00796B), fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
