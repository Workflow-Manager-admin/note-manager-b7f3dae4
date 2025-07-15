import 'package:flutter/material.dart';
import 'package:notes_frontend/note_model.dart';
import 'package:notes_frontend/notes_database.dart';
import 'package:notes_frontend/note_edit_page.dart';
import 'package:notes_frontend/note_detail_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NotesApp());
}

// PUBLIC_INTERFACE
class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF1976D2);
    final Color accentColor = const Color(0xFFFFC107);

    final ThemeData theme = ThemeData(
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: const Color(0xFF424242),
        surface: Colors.white,
        background: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.black87,
        elevation: 4,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: primaryColor,
        backgroundColor: Colors.white,
        unselectedItemColor: Colors.grey[500],
        elevation: 8,
      ),
      textTheme: const TextTheme(
        displayMedium: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 18,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
        ),
      ),
      scaffoldBackgroundColor: Colors.white,
    );

    return MaterialApp(
      title: 'Notes',
      theme: theme,
      home: const NotesHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class NotesHomePage extends StatefulWidget {
  const NotesHomePage({super.key});

  @override
  State<NotesHomePage> createState() => _NotesHomePageState();
}

class _NotesHomePageState extends State<NotesHomePage> {
  late Future<List<Note>> _notesFuture;
  int _selectedIndex = 0;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  // Bottom navigation bar implementation is minimal for extensibility.
  final List<Widget> _extraNavPages = [
    Center(child: Text('All Notes')), // Replaced with dynamic content
    Center(child: Text('Favorites (Coming soon)')),
  ];

  @override
  void initState() {
    super.initState();
    NotesDatabase.instance.initDb();
    _notesFuture = _getNotes();
    _searchController.addListener(_onSearchChanged);
  }

  Future<List<Note>> _getNotes() async {
    return await NotesDatabase.instance.getNotes(query: _searchQuery.trim());
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _notesFuture = _getNotes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    NotesDatabase.instance.close();
    super.dispose();
  }

  void _onDeleteNote(Note note) async {
    await NotesDatabase.instance.deleteNote(note.id!);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note deleted')),
    );
    setState(() {
      _notesFuture = _getNotes();
    });
  }

  void _onEditNote(Note note) async {
    final updated = await Navigator.of(context).push<Note?>(
      MaterialPageRoute(builder: (ctx) => NoteEditPage(note: note)),
    );
    if (updated != null) {
      await NotesDatabase.instance.updateNote(updated);
      setState(() {
        _notesFuture = _getNotes();
      });
    }
  }

  void _onAddNote() async {
    final newNote = await Navigator.of(context).push<Note?>(
      MaterialPageRoute(builder: (ctx) => const NoteEditPage()),
    );
    if (newNote != null) {
      await NotesDatabase.instance.insertNote(newNote);
      setState(() {
        _notesFuture = _getNotes();
      });
    }
  }

  void _onNoteTap(Note note) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) =>
            NoteDetailPage(note: note, onEdit: _onEditNote, onDelete: _onDeleteNote),
      ),
    );
    setState(() {
      _notesFuture = _getNotes();
    });
  }

  Widget _notesListBuilder(BuildContext context, AsyncSnapshot<List<Note>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    }
    final notes = snapshot.data ?? [];
    if (notes.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty
              ? 'No notes yet.\nTap + to add a note.'
              : 'No notes found for "${_searchQuery}"',
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      itemCount: notes.length,
      separatorBuilder: (ctx, i) => const Divider(height: 1),
      itemBuilder: (ctx, idx) {
        final note = notes[idx];
        return Dismissible(
          key: Key(note.id.toString()),
          background: Container(
            color: Colors.red.shade100,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 24),
            child: const Icon(Icons.delete, color: Colors.red),
          ),
          direction: DismissDirection.startToEnd,
          onDismissed: (_) => _onDeleteNote(note),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            title: Text(
              note.title,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: note.content.isNotEmpty
                ? Text(note.content, maxLines: 1, overflow: TextOverflow.ellipsis)
                : null,
            onTap: () => _onNoteTap(note),
            trailing: IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF1976D2)),
              tooltip: 'Edit',
              onPressed: () => _onEditNote(note),
            ),
          ),
        );
      },
    );
  }

  Widget _mainContentWidget() {
    // For extensibility (e.g. tabs for favorite, archived), navigation is present.
    // Only All Notes implemented.
    if (_selectedIndex == 0) {
      return FutureBuilder<List<Note>>(
        future: _notesFuture,
        builder: _notesListBuilder,
      );
    } else {
      return _extraNavPages[_selectedIndex];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _AppBarSearchField(
          controller: _searchController,
          hintText: 'Search notes...',
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _searchController.text.isEmpty
                ? null
                : () {
                    _searchController.clear();
                  },
            tooltip: "Clear",
          ),
        ],
      ),
      body: _mainContentWidget(),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddNote,
        tooltip: 'New Note',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.notes), label: 'Notes'),
          BottomNavigationBarItem(icon: Icon(Icons.star_border), label: 'Favorites'),
        ],
        onTap: (idx) {
          setState(() {
            _selectedIndex = idx;
          });
        },
      ),
    );
  }
}

class _AppBarSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const _AppBarSearchField({
    required this.controller,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.transparent),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          hintText: hintText,
          border: InputBorder.none,
        ),
        style: const TextStyle(fontSize: 16),
        autocorrect: false,
      ),
    );
  }
}
