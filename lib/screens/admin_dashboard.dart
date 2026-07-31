import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http; // 👈 Ditambah untuk HTTP request
import 'dart:convert';                    // 👈 Ditambah untuk JSON decode
import 'login_screen.dart';
import 'add_event_page.dart'; 
import '../widgets/event_card.dart'; 
import '../widgets/custom_popup.dart'; 

class AdminDashboard extends StatefulWidget {
  final String department; 
  final String role; 
  const AdminDashboard({super.key, required this.department, required this.role});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    
    // 👈 Panggil fungsi auto-refresh token Facebook di latar belakang
    _triggerAutoRefreshToken();

    // Tab khusus untuk Admin Jabatan sahaja
    _tabs = [
      EventManagementTab(department: widget.department, role: widget.role),
      const HistoryTab(), 
      const AnalyticsTab(),
    ];
  }

  // Fungsi untuk berhubung dengan server Node.js bagi menyegarkan token Facebook
  Future<void> _triggerAutoRefreshToken() async {
    try {
      // NOTA: Guna 'http://10.0.2.2:3000/refresh-token' jika guna Android Emulator
      final url = Uri.parse('http://localhost:3000/refresh-token');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (kDebugMode) {
          print("Berjaya auto-refresh token: ${data['message']}");
        }
      } else {
        if (kDebugMode) {
          print("Gagal refresh token. Status code: ${response.statusCode}");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Ralat menyambung ke server backend: $e");
      }
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    const Color themeColor = Colors.indigo;

    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Panel - ${widget.department}"),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout)
        ],
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: themeColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.event), label: "Events"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "Sejarah"),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: "Analytics"),
        ],
      ),
    );
  }
}

class EventManagementTab extends StatefulWidget {
  final String department;
  final String role;
  const EventManagementTab({super.key, required this.department, required this.role});

  @override
  State<EventManagementTab> createState() => _EventManagementTabState();
}

class _EventManagementTabState extends State<EventManagementTab> {
  String searchQuery = "";
  final Map<String, Color> deptColors = const {
    "JKE": Colors.orange, "JKA": Colors.teal, "JTMK": Colors.indigo, "JP": Colors.purple
  };

  Widget _buildStatCard(String title, int count, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(children: [
          Text(title, style: const TextStyle(fontSize: 11)),
          Text("$count", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ]),
      ),
    );
  }

