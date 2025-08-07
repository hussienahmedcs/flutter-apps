import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../data/models/center_config.dart';

class CenterConfigAdminPage extends StatefulWidget {
  final String centerCode;
  const CenterConfigAdminPage({super.key, required this.centerCode});

  @override
  State<CenterConfigAdminPage> createState() => _CenterConfigAdminPageState();
}

class _CenterConfigAdminPageState extends State<CenterConfigAdminPage> {
  late CenterConfig _config;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final doc = await FirebaseFirestore.instance.collection('centers').doc(widget.centerCode).get();
    // final rawData = doc.data()?['config'];
    final raw = doc.data()?['config'];
    final data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    setState(() {
      _config = CenterConfig.fromMap(data);
      _loading = false;
    });
  }

  Future<void> _saveConfig() async {
    await FirebaseFirestore.instance.collection('centers').doc(widget.centerCode).update({
      'config': _config.toMap(),
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuration saved.')));
  }

  Widget _buildSwitch(String label, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: (val) => setState(() => onChanged(val)),
    );
  }

  Widget _buildSlider(String label, double value, double max, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label (${value.toInt()})'),
        Slider(
          min: 0,
          max: max,
          divisions: max.toInt(),
          value: value,
          label: value.toInt().toString(),
          onChanged: (val) => setState(() => onChanged(val)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isWide = MediaQuery.of(context).size.width > 600;

    final configFields = <Widget>[
      ...[
        _buildSwitch('Learner can create session', _config.learnerCanCreateSession,
            (val) => _config = _config.copyWith(learnerCanCreateSession: val)),
        _buildSwitch('Teacher can create session', _config.teacherCanCreateSession,
            (val) => _config = _config.copyWith(teacherCanCreateSession: val)),
        _buildSwitch('Share sessions with learners', _config.shareSessionsWithLearners,
            (val) => _config = _config.copyWith(shareSessionsWithLearners: val)),
        _buildSwitch('Share sessions with teachers', _config.shareSessionsWithTeachers,
            (val) => _config = _config.copyWith(shareSessionsWithTeachers: val)),
        _buildSwitch('Learner can access exam page', _config.learnerCanAccessExamPage,
            (val) => _config = _config.copyWith(learnerCanAccessExamPage: val)),
        _buildSwitch('Teacher can access exam page', _config.teacherCanAccessExamPage,
            (val) => _config = _config.copyWith(teacherCanAccessExamPage: val)),
        _buildSwitch('Enable join requests', _config.enableJoinRequests,
            (val) => _config = _config.copyWith(enableJoinRequests: val)),
        _buildSwitch('Auto-approve learners', _config.autoApproveLearners,
            (val) => _config = _config.copyWith(autoApproveLearners: val)),
        _buildSwitch('Auto-approve instructors', _config.autoApproveInstructors,
            (val) => _config = _config.copyWith(autoApproveInstructors: val)),
        _buildSwitch('Gamification enabled', _config.enableGamification,
            (val) => _config = _config.copyWith(enableGamification: val)),
        _buildSlider('Max sessions per learner', _config.maxSessionsPerLearner.toDouble(), 50,
            (val) => _config = _config.copyWith(maxSessionsPerLearner: val.toInt())),
        _buildSlider('Max sessions per teacher', _config.maxSessionsPerTeacher.toDouble(), 100,
            (val) => _config = _config.copyWith(maxSessionsPerTeacher: val.toInt())),
      ]
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Center Configuration')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: isWide
                  ? GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 3.5,
                      children: configFields,
                    )
                  : ListView(
                      children: configFields,
                    ),
            ),
            ElevatedButton.icon(
              onPressed: _saveConfig,
              icon: const Icon(Icons.save),
              label: const Text('Save Configuration'),
            )
          ],
        ),
      ),
    );
  }
}
