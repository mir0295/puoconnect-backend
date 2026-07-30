import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import '../widgets/puo_event_bottom_sheet.dart';
import 'login_screen.dart'; 
import '../widgets/event_card.dart';
import 'navigation_screen.dart'; // 🚀 TAMBAHAN: Import skrin navigasi

class DashboardScreen extends StatefulWidget {
  final String userDept; 
  const DashboardScreen({super.key, required this.userDept});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late String selectedDept;
  String searchQuery = "";
  bool _isPopupShown = false; 
  final List<String> depts = ["Semua", "JKE", "JKA", "JTMK", "JP"];

  final Map<String, Color> deptColors = {
    "JKE": Colors.orange.shade700, "JKA": Colors.teal.shade700,
    "JTMK": Colors.indigo.shade700, "JP": Colors.purple.shade700,
    "Semua": Colors.grey.shade700,
  };

  @override
  void initState() {
    super.initState();
    selectedDept = widget.userDept;
    _checkGeofence();
  }

  void _logout() async {
    setState(() {
      _isPopupShown = false; // 🔄 Reset status popup geofence
    });
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _checkGeofence() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        
  Position position = await Geolocator.getCurrentPosition(
  desiredAccuracy: LocationAccuracy.high, // 👈 Guna desiredAccuracy
);

        // 📍 Koordinat Pusat PUO (4.5880, 101.1200)
        double distance = Geolocator.distanceBetween(
          position.latitude, 
          position.longitude, 
          4.5880, 
          101.1200,
        );
        
        // Jika jarak <= 500m dari PUO, paparkan Bottom Sheet
        if (distance <= 500 && mounted && !_isPopupShown) {
          _isPopupShown = true; 
          _showEventBottomSheet();
        }
      }
    } catch (e) {
      debugPrint("Geofence error: $e");
    }
  }

  /// 🎯 PAPARKAN BOTTOM SHEET VISUAL
  void _showEventBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FractionallySizedBox(
        heightFactor: 0.65,
        child: PUOEventBottomSheet(),
      ),
    );
  }

  Widget _buildEventList(bool isUpcomingTab) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('events').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Ralat: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        DateTime now = DateTime.now();
        DateTime today = DateTime(now.year, now.month, now.day);

        var docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          
          List<String> parts = (data['startDate'] ?? "").split('/');
          if (parts.length != 3) return false;
          DateTime eventDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));

          bool dateCondition = isUpcomingTab 
          ? eventDate.isAfter(today) 
          : eventDate.isAtSameMomentAs(today);

          return (selectedDept == "Semua" || data['publishDept'] == selectedDept) &&
                 dateCondition &&
                 (data['title'] ?? "").toString().toLowerCase().contains(searchQuery.toLowerCase()) &&
                 (data['isActive'] == true); 
        }).toList();

        if (docs.isEmpty) return const Center(child: Text("Tiada aktiviti dijumpai"));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            String dateStr = data['startDate'] ?? 'Tiada Tarikh';
            
            bool isNewDate = i == 0 || dateStr != (docs[i-1].data() as Map<String, dynamic>)['startDate'];
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isNewDate) 
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text(
                      dateStr, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo),
                    ),
                  ),
                // 🚀 TAMBAHAN: GestureDetector untuk pindah ke NavigationScreen bila kad ditekan
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NavigationScreen(
                          eventName: data['title'] ?? 'Acara PUO',
                          locationName: data['locationName'] ?? 'Blok JTMK, Makmal 3',
                          targetLat: (data['latitude'] != null) 
                              ? (data['latitude'] as num).toDouble() 
                              : 4.5895, // Default latitude
                          targetLng: (data['longitude'] != null) 
                              ? (data['longitude'] as num).toDouble() 
                              : 101.1215, // Default longitude
                          floorPlanAsset: data['floorPlanAsset'] ?? 'assets/maps/jtmk_level1.png',
                        ),
                      ),
                    );
                  },
                  child: EventCard(eventData: data, deptColors: deptColors),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Dashboard Pelajar"),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _logout)],
          bottom: const TabBar(
            labelColor: Colors.white, 
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [Tab(text: "Sedang Berlangsung"), Tab(text: "Akan Datang")],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: const InputDecoration(labelText: "Cari...", prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
                onChanged: (val) => setState(() => searchQuery = val),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: depts.map((d) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(label: Text(d), selected: selectedDept == d, onSelected: (_) => setState(() => selectedDept = d)),
                )).toList(),
              ),
            ),
            Expanded(
              child: TabBarView(children: [
                _buildEventList(false), 
                _buildEventList(true)   
              ]),
            ),
          ],
        ),
      ),
    );
  }
}