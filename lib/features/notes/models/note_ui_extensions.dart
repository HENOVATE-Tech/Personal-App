import 'package:flutter/material.dart';
import '../../../core/database/schema_models.dart';

extension NoteCategoryUiExtension on NoteCategory {
  IconData get icon {
    switch (this) {
      case NoteCategory.spiritual:
        return Icons.auto_stories;
      case NoteCategory.bibleStudy:
        return Icons.menu_book;
      case NoteCategory.visionStrategy:
        return Icons.rocket_launch;
      case NoteCategory.professional:
        return Icons.business_center;
      case NoteCategory.relationships:
        return Icons.people_outline;
      case NoteCategory.personal:
        return Icons.lightbulb_outline;
    }
  }
}
