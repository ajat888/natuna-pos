import 'package:flutter/material.dart';

class TablePickerDialog extends StatelessWidget {
  final List<int> activeTables;

  const TablePickerDialog({super.key, required this.activeTables});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pilih Meja', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 500, // Lebar dialog (cocok untuk web/tablet)
        height: 400,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5, // 5 kolom
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.2,
          ),
          itemCount: 60,
          itemBuilder: (context, index) {
            final tableNumber = index + 1;
            final isActive = activeTables.contains(tableNumber);

            return InkWell(
              onTap: isActive 
                  ? null // Disabled jika meja terisi
                  : () {
                      Navigator.pop(context, tableNumber); // Kembalikan nomor meja
                    },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: isActive ? Colors.grey[300] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive ? Colors.grey[400]! : Colors.blue[300]!,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Meja\n$tableNumber',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.grey[600] : Colors.blue[800],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
      ],
    );
  }
}