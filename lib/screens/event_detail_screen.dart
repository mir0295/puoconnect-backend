import 'package:flutter/material.dart';
import 'navigation_screen.dart'; // Import skrin navigasi baru

class EventDetailScreen extends StatelessWidget {
  final Map<String, dynamic> eventData; // Terima data penuh aktiviti

  const EventDetailScreen({super.key, required this.eventData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Menggunakan extendBodyBehindAppBar supaya gambar memenuhi skrin
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // REKA BENTUK PREMIUM: Hero Image dengan Gradient Overlay
            Stack(
              children: [
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    image: (eventData['imageUrl'] != null && eventData['imageUrl'].toString().isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(eventData['imageUrl']),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: (eventData['imageUrl'] == null || eventData['imageUrl'].toString().isEmpty)
                      ? const Icon(Icons.event, size: 100, color: Colors.white)
                      : null,
                ),
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withValues(alpha: 0.1), Colors.black.withValues(alpha: 0.6)],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Text(
                    eventData['title'] ?? 'Butiran Aktiviti',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 10, color: Colors.black45)],
                    ),
                  ),
                ),
              ],
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Maklumat tambahan
                  _buildInfoRow(Icons.person, "PLC: ${eventData['plc'] ?? 'N/A'}"),
                  _buildInfoRow(Icons.calendar_today, "Tarikh: ${eventData['startDate'] ?? ''} hingga ${eventData['endDate'] ?? ''}"),
                  _buildInfoRow(Icons.access_time, "Masa: ${eventData['startTime'] ?? ''} - ${eventData['endTime'] ?? ''}"),
                  _buildInfoRow(Icons.location_on, "Lokasi: ${eventData['location'] ?? 'Tiada Lokasi'}"),
                  _buildInfoRow(Icons.apartment, "Jabatan: ${eventData['publishDept'] ?? 'N/A'}"),
                  
                  const SizedBox(height: 30),
                  
                  // BUTANG NAVIGASI KE EVENT (DIKEMASKINI)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NavigationScreen(
                              eventName: eventData['title'] ?? 'Butiran Aktiviti',
                              locationName: eventData['location'] ?? 'Tiada Lokasi',
                              targetLat: (eventData['latitude'] ?? 0.0).toDouble(),
                              targetLng: (eventData['longitude'] ?? 0.0).toDouble(),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.navigation, color: Colors.white),
                      label: const Text(
                        "Navigasi ke Event",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.indigo),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}