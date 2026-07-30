import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // 👈 Mengira jarak GPS
import 'package:url_launcher/url_launcher.dart';

class NavigationScreen extends StatefulWidget {
  final String eventName;
  final String locationName;
  final double targetLat;
  final double targetLng;
  final String floorPlanAsset;

  const NavigationScreen({
    super.key,
    required this.eventName,
    required this.locationName,
    required this.targetLat,
    required this.targetLng,
    this.floorPlanAsset = 'assets/maps/jtmk_level1.png',
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  bool _isArrived = false; // Status sama ada user dah sampai lokasi atau belum
  double _distanceInMeters = 0; // Nilai jarak dalam meter dari GPS

  @override
  void initState() {
    super.initState();
    _checkArrivalStatus(); // Semak jarak sebaik sahaja skrin dibuka
  }

  // 📍 Logik Semak Jarak GPS (Real-Time Distance Check)
  Future<void> _checkArrivalStatus() async {
    try {
      // Ambil lokasi semasa peranti (Sintaks baharu Geolocator)
Position userPosition = await Geolocator.getCurrentPosition(
  desiredAccuracy: LocationAccuracy.high, // 👈 Guna desiredAccuracy
);

      // Kira jarak antara User -> Target Bangunan (dalam unit Meter)
      double distance = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        widget.targetLat,
        widget.targetLng,
      );

      setState(() {
        _distanceInMeters = distance;
        // Jika jarak KURANG daripada 50 METER, anggap pengguna DAH SAMPAI!
        _isArrived = distance <= 50;
      });
    } catch (e) {
      debugPrint("Gagal mengambil lokasi GPS: $e");
    }
  }

  // 🚗 Langkah 4: Buka Google Maps
  Future<void> _openGoogleMaps(double lat, double lng) async {
    final Uri googleMapsUrl =
        Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    }
  }

  // 🤖 Langkah 3: AI Parking Engine
  Map<String, dynamic> _getAIParkingRecommendation() {
    final now = DateTime.now();
    bool isPeakHour = (now.hour >= 8 && now.hour <= 11) && (now.weekday <= 5);

    if (isPeakHour) {
      return {
        'name': 'Parkir Pusat Islam (Alternatif AI)',
        'lat': 4.5890,
        'lng': 101.1210,
        'walkTime': '2 minit berjalan kaki ke ${widget.locationName}',
        'reason':
            'AI mengesan waktu puncak (8 AM - 11:30 AM). Parkir Utama berisiko penuh. Parkir Pusat Islam mempunyai ketersediaan lebih tinggi.',
      };
    } else {
      return {
        'name': 'Parkir Utama JTMK',
        'lat': widget.targetLat,
        'lng': widget.targetLng,
        'walkTime': '1 minit berjalan kaki ke ${widget.locationName}',
        'reason':
            'Kawasan luar waktu puncak. Parkir Utama mempunyai petak yang mencukupi.',
      };
    }
  }

  // 🤖 Popup Dialog AI
  void _showAIParkingDialog(BuildContext context) {
    final parkingData = _getAIParkingRecommendation();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.psychology, color: Colors.indigo, size: 28),
            SizedBox(width: 8),
            Text("Cadangan Parkir AI"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "📍 ${parkingData['name']}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text("🚶‍♂️ ${parkingData['walkTime']}", style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "💡 ${parkingData['reason']}",
                style: const TextStyle(fontSize: 12, color: Colors.indigo),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.navigation),
            label: const Text("Terima & Pandu"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _openGoogleMaps(parkingData['lat'], parkingData['lng']);
            },
          ),
        ],
      ),
    );
  }

  // 🚶‍♂️ BottomSheet Indoor Map
  void _showIndoorMapBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Pelan Aras: ${widget.locationName}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const Divider(),
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.amber.shade50,
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Laluan: Masuk Lobi Utama -> Naik Tangga -> Belok Kanan.",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.asset(
                  widget.floorPlanAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Text("Pelan aras belum disediakan.")),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Kawasan Peta
          Container(
            color: Colors.grey[200],
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'Peta & Visual Laluan Kampus',
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // 2. Kad Atas
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 450,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start, // 👈 CrossAxisAlignment dibetulkan
                              children: [
                                Text(
                                  widget.eventName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Destinasi: ${widget.locationName}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. Kad Bawah Dinamik (Berubah mengikut status lokasi)
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: 450,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _isArrived ? Icons.where_to_vote : Icons.directions_walk,
                                    color: _isArrived ? Colors.green : Colors.blue,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isArrived
                                        ? 'Anda Telah Sampai!'
                                        : (_distanceInMeters > 0
                                            ? '${_distanceInMeters.toStringAsFixed(0)}m'
                                            : '4 minit (300m)'),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                              Chip(
                                label: Text(_isArrived ? 'Destinasi' : 'Lokasi Event'),
                                backgroundColor: _isArrived ? Colors.green.shade50 : Colors.blue.shade50,
                                labelStyle: TextStyle(
                                  color: _isArrived ? Colors.green.shade800 : Colors.blue.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 🚗 BUTANG MULA NAVIGASI (Sentiasa Ada)
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: () => _showAIParkingDialog(context),
                              icon: const Icon(Icons.navigation_rounded),
                              label: const Text(
                                'Mula Navigasi',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),

                          // 🚶‍♂️ BUTANG INDOOR NAV (HANYA MUNCUL BILA _isArrived == true)
                          if (_isArrived) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 45,
                              child: OutlinedButton.icon(
                                onPressed: () => _showIndoorMapBottomSheet(context),
                                icon: const Icon(Icons.map, color: Colors.indigo),
                                label: const Text(
                                  'Lihat Pelan Aras Bilik (Indoor Nav)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.indigo,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.indigo, width: 2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],

                          // 🧪 (UNTUK TESTING MAKSUD DOKUMEN/SIMULASI FYP)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isArrived = !_isArrived; // Tukar status untuk test
                              });
                            },
                            child: Text(
                              _isArrived ? "[Simulasi: Tukar Ke Mod Belum Sampai]" : "[Simulasi: Mod Dah Sampai]",
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}