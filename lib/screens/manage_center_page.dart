import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

class ManageCenterPage extends StatefulWidget {
  final String centerCode;

  const ManageCenterPage({super.key, required this.centerCode});

  @override
  _ManageCenterPageState createState() => _ManageCenterPageState();
}

class _ManageCenterPageState extends State<ManageCenterPage> {
  String logoUrl = '';
  String centerName = '';
  String centerCode = '';
  XFile? _pickedImage;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    loadCenterInfo();
  }

  Future<void> loadCenterInfo() async {
    var doc = await FirebaseFirestore.instance.collection('centers').doc(widget.centerCode).get();
    var data = doc.data()!;
    setState(() {
      logoUrl = data['logoUrl'] ?? '';
      centerName = data['name'];
      centerCode = data['code'];
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
    await FirebaseFirestore.instance.collection('centers').doc(widget.centerCode).update({
      'logoUrl': logoUrl,
      'code': centerCode,
    });
    setState(() => _loading = false);
  }

  void shareDeepLink() {
    final link = 'https://wordstory-fe3a3.web.app/code/$centerCode';
    Share.share('Join our Center using this link: $link');
  }

  void pickImage() async {
    final picker = ImagePicker();
    _pickedImage = await picker.pickImage(source: ImageSource.gallery);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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
                  Text('Center Code: $centerCode', style: const TextStyle(fontSize: 18)),
                  IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() => centerCode = centerCode)),
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
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('centers')
                    .doc(widget.centerCode) // <-- make sure this is the correct field (id vs code)
                    .collection('student_requests')
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
                  return ExpansionTile(
                    title: Text('Learner Join Requests (${requests.length})'),
                    children: requests
                        .map((req) => ListTile(
                              title: Text(req['name'] ?? 'Unknown'),
                              subtitle: Text(req['email'] ?? ''),
                              trailing: IconButton(
                                icon: const Icon(Icons.check),
                                onPressed: () async {
                                  // Approve request
                                  await FirebaseFirestore.instance.collection('centers').doc(widget.centerCode).update({
                                    'learners': FieldValue.arrayUnion([req.id]) // Add learner UID to array
                                  });
                                  await req.reference.delete();
                                },
                              ),
                            ))
                        .toList(),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
