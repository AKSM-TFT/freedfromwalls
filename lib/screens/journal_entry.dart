import 'package:flutter/material.dart';
import 'package:freedfromwalls/models/additional_note.dart';
import 'package:freedfromwalls/models/emotion.dart';
import 'package:intl/intl.dart';
import '../assets/widgets/customThemes.dart';
import '../assets/widgets/last_edited_info.dart';
import '../controllers/daily_entry_controller.dart';
import '../models/daily_entry.dart';

class JournalEntryScreen extends StatefulWidget {
  final Function(String, DateTime, DateTime) onJournalEntryChanged;
  final String initialEntry;
  final DateTime Function() getCurrentTime;
  final DateTime? initialCreationDate;
  final DateTime? initialEditedDate;

  const JournalEntryScreen({
    super.key,
    required this.onJournalEntryChanged,
    this.initialEntry = "",
    required this.getCurrentTime,
    this.initialCreationDate,
    this.initialEditedDate,
  });

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  late DateTime editedDate;
  late final DateTime creationDate;
  late final TextEditingController _journalEntryController;
  List<AdditionalNoteModel> notes = [];
  final DailyEntryController controller = DailyEntryController();
  List<DailyEntryModel> entries = [];

  @override
  void initState() {
    super.initState();
    creationDate = widget.initialCreationDate ?? widget.getCurrentTime();
    editedDate = widget.initialEditedDate ?? creationDate;
    _journalEntryController = TextEditingController(text: widget.initialEntry);
    _journalEntryController.addListener(_onJournalEntryChanged);
    _loadEntries();
    print(entries);
  }

  Future<void> _loadEntries() async {
    entries = await controller.fetchEntries();
  }

  void _onJournalEntryChanged() {
    DailyEntryModel dailyEntry = DailyEntryModel(
      date: DateTime.now(),
      journalEntry: _journalEntryController.text,
      additionalNotes: notes,
    );

    editedDate = widget.getCurrentTime();
    widget.onJournalEntryChanged(
        _journalEntryController.text, creationDate, editedDate);
  }

  Future<void> _addEntry() async {
    DailyEntryModel dailyEntry = DailyEntryModel(
      date: DateTime.now(),
      emotion: EmotionModel(name: "happy", title: "YAY", color: "0xFFF8E9BB"),
      journalEntry: _journalEntryController.text,
      additionalNotes: notes,
    );
    await controller.addEntry(dailyEntry);
  }

  @override
  void dispose() {
    _journalEntryController.removeListener(_onJournalEntryChanged);
    _journalEntryController.dispose();
    super.dispose();
  }

  void addNote(String note) {
    setState(() {
      notes.add(AdditionalNoteModel(dailyEntryId: entries.length, note: note));
    });
  }

  void removeNote(int index) {
    setState(() {
      notes.removeAt(index);
    });
  }

  void editNote(int index, String newNote) {
    setState(() {
      notes[index].note = newNote;
      editedDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "FreedFrom Walls",
          style:
              TextStyle(fontSize: AppThemes.getResponsiveFontSize(context, 18)),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Journal Entry",
              style: TextStyle(
                  fontSize: AppThemes.getResponsiveFontSize(context, 20),
                  fontWeight: FontWeight.bold,
                  fontFamily: "Jua"),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                LastEditedInfo(
                    creationDate: creationDate, editedDate: editedDate),
                Container(
                  height: 45,
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    DateFormat("yMd").format(creationDate),
                    style: TextStyle(
                        fontSize: AppThemes.getResponsiveFontSize(context, 12),
                        color: Theme.of(context).textTheme.displaySmall?.color,
                        fontFamily: "RethinkSans",
                        fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
            const Divider(
              color: Colors.grey,
            ),
            //  A SizedBox was needed to limit the height of the TextField
            SizedBox(
              height: 250,
              child: TextField(
                controller: _journalEntryController,
                textInputAction: TextInputAction.send,
                onSubmitted: (String str) {
                  _addEntry();
                  FocusManager.instance.primaryFocus?.unfocus();
                  Navigator.pop(context);
                },
                maxLines: 100,
                decoration: InputDecoration(
                  hintText: "Write something here",
                  hintStyle: TextStyle(
                    fontSize: AppThemes.getResponsiveFontSize(context, 12),
                    fontStyle: FontStyle.italic,
                  ),
                  border: InputBorder.none,
                ),
                style: TextStyle(
                    fontSize: AppThemes.getResponsiveFontSize(context, 14),
                    fontStyle: FontStyle.italic,
                    fontFamily: "RethinkSans"),
              ),
            ),
            const Divider(color: Colors.grey),
            const SizedBox(height: 4),
            Container(
              height: 30,
              width: 85,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(5)),
              child: const Text(
                "NOTES",
                style: TextStyle(
                    fontFamily: "RethinkSans", fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            const Divider(color: Colors.grey),
            Expanded(
              child: ListView.builder(
                itemCount: notes.length + 1,
                itemBuilder: (context, index) {
                  if (index == notes.length) {
                    return NoteItem(
                      onAdd: addNote,
                    );
                  } else {
                    return NoteItem(
                      note: notes[index].note,
                      onRemove: () => removeNote(index),
                      onEdit: (String newNote) => editNote(index, newNote),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NoteItem extends StatelessWidget {
  final String? note;
  final Function(String)? onAdd;
  final VoidCallback? onRemove;
  final Function(String)? onEdit;

  const NoteItem(
      {super.key, this.note, this.onAdd, this.onRemove, this.onEdit});

  void showNoteBottomSheet(BuildContext context, {String? initialNote}) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => AddNoteBottomSheet(
        initialNote: initialNote,
        onTextSubmit: (String str) {
          if (initialNote == null && onAdd != null) {
            onAdd!(str);
          } else if (onEdit != null) {
            onEdit!(str);
          }
          FocusManager.instance.primaryFocus?.unfocus();
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
              child: InkWell(
                onTap: note == null
                    ? () => showNoteBottomSheet(context)
                    : onRemove,
                child: Icon(
                  note == null ? Icons.add : Icons.remove,
                  color: note == null
                      ? const Color(0xffB3B3B3)
                      : const Color(0xff000000),
                  size: 18,
                ),
              ),
            ),
            Expanded(
              child: Text(
                note ?? "Additional Notes...",
                style: TextStyle(
                    color: note == null
                        ? const Color(0xffB3B3B3)
                        : const Color(0xff000000),
                    fontSize: 12,
                    fontFamily: "RethinkSans"),
              ),
            ),
            if (note != null)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: InkWell(
                  child: const Icon(Icons.edit, size: 18),
                  onTap: () => showNoteBottomSheet(context, initialNote: note),
                ),
              ),
          ],
        ),
        const Divider(
          color: Colors.grey,
        ),
      ],
    );
  }
}

class AddNoteBottomSheet extends StatefulWidget {
  final Function(String) onTextSubmit;
  final String? initialNote;

  const AddNoteBottomSheet(
      {super.key, required this.onTextSubmit, this.initialNote});

  @override
  State<AddNoteBottomSheet> createState() => _AddNoteBottomSheetState();
}

class _AddNoteBottomSheetState extends State<AddNoteBottomSheet> {
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 350,
      child: TextField(
        controller: _noteController,
        textInputAction: TextInputAction.send,
        onSubmitted: (String str) {
          widget.onTextSubmit(_noteController.text);
        },
        autofocus: true,
        decoration: const InputDecoration(
          hintText: "Notes",
          hintStyle: TextStyle(
              color: Color(0xff938F8F),
              fontFamily: "RethinkSans",
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
