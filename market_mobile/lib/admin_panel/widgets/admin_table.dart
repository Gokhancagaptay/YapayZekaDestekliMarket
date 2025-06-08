import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminTable<T> extends StatelessWidget {
  final List<String> columns;
  final List<T> data;
  final List<DataCell> Function(T, int) cellBuilder;
  final Function(T)? onRowTap;
  final bool isLoading;
  final String emptyText;

  const AdminTable({
    Key? key,
    required this.columns,
    required this.data,
    required this.cellBuilder,
    this.onRowTap,
    this.isLoading = false,
    this.emptyText = 'Veri bulunamadı',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.deepOrange),
      );
    }

    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inbox,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              emptyText,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(0),
      color: const Color(0xFF333333),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(const Color(0xFF424242)),
              dataRowColor: MaterialStateProperty.all(const Color(0xFF333333)),
              headingTextStyle: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              dataTextStyle: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 13,
              ),
              columnSpacing: 24,
              horizontalMargin: 16,
              showCheckboxColumn: false,
              columns: columns
                  .map(
                    (column) => DataColumn(
                      label: Text(column),
                    ),
                  )
                  .toList(),
              rows: data
                  .asMap()
                  .map(
                    (i, item) => MapEntry(
                      i,
                      DataRow(
                        onSelectChanged: onRowTap != null ? (_) => onRowTap!(item) : null,
                        cells: cellBuilder(item, i),
                        color: i % 2 == 0
                            ? MaterialStateProperty.all(const Color(0xFF333333))
                            : MaterialStateProperty.all(const Color(0xFF3A3A3A)),
                      ),
                    ),
                  )
                  .values
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class ActionCell extends StatelessWidget {
  final List<ActionItem> actions;

  const ActionCell({
    Key? key,
    required this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: actions.map((action) {
        return IconButton(
          icon: Icon(action.icon, color: action.color, size: 20),
          onPressed: action.onPressed,
          tooltip: action.tooltip,
          splashRadius: 20,
        );
      }).toList(),
    );
  }
}

class ActionItem {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final String tooltip;

  ActionItem({
    required this.icon,
    required this.onPressed,
    this.color = Colors.white,
    this.tooltip = '',
  });
} 