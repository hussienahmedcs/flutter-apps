import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wordstory/data/models/center.dart';
import 'package:wordstory/data/models/center_request.dart';
import 'package:wordstory/screens/admin/center_config_admin_page.dart';
import 'package:wordstory/services/firestore_service.dart';

class ManageCenterPage extends StatefulWidget {
  final String centerCode;

  const ManageCenterPage({super.key, required this.centerCode});

  @override
  _ManageCenterPageState createState() => _ManageCenterPageState();
}

class _ManageCenterPageState extends State<ManageCenterPage> {
  String logoUrl = '';
  String centerName = '';
  // String centerCode = '';
  XFile? _pickedImage;
  bool _loading = false;
  final FirestoreService db = FirestoreService();

  @override
  void initState() {
    super.initState();
    loadCenterInfo();
  }

  Future<void> loadCenterInfo() async {
    var doc = await db.centerRef(widget.centerCode).get();
    var data = doc.data()!;
    setState(() {
      logoUrl = data['logoUrl'] ?? '';
      centerName = data['name'];
      // centerCode = data['code'];
    });
  }

  Future<void> uploadLogo() async {
    final storage = FirebaseStorage.instance;
    final ref = storage.ref('logos/${widget.centerCode}.png');
    await ref.putData(await _pickedImage!.readAsBytes());
    logoUrl = await ref.getDownloadURL();
  }

  void saveCenterConfig() async {
    setState(() => _loading = true);
    if (_pickedImage != null) await uploadLogo();
    await db.centerRef(widget.centerCode).update({
      'logoUrl': logoUrl,
      'code': widget.centerCode,
    });
    setState(() => _loading = false);
  }

  void shareDeepLink() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Role'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, '101'),
            child: const Text('👩‍🎓 Learner'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, '102'),
            child: const Text('👨‍🏫 Teacher'),
          ),
        ],
      ),
    );

    if (selected != null) {
      final link = 'https://wordstory-fe3a3.web.app/join?center=${widget.centerCode}&type=$selected';
      Share.share('Join our Center using this link: $link');
    }
  }

  void pickImage() async {
    final picker = ImagePicker();
    _pickedImage = await picker.pickImage(source: ImageSource.gallery);
    setState(() {});
  }

  Widget _buildRequestTile(
      String title, List<QueryDocumentSnapshot> requests, Map<String, Map<String, dynamic>> users, Role role) {
    return ExpansionTile(
      title: Text('$title (${requests.length})'),
      children: requests.map((req) {
        final user = users[req['requesterId']];
        final userName = user?['name'] ?? 'Unknown';
        final userEmail = user?['email'] ?? '';

        return ListTile(
          title: Text(userName),
          subtitle: Text(userEmail),
          trailing: IconButton(
            icon: const Icon(Icons.check),
            onPressed: () async {
              final roleField = role == Role.learner ? 'learners' : 'teachers';

              await db.centerRef(widget.centerCode).update({
                roleField: FieldValue.arrayUnion([req['requesterId']])
              });

              await db
                  .centerRef(widget.centerCode)
                  .collection('requests')
                  .doc(req.id)
                  .update({'status': RequestStatus.approved.name});

              setState(() {});
            },
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isInvalid = widget.centerCode.trim().isEmpty;
    if (isInvalid) {
      return Scaffold(
        appBar: AppBar(title: const Text('Center')),
        body: const Center(
          child: Text(
            'Invalid Center Code',
            style: TextStyle(fontSize: 16, color: Colors.red),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Center')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: InkWell(
                  onTap: pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: _pickedImage != null
                        ? FileImage(File(_pickedImage!.path))
                        : (logoUrl.isNotEmpty ? NetworkImage(logoUrl) : null) as ImageProvider?,
                    child: logoUrl.isEmpty && _pickedImage == null ? const Icon(Icons.upload, size: 50) : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Center Name:', style: Theme.of(context).textTheme.titleMedium),
              Text(centerName, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Center Code: ${widget.centerCode}', style: const TextStyle(fontSize: 18)),
                  IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() => {})),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('Share Join Link'),
                onPressed: shareDeepLink,
              ),
              const SizedBox(height: 20),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: saveCenterConfig,
                      child: const Text('Save Configuration'),
                    ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.settings),
                label: const Text('Center Settings'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CenterConfigAdminPage(centerCode: widget.centerCode),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              StreamBuilder<QuerySnapshot>(
                stream: db
                    .centerRef(widget.centerCode)
                    .collection('requests')
                    .where('centerCode', isEqualTo: widget.centerCode)
                    .where('requesterRole', whereIn: [Role.learner.name, Role.instructor.name])
                    .where('status', isEqualTo: RequestStatus.pending.name)
                    .where('type', isEqualTo: RequestType.join.name)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Text('Error loading requests');
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text('No join requests');
                  }

                  var requests = snapshot.data!.docs;
                  final requesterIds = requests.map((d) => d['requesterId']).toList();

                  return FutureBuilder<QuerySnapshot>(
                    future: db.usersRef().where(FieldPath.documentId, whereIn: requesterIds).get(),
                    builder: (context, usersSnap) {
                      if (usersSnap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (usersSnap.hasError) {
                        return const Text('Error loading user details');
                      }

                      final users = {for (var u in usersSnap.data!.docs) u.id: u.data() as Map<String, dynamic>};

                      // Group requests by role
                      final learnerRequests = requests.where((r) => r['requesterRole'] == Role.learner.name).toList();
                      final instructorRequests =
                          requests.where((r) => r['requesterRole'] == Role.instructor.name).toList();

                      return Column(
                        children: [
                          if (learnerRequests.isNotEmpty)
                            _buildRequestTile('Learner Join Requests', learnerRequests, users, Role.learner),
                          if (instructorRequests.isNotEmpty)
                            _buildRequestTile('Instructor Join Requests', instructorRequests, users, Role.instructor),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              StreamBuilder<DocumentSnapshot>(
                stream: db.centerRef(widget.centerCode).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Text('Error loading members');
                  }

                  if (!snapshot.hasData || snapshot.data!.data() == null) {
                    return const Text('No data found');
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final List<dynamic> learnerIds = data['learners'] ?? [];
                  final List<dynamic> teacherIds = data['teachers'] ?? [];

                  final allUserIds = [...learnerIds, ...teacherIds].toSet().toList();

                  if (allUserIds.isEmpty) {
                    return const Text('No members');
                  }

                  return FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .where(FieldPath.documentId, whereIn: allUserIds)
                        .get(),
                    builder: (context, usersSnap) {
                      if (usersSnap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (usersSnap.hasError) {
                        return const Text('Error loading user details');
                      }

                      final users = {for (var u in usersSnap.data!.docs) u.id: u.data() as Map<String, dynamic>};

                      return Column(
                        children: [
                          ExpansionTile(
                            title: Text('Learners (${learnerIds.length})'),
                            children: learnerIds.map((id) {
                              final user = users[id];
                              final userName = user?['name'] ?? 'Unknown';
                              final userEmail = user?['email'] ?? '';
                              return ListTile(
                                title: Text(userName),
                                subtitle: Text(userEmail),
                                leading: const Icon(Icons.school),
                              );
                            }).toList(),
                          ),
                          ExpansionTile(
                            title: Text('Instructors (${teacherIds.length})'),
                            children: teacherIds.map((id) {
                              final user = users[id];
                              final userName = user?['name'] ?? 'Unknown';
                              final userEmail = user?['email'] ?? '';
                              return ListTile(
                                title: Text(userName),
                                subtitle: Text(userEmail),
                                leading: const Icon(Icons.person_outline),
                              );
                            }).toList(),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
