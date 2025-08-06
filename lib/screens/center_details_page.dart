import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wordstory/data/models/center.dart';
import 'package:wordstory/data/models/center_request.dart';
// import 'package:wordstory/services/auth_service.dart';

class CenterDetailsPage extends StatefulWidget {
  final String centerCode;
  final String? userId;

  const CenterDetailsPage({super.key, required this.centerCode, this.userId});

  @override
  _CenterDetailsPageState createState() => _CenterDetailsPageState();
}

class _CenterDetailsPageState extends State<CenterDetailsPage> {
  bool _loading = true;
  bool _isJoined = false;
  bool _isPending = false;
  Map<String, dynamic>? _centerData;

  @override
  void initState() {
    super.initState();
    _loadCenterDetails(widget.centerCode);
  }

  Future<void> _loadCenterDetails(String centerCode) async {
    if (widget.userId == null) {
      setState(() {
        _loading = true;
      });
      return;
    }
    try {
      setState(() {
        _loading = true;
      });
      final centerRef = FirebaseFirestore.instance.collection('centers').doc(centerCode);
      final centerSnap = await centerRef.get();
      if (!centerSnap.exists) {
        setState(() {
          _loading = false;
          _centerData = null;
        });
        return;
      }
      final center = centerSnap.data() as Map<String, dynamic>;
      final learners = List<String>.from(center['learners'] ?? []);

      // Check join status
      bool joined = learners.contains(widget.userId);
      bool pending = false;
      if (!joined) {
        final reqSnap = await centerRef
            .collection('requests')
            .where('centerCode', isEqualTo: widget.centerCode)
            .where('requesterRole', isEqualTo: Role.learner.name)
            .where('status', isEqualTo: RequestStatus.pending.name)
            .where('type', isEqualTo: RequestType.join.name)
            .get();
        pending = reqSnap.docs.isNotEmpty;
      }

      setState(() {
        _centerData = center;
        _isJoined = joined;
        _isPending = pending;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading center: $e')),
      );
    }
  }

  // Future<void> _sendJoinRequest() async {
  //   try {
  //     final reqRef = FirebaseFirestore.instance
  //         .collection('centers')
  //         .doc(widget.centerCode)
  //         .collection('student_requests')
  //         .doc(widget.userId);

  //     await reqRef.set({
  //       'id': widget.userId,
  //       'createdAt': FieldValue.serverTimestamp(),
  //       'status': 'pending',
  //     });

  //     setState(() {
  //       _isPending = true;
  //     });

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Join request sent!')),
  //     );
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error sending request: $e')),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Center')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isInvalid = widget.centerCode == null || widget.centerCode.trim().isEmpty || _centerData == null;
    if (isInvalid) {
      return Scaffold(
        appBar: AppBar(title: const Text('Center')),
        body: const Center(
          child: Text(
            'Invalid Center Code, call center!',
            style: TextStyle(fontSize: 16, color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Center Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_centerData!['logoUrl'] != null)
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(_centerData!['logoUrl']),
              ),
            const SizedBox(height: 16),
            Text(
              _centerData!['name'] ?? 'Unnamed Center',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            if (_centerData!['description'] != null)
              Text(
                _centerData!['description'],
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            const SizedBox(height: 20),
            if (_isJoined)
              const Chip(
                label: Text('You are already a member'),
                backgroundColor: Colors.green,
              )
            else if (_isPending)
              const Chip(
                label: Text('Join request pending'),
                backgroundColor: Colors.orange,
              )
            else
              ElevatedButton.icon(
                icon: const Icon(Icons.group_add),
                label: const Text('Join Center'),
                onPressed: null,
              ),
            const SizedBox(height: 20),
            if (_centerData!['email'] != null)
              ListTile(
                leading: const Icon(Icons.email),
                title: Text(_centerData!['email']),
              ),
            if (_centerData!['phone'] != null)
              ListTile(
                leading: const Icon(Icons.phone),
                title: Text(_centerData!['phone']),
              ),
            if (_centerData!['website'] != null)
              ListTile(
                leading: const Icon(Icons.link),
                title: Text(_centerData!['website']),
              ),
          ],
        ),
      ),
    );
  }
}