@override
  Widget build(BuildContext context) {
    // Tapis aktiviti mengikut jabatan admin tersebut menggunakan 'department'
    Query query = FirebaseFirestore.instance
        .collection('events')
        .where('department', isEqualTo: widget.department);

    return Scaffold(
      body: Column(
        children: [
          // 1. Kad Statistik (Aktif / Akan Datang / Tamat)
          StreamBuilder<QuerySnapshot>(
            stream: query.snapshots(),
            builder: (context, snapshot) {
              int aktif = 0;       // Hari ini
              int akanDatang = 0;  // Masa depan
              int tamat = 0;       // Masa lepas

              DateTime now = DateTime.now();
              DateTime today = DateTime(now.year, now.month, now.day);

              if (snapshot.hasData) {
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;

                  if (data['isActive'] == true) {
                    String dateStr = data['startDate'] ?? "";
                    try {
                      List<String> parts = dateStr.split('/');
                      if (parts.length == 3) {
                        DateTime eventDate = DateTime(
                          int.parse(parts[2]),
                          int.parse(parts[1]),
                          int.parse(parts[0]),
                        );

                        if (eventDate.isAtSameMomentAs(today)) {
                          aktif++;
                        } else if (eventDate.isAfter(today)) {
                          akanDatang++;
                        } else if (eventDate.isBefore(today)) {
                          tamat++;
                        }
                      }
                    } catch (e) {
                      /* Abaikan ralat format */
                    }
                  }
                }
              }

              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard("Aktif", aktif, Colors.green),
                    _buildStatCard("Akan Datang", akanDatang, Colors.blueAccent),
                    _buildStatCard("Tamat", tamat, Colors.grey.shade700),
                  ],
                ),
              );
            },
          ),

          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: "Cari event...", 
                prefixIcon: const Icon(Icons.search), 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))
              ),
              onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
            ),
          ),

          // 2. Senarai Event Jabatan
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                DateTime now = DateTime.now();
                DateTime today = DateTime(now.year, now.month, now.day);

                var docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  bool matchesSearch = data['title'].toString().toLowerCase().contains(searchQuery);

                  bool isUpcomingOrToday = false;
                  if (data['isActive'] == true) {
                    String dateStr = data['startDate'] ?? "";
                    try {
                      List<String> parts = dateStr.split('/');
                      if (parts.length == 3) {
                        DateTime eventDate = DateTime(
                          int.parse(parts[2]),
                          int.parse(parts[1]),
                          int.parse(parts[0]),
                        );
                        if (eventDate.isAtSameMomentAs(today) || eventDate.isAfter(today)) {
                          isUpcomingOrToday = true;
                        }
                      }
                    } catch (e) {
                      /* Abaikan ralat format */
                    }
                  }

                  return matchesSearch && isUpcomingOrToday;
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text("Tiada acara aktif atau akan datang."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    var doc = docs[i];
                    return EventCard(
                      eventData: doc.data() as Map<String, dynamic>,
                      deptColors: deptColors,
                      isAdmin: true, 
                      onEdit: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEventPage(doc: doc))),
                      onDelete: () => showDialog(
                        context: context, 
                        builder: (_) => CustomPopup(
                          title: "Padam?", 
                          content: "Padam event ini?", 
                          onConfirm: () async => await doc.reference.delete()
                        )
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddEventPage())),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  String searchQuery = "";

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      List<String> parts = dateStr.split('/');
      return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]), 23, 59, 59);
    } catch (e) {
      return null;
    }
  }

  final Map<String, Color> deptColors = const {
    "JKE": Colors.orange,
    "JKA": Colors.teal,
    "JTMK": Colors.indigo,
    "JP": Colors.purple
  };

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('events').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        DateTime now = DateTime.now();

        var filteredDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          
          String title = (data['title'] ?? '').toString().toLowerCase();
          String dept = (data['publishDept'] ?? '').toString().toLowerCase();
          bool matchesSearch = title.contains(searchQuery) || dept.contains(searchQuery);

          DateTime? endDate = _parseDate(data['endDate'] ?? data['startDate']);
          if (endDate == null) return false;

          bool isExpired = endDate.isBefore(now);
          int daysAgo = now.difference(endDate).inDays;
          bool isWithinPast7Days = daysAgo >= 0 && daysAgo <= 7;

          return isExpired && isWithinPast7Days && matchesSearch;
        }).toList();

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Arsip Sejarah (7 Hari)",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
                          ),
                          Text(
                            "${filteredDocs.length} aktiviti telah selesai",
                            style: TextStyle(fontSize: 12, color: Colors.indigo.shade300),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Fungsi Eksport Laporan PDF/Excel sedia ditambah!")),
                          );
                        },
                        icon: const Icon(Icons.picture_as_pdf, size: 16),
                        label: const Text("Laporan", style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Cari sejarah mengikut tajuk / jabatan...",
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: filteredDocs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_toggle_off, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            "Tiada sejarah aktiviti dijumpai",
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, i) {
                        final data = filteredDocs[i].data() as Map<String, dynamic>;
                        String dept = data['publishDept'] ?? 'UMUM';
                        Color deptColor = deptColors[dept] ?? Colors.blueGrey;

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: deptColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        dept,
                                        style: TextStyle(
                                          color: deptColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        border: Border.all(color: Colors.red.shade200),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: const [
                                          Icon(Icons.check_circle, size: 12, color: Colors.red),
                                          SizedBox(width: 4),
                                          Text(
                                            "Selesai",
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                Text(
                                  data['title'] ?? 'Tiada Tajuk',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Text(
                                      "${data['startDate']} - ${data['endDate'] ?? data['startDate']}",
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                                    ),
                                    if (data['location'] != null) ...[
                                      const SizedBox(width: 16),
                                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          data['location'],
                                          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ]
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  String selectedDept = "Semua";
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  final List<String> deptList = ["Semua", "JKE", "JKA", "JTMK", "JP"];
  final List<String> monthNames = [
    "Januari", "Februari", "Mac", "April", "Mei", "Jun", 
    "Julai", "Ogos", "September", "Oktober", "November", "Disember"
  ];
  final List<int> yearList = [2024, 2025, 2026, 2027];

  final Map<String, Color> deptColors = {
    "JKE": Colors.orange,
    "JKA": Colors.teal,
    "JTMK": Colors.indigo,
    "JP": Colors.purple,
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Analisis & Statistik Aktiviti",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: selectedDept,
                  decoration: const InputDecoration(
                    labelText: 'Jabatan', 
                    border: OutlineInputBorder(), 
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)
                  ),
                  items: deptList.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: (val) => setState(() => selectedDept = val!),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: selectedMonth,
                  decoration: const InputDecoration(
                    labelText: 'Bulan', 
                    border: OutlineInputBorder(), 
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)
                  ),
                  items: List.generate(12, (index) => DropdownMenuItem(value: index + 1, child: Text(monthNames[index], style: const TextStyle(fontSize: 12)))),
                  onChanged: (val) => setState(() => selectedMonth = val!),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: selectedYear,
                  decoration: const InputDecoration(
                    labelText: 'Tahun', 
                    border: OutlineInputBorder(), 
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)
                  ),
                  items: yearList.map((y) => DropdownMenuItem(value: y, child: Text(y.toString(), style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: (val) => setState(() => selectedYear = val!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('events').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              Map<String, int> deptCounts = {"JKE": 0, "JKA": 0, "JTMK": 0, "JP": 0};
              int totalFilteredEvents = 0;

              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                String publishDept = data['publishDept'] ?? "";
                String dateStr = data['startDate'] ?? "";

                try {
                  List<String> parts = dateStr.split('/');
                  int month = int.parse(parts[1]);
                  int year = int.parse(parts[2]);

                  if (month == selectedMonth && year == selectedYear) {
                    if (selectedDept == "Semua" || publishDept == selectedDept) {
                      totalFilteredEvents++;
                      if (deptCounts.containsKey(publishDept)) {
                        deptCounts[publishDept] = deptCounts[publishDept]! + 1;
                      }
                    }
                  }
                } catch (e) {
                  // Abaikan jika format tarikh tidak sah
                }
              }

              double maxCount = deptCounts.values.fold(0, (max, e) => e > max ? e : max).toDouble();
              double maxY = maxCount < 5 ? 5 : maxCount + 2;

              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.indigo,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Aktiviti (${monthNames[selectedMonth - 1]} $selectedYear)",
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "$totalFilteredEvents",
                              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Icon(Icons.bar_chart, color: Colors.white54, size: 48),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Pecahan Aktiviti Mengikut Jabatan",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 25),
                          
                          SizedBox(
                            height: 250,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: maxY,
                                barTouchData: BarTouchData(enabled: true),
                                titlesData: FlTitlesData(
                                  show: true,
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (double value, TitleMeta meta) {
                                        List<String> keys = deptCounts.keys.toList();
                                        int index = value.toInt();
                                        if (index >= 0 && index < keys.length) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              keys[index],
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: deptColors[keys[index]] ?? Colors.indigo,
                                              ),
                                            ),
                                          );
                                        }
                                        return const Text('');
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 1,
                                      reservedSize: 28,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          value.toInt().toString(),
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                gridData: const FlGridData(show: true, drawVerticalLine: false),
                                borderData: FlBorderData(show: false),
                                barGroups: List.generate(deptCounts.length, (i) {
                                  String key = deptCounts.keys.elementAt(i);
                                  int val = deptCounts[key]!;
                                  return BarChartGroupData(
                                    x: i,
                                    barRods: [
                                      BarChartRodData(
                                        toY: val.toDouble(),
                                        color: deptColors[key] ?? Colors.indigo,
                                        width: 28,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(4),
                                          topRight: Radius.circular(4),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}