import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GroupTagChip extends StatelessWidget {
  final String label;
  final VoidCallback onDelete;

  const GroupTagChip({
    super.key,
    required this.label,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Format label to uppercase code style matching the reference image (e.g. GDDTM, GDDTM_ADMINS)
    final formattedLabel = label
        .trim()
        .replaceAll(' ', '_')
        .toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xffFFFBEB), // Light cream background
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xffFDE68A).withOpacity(0.6),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formattedLabel,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: const Color(0xffC2410C), // Warm brown/amber text color
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(
                Icons.delete_outline_rounded,
                size: 15,
                color: Color(0xffC2410C), // Matching brown/amber icon color
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GroupCategorySection extends StatelessWidget {
  final String categoryTitle;
  final List<String> groups;
  final Function(String group) onDeleteGroup;

  const GroupCategorySection({
    super.key,
    required this.categoryTitle,
    required this.groups,
    required this.onDeleteGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          categoryTitle.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xff334155),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: groups.map((group) {
            return GroupTagChip(
              label: group,
              onDelete: () => onDeleteGroup(group),
            );
          }).toList(),
        ),
      ],
    );
  }
}
