import 'package:flutter/material.dart';
import '/screens/event_detail_screen.dart';

class EventCard extends StatelessWidget {
  final Map<String, dynamic> eventData;
  final Map<String, Color> deptColors;
  final bool isAdmin; 
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const EventCard({
    super.key, 
    required this.eventData, 
    required this.deptColors,
    this.isAdmin = false, 
    this.onEdit,
    this.onDelete,
  });

  // Fungsi pembantu untuk membina barisan info dengan ikon (warna teks lebih terang)
  Widget _infoRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.indigo.shade700),
        const SizedBox(width: 4),
        Text(
          text, 
          style: const TextStyle(
            fontSize: 12, 
            fontWeight: FontWeight.w600, 
            color: Colors.black87, 
          ),
        ),
      ],
    );
  }

  Widget _buildStatusLabel() {
    try {
      List<String> parts = (eventData['startDate'] ?? "").split('/');
      DateTime startDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);

      if (today.isBefore(startDate)) {
        return _statusChip("Akan Datang", Colors.blue);
      } else {
        return _statusChip("Sedang Berlangsung", Colors.green);
      }
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ambil data jabatan asal
    String rawDept = eventData['publishDept'] ?? eventData['department'] ?? 'UMUM';
    
    // Tukar facebook_config kepada UKK secara automatik
    String dept = (rawDept == 'facebook_config') ? 'UKK' : rawDept;
    
    Color deptColor = deptColors[dept] ?? Colors.indigo;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 3,
      color: Colors.white, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade300, width: 1), 
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(eventData: eventData))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Container(
                height: 140,
                width: double.infinity,
                color: Colors.grey.shade100,
                child: (eventData['imageUrl'] != null && eventData['imageUrl'].toString().isNotEmpty)
                    ? Image.network(
                        eventData['imageUrl'], 
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey));
                        },
                      )
                    : Center(child: Icon(Icons.image_outlined, size: 45, color: Colors.grey.shade400)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusLabel(),
                        const SizedBox(height: 8),
                        Text(
                          eventData['title'] ?? 'Tiada Nama', 
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 16, 
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            _infoRow(Icons.calendar_today, "${eventData['startDate']}"),
                            _infoRow(Icons.access_time, "${eventData['startTime'] ?? '-'} - ${eventData['endTime'] ?? '-'}"),
                            _infoRow(Icons.location_on, "${eventData['location'] ?? 'Tiada Lokasi'}"),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: deptColor.withValues(alpha: 0.15), 
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            dept, 
                            style: TextStyle(
                              color: deptColor, 
                              fontSize: 11, 
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isAdmin && (onEdit != null || onDelete != null))
                    PopupMenuButton(
                      onSelected: (value) {
                        if (value == 'edit') onEdit!();
                        if (value == 'delete') onDelete!();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text("Edit"))),
                        const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text("Padam", style: TextStyle(color: Colors.red)))),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}