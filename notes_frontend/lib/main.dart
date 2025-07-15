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
class NotesApp extends StatefulWidget {
  const NotesApp({super.key});

  @override
  State<NotesApp> createState() => _NotesAppState();
}

class _NotesAppState extends State<NotesApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme([bool? dark]) {
    setState(() {
      if (dark == null) {
        _themeMode =
            _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
      } else if (dark) {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.light;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF1976D2);
    final Color accentColor = const Color(0xFFFFC107);
    final Color secondaryColor = const Color(0xFF424242);

    // Light theme
    final ThemeData lightTheme = ThemeData(
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
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
      dialogBackgroundColor: Colors.white,
      dividerColor: Colors.grey[300],
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primaryColor,
        contentTextStyle: TextStyle(color: Colors.white),
        actionTextColor: accentColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );

    // Dark theme
    final ThemeData darkTheme = ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: const Color(0xFF22252A),
        background: const Color(0xFF181A20),
        onPrimary: Colors.white,
        onSecondary: Colors.black,
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
        selectedItemColor: accentColor,
        backgroundColor: const Color(0xFF181A20),
        unselectedItemColor: Colors.grey[400],
        elevation: 8,
      ),
      textTheme: const TextTheme(
        displayMedium: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 18,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          color: Color(0xFFECECEC),
        ),
      ),
      scaffoldBackgroundColor: const Color(0xFF181A20),
      dialogBackgroundColor: const Color(0xFF1F2128),
      dividerColor: Colors.grey[700],
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primaryColor,
        contentTextStyle: const TextStyle(color: Colors.white),
        actionTextColor: accentColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF22252A),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[800]!),
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );

    return MaterialApp(
      title: 'Notes',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      home: NotesHomePage(
        themeMode: _themeMode,
        onThemeChanged: (mode) => setState(() => _themeMode = mode),
        toggleTheme: _toggleTheme,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

// PUBLIC_INTERFACE
class NotesHomePage extends StatefulWidget {
  final ThemeMode themeMode;
  final void Function(ThemeMode) onThemeChanged;
  final void Function([bool? dark]) toggleTheme;

  const NotesHomePage({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
    required this.toggleTheme,
  });

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
    Center(child: Text('All Notes')), // To be replaced with dynamic content
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
        builder: (ctx) => NoteDetailPage(
          note: note,
          onEdit: _onEditNote,
          onDelete: _onDeleteNote,
        ),
      ),
    );
    setState(() {
      _notesFuture = _getNotes();
    });
  }

  Widget _notesListBuilder(BuildContext context, AsyncSnapshot<List<Note>> snapshot) {
    final theme = Theme.of(context);
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    }
    final notes = snapshot.data ?? [];
    final isDark = theme.brightness == Brightness.dark;
    if (notes.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty
              ? 'No notes yet.\nTap + to add a note.'
              : 'No notes found for "${_searchQuery}"',
          style: theme.textTheme.bodyMedium!.copyWith(
            color: isDark ? Colors.grey[400] : Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      itemCount: notes.length,
      separatorBuilder: (ctx, i) => Divider(
        height: 1,
        color: isDark ? Colors.grey[800] : Colors.grey[300],
      ),
      itemBuilder: (ctx, idx) {
        final note = notes[idx];
        return Dismissible(
          key: Key(note.id.toString()),
          background: Container(
            color: isDark ? Colors.red.shade900 : Colors.red.shade100,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 24),
            child: Icon(Icons.delete, color: isDark ? Colors.red[200] : Colors.red),
          ),
          direction: DismissDirection.startToEnd,
          onDismissed: (_) => _onDeleteNote(note),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            title: Text(
              note.title,
              style: theme.textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: note.content.isNotEmpty
                ? Text(
                    note.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[800]),
                  )
                : null,
            onTap: () => _onNoteTap(note),
            trailing: IconButton(
              icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: _AppBarSearchField(
          controller: _searchController,
          hintText: 'Search notes...',
          isDark: isDark,
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.clear, color: isDark ? Colors.white70 : Colors.grey[700]),
            onPressed: _searchController.text.isEmpty
                ? null
                : () {
                    _searchController.clear();
                  },
            tooltip: "Clear",
          ),
          _ThemeToggleSwitch(
            themeMode: widget.themeMode,
            onChanged: (mode) => widget.onThemeChanged(mode),
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

// Theme toggle switch widget for app bar
class _ThemeToggleSwitch extends StatelessWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeToggleSwitch({
    Key? key,
    required this.themeMode,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Three-way switch: light, dark, system
    return PopupMenuButton<ThemeMode>(
      icon: Icon(
          themeMode == ThemeMode.dark
              ? Icons.dark_mode
              : themeMode == ThemeMode.light
                  ? Icons.light_mode
                  : Icons.brightness_auto,
          color: Theme.of(context).appBarTheme.foregroundColor ?? Colors.white),
      tooltip: 'Theme',
      onSelected: onChanged,
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: ThemeMode.light,
          child: Row(
            children: [
              Icon(Icons.light_mode, color: Colors.amberAccent),
              const SizedBox(width: 12),
              const Text('Light'),
              if (themeMode == ThemeMode.light)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.check, color: Colors.green, size: 16),
                ),
            ],
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.dark,
          child: Row(
            children: [
              Icon(Icons.dark_mode, color: Colors.deepPurpleAccent),
              const SizedBox(width: 12),
              const Text('Dark'),
              if (themeMode == ThemeMode.dark)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.check, color: Colors.green, size: 16),
                ),
            ],
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.system,
          child: Row(
            children: [
              Icon(Icons.brightness_auto, color: Colors.blueGrey),
              const SizedBox(width: 12),
              const Text('System'),
              if (themeMode == ThemeMode.system)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.check, color: Colors.green, size: 16),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AppBarSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isDark;

  const _AppBarSearchField({
    required this.controller,
    required this.hintText,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = isDark ? const Color(0xFF23262B) : Colors.white;
    return Container(
      height: 38,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: baseColor,
        border: Border.all(color: Colors.transparent),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey[300] : Colors.grey),
          hintText: hintText,
          border: InputBorder.none,
        ),
        style: TextStyle(fontSize: 16, color: isDark ? Colors.white : Colors.black),
        autocorrect: false,
      ),
    );
  }
}
