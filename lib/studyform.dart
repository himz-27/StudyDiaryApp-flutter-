import 'package:flutter/material.dart';

import 'study_database.dart';

/// Collects, validates, confirms and save one study log.
/// If [existingLog] is given, the form is prefilled and updates that record.
class StudyFormPage extends StatefulWidget {
  const StudyFormPage({super.key, this.existingLog});

  final Map<String, Object?>? existingLog;

  @override
  State<StudyFormPage> createState() => _StudyFormPageState();
}

class _StudyFormPageState extends State<StudyFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _minutesController = TextEditingController();
  final _notesController = TextEditingController();
  String? _subject;
  String _activity = 'Watch video';
  double _understanding = 3;
  bool _isSaving = false;

  static const List<String> _subjects = [
    'Mathematics',
    'Science',
    'Programming',
    'Languages',
    'Business',
    'Other',
  ];

  static const List<String> _activities = [
    'Watch video',
    'Write notes',
    'Practice questions',
    'Ask for help',
  ];

  bool get _isEditing => widget.existingLog != null;

  @override
  void initState() {
    super.initState();
    // Prefill every field when editing an existing record.
    final log = widget.existingLog;
    if (log != null) {
      _titleController.text = log['title'] as String;
      _minutesController.text = (log['minutes'] as num).toInt().toString();
      _notesController.text = log['notes'] as String;
      _subject = log['subject'] as String;
      _activity = log['activity'] as String;
      _understanding = (log['understanding'] as num).toDouble();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _minutesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _confirmSave() async {
    // Do not ask for confirmation until required fields pass validation.
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isEditing ? 'Confirm update' : 'Confirm study log'),
        content: Text(
          _isEditing ? 'Save changes to this study log?' : 'Save this study log?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Return the save result to the main screen so it can refresh its list.
    setState(() => _isSaving = true);
    var saved = false;
    try {
      final title = _titleController.text.trim();
      final minutes = int.parse(_minutesController.text.trim());
      final notes = _notesController.text.trim();
      final understanding = _understanding.round();

      if (_isEditing) {
        final updated = await StudyDatabase.instance.updateLog(
          id: widget.existingLog!['id'] as int,
          title: title,
          subject: _subject!,
          activity: _activity,
          minutes: minutes,
          understanding: understanding,
          notes: notes,
        );
        saved = updated > 0;
      } else {
        await StudyDatabase.instance.insertLog(
          title: title,
          subject: _subject!,
          activity: _activity,
          minutes: minutes,
          understanding: understanding,
          notes: notes,
        );
        saved = true;
      }
    } catch (_) {
      saved = false;
    }

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop(saved);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? (_isEditing
                    ? 'Study log updated successfully'
                    : 'Study log saved successfully')
              : 'Failed to save study log',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Study Log' : 'New Study Log')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                validator: (value) {
                  final title = value?.trim() ?? '';
                  if (title.isEmpty) return 'Enter what you studied';
                  if (title.length < 3) return 'Title must be at least 3 characters';
                  if (title.length > 50) return 'Title must be 50 characters or less';
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'What did you study? (topic)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
                value: _subject,
                validator: (value) => value == null ? 'Select a subject' : null,
                items: _subjects
                    .map(
                      (subject) => DropdownMenuItem<String>(
                        value: subject,
                        child: Text(subject),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _subject = value),
              ),
              const SizedBox(height: 16),
              const Text(
                'How did you study?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              // One radio button per study method.
              ..._activities.map(
                (activity) => RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(activity),
                  value: activity,
                  groupValue: _activity,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _activity = value);
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _minutesController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  final minutes = int.tryParse(value?.trim() ?? '');
                  if (minutes == null) return 'Enter whole minutes, e.g. 45';
                  if (minutes <= 0) return 'Minutes must be greater than zero';
                  if (minutes > 600) return 'Minutes must be 600 or less';
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Time spent (minutes)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Understanding after studying: ${_understanding.round()} / 5',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Slider(
                value: _understanding,
                min: 1,
                max: 5,
                divisions: 4,
                label: _understanding.round().toString(),
                onChanged: (value) => setState(() => _understanding = value),
              ),
              const Text('1 = still confused, 5 = fully understood'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _confirmSave,
                  child: Text(
                    _isSaving
                        ? 'Saving...'
                        : (_isEditing ? 'Update log' : 'Add log'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}