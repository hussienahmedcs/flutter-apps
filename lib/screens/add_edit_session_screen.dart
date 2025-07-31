import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/session_model.dart';
import '../providers/session_provider.dart';
import '../providers/auth_provider.dart';

/// Form screen used to create or edit a vocabulary session.  Users
/// supply a title, date and optional notes.  When editing, fields
/// are prefilled with existing values.  Upon saving, the session is
/// persisted via [SessionProvider].
class AddEditSessionScreen extends StatefulWidget {
  final Session? session;
  const AddEditSessionScreen({Key? key, this.session}) : super(key: key);

  @override
  State<AddEditSessionScreen> createState() => _AddEditSessionScreenState();
}

class _AddEditSessionScreenState extends State<AddEditSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final session = widget.session;
    _titleController = TextEditingController(text: session?.title ?? '');
    _notesController = TextEditingController(text: session?.notes ?? '');
    _selectedDate = session?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<SessionProvider>();
    final uid = Provider.of<AuthProvider>(context, listen: false).user?.uid ?? '';
    final newSession = Session(
      id: widget.session?.id ?? '',
      userId: uid,
      title: _titleController.text.trim(),
      date: _selectedDate,
      notes: _notesController.text.trim(),
      createdAt: widget.session?.createdAt ?? DateTime.now(),
    );
    await provider.saveSession(newSession);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session == null ? 'New Session' : 'Edit Session'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate.toLocal().toString().split(' ').first,
                      ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}