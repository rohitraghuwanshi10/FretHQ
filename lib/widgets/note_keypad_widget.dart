import 'package:flutter/material.dart';
import '../models/note.dart';

class NoteKeypadWidget extends StatelessWidget {
  final ValueChanged<Note> onNoteSelected;
  final bool isEnabled;
  final bool allowAccidentals;

  const NoteKeypadWidget({
    super.key,
    required this.onNoteSelected,
    this.isEnabled = true,
    this.allowAccidentals = true,
  });

  @override
  Widget build(BuildContext context) {
    final notes = Note.chromaticNotes;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 4 columns x 3 rows
        childAspectRatio: 2.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        final isAccidental = note.id.contains('#');
        final isButtonActive = isEnabled && (!isAccidental || allowAccidentals);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isButtonActive ? () => onNoteSelected(note) : null,
            borderRadius: BorderRadius.circular(10),
            splashColor: Colors.amberAccent.withValues(alpha: 0.3),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: isButtonActive
                    ? (isAccidental ? const Color(0xFF242230) : const Color(0xFF323042))
                    : Colors.grey.shade900.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isButtonActive
                      ? (isAccidental ? Colors.deepPurple.shade300.withValues(alpha: 0.5) : Colors.amber.withValues(alpha: 0.4))
                      : Colors.white10,
                  width: 1.2,
                ),
                boxShadow: isButtonActive
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      note.displayName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isAccidental ? 13 : 16,
                        fontWeight: FontWeight.bold,
                        color: isButtonActive
                            ? (isAccidental ? Colors.purpleAccent.shade100 : Colors.amber.shade200)
                            : Colors.white24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
