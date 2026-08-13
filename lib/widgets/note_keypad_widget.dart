import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';

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
        crossAxisCount: 4, // 4 cols x 3 rows
        childAspectRatio: 2.1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        final isAccidental = note.id.contains('#');
        final isButtonActive = isEnabled && (!isAccidental || allowAccidentals);

        final activeBg = isAccidental ? const Color(0xFF1F1C32) : const Color(0xFF2B263C);
        final activeBorder = isAccidental
            ? AppColors.purple.withValues(alpha: 0.5)
            : AppColors.gold.withValues(alpha: 0.5);
        final activeTextColor = isAccidental
            ? const Color(0xFFC4B5FD) // soft violet
            : const Color(0xFFFDE68A); // soft gold

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isButtonActive
                ? () {
                    HapticFeedback.selectionClick();
                    onNoteSelected(note);
                  }
                : null,
            borderRadius: BorderRadius.circular(12),
            splashColor: (isAccidental ? AppColors.purple : AppColors.gold).withValues(alpha: 0.2),
            highlightColor: (isAccidental ? AppColors.purple : AppColors.gold).withValues(alpha: 0.1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: isButtonActive ? activeBg : Colors.grey.shade900.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isButtonActive ? activeBorder : Colors.white10,
                  width: 1.2,
                ),
                boxShadow: isButtonActive
                    ? [
                        BoxShadow(
                          color: (isAccidental ? AppColors.purple : AppColors.gold).withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: Text(
                      note.displayName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isAccidental ? 13 : 17,
                        fontWeight: FontWeight.w800,
                        color: isButtonActive ? activeTextColor : Colors.white24,
                        letterSpacing: 0.3,
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
