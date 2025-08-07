import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wordstory/data/models/center.dart';
import 'package:wordstory/data/models/center_request.dart';

class CenterDetailsPage extends StatefulWidget {
  final String centerCode;
  final String? userId;
  final Role userRole;

  const CenterDetailsPage({
    super.key,
    required this.centerCode,
    this.userId,
    this.userRole = Role.learner, // default to learner
  });

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
      final teachers = List<String>.from(center['teachers'] ?? []);

      // Check if joined
      final joined =
          widget.userRole == Role.learner ? learners.contains(widget.userId) : teachers.contains(widget.userId);

      // Check pending request
      bool pending = false;
      if (!joined) {
        final reqSnap = await centerRef
            .collection('requests')
            .where('centerCode', isEqualTo: widget.centerCode)
            .where('requesterRole', isEqualTo: widget.userRole.name)
            .where('status', isEqualTo: RequestStatus.pending.name)
            .where('type', isEqualTo: RequestType.join.name)
            .where('requesterId', isEqualTo: widget.userId)
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

  Future<void> _sendJoinRequest() async {
    try {
      final reqRef = FirebaseFirestore.instance
          .collection('centers')
          .doc(widget.centerCode)
          .collection('requests')
          .doc(widget.userId);

      final request = CenterRequest(
        id: reqRef.id,
        requesterId: widget.userId!,
        centerCode: widget.centerCode,
        requesterRole: widget.userRole,
        type: RequestType.join,
        status: RequestStatus.pending,
      );

      await reqRef.set(request.toMap());

      setState(() {
        _isPending = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Join request sent!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending request: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Center')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isInvalid = widget.centerCode.trim().isEmpty || _centerData == null;
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
            const SizedBox(height: 4),
            Text(
              'Joining as: ${widget.userRole.name.toUpperCase()}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.grey),
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
                onPressed: _sendJoinRequest,
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
