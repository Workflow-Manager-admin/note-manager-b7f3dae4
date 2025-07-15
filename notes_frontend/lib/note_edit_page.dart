import 'package:flutter/material.dart';
import 'note_model.dart';

// PUBLIC_INTERFACE
class NoteEditPage extends StatefulWidget {
  final Note? note;
  const NoteEditPage({super.key, this.note});

  @override
  State<NoteEditPage> createState() => _NoteEditPageState();
}

class _NoteEditPageState extends State<NoteEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveNote() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final now = DateTime.now();
    final note = (widget.note ?? Note(title: '', content: ''))
        .copyWith(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          updatedAt: now,
          createdAt: widget.note?.createdAt ?? now,
        );

    Navigator.of(context).pop(note);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.note != null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Note' : 'New Note'),
        backgroundColor: theme.colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                key: const Key("noteTitle"),
                controller: _titleController,
                style: theme.textTheme.titleMedium,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
                maxLength: 64,
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Title cannot be empty'
                        : null,
                enabled: !_isSaving,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TextFormField(
                  key: const Key("noteContent"),
                  controller: _contentController,
                  style: theme.textTheme.bodyMedium,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: null,
                  expands: true,
                  validator: (value) => null,
                  enabled: !_isSaving,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton.icon(
                  icon: Icon(isEditing ? Icons.save : Icons.add),
                  label: Text(isEditing ? 'Save Changes' : 'Create Note'),
                  onPressed: _isSaving ? null : _saveNote,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
