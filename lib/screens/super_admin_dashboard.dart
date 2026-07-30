// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'login_screen.dart';
import 'add_event_page.dart';
import '../widgets/event_card.dart';
import '../widgets/custom_popup.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int _selectedIndex = 0;
  String _selectedDepartment = 'Semua Jabatan';
  String _eventSearchQuery = "";

  // Senarai Jabatan untuk Filter Super Admin
  final List<String> _departments = [
    'Semua Jabatan',
    'JTMK',
    'JKE',
    'JKM',
    'JP',
    'JKA',
  ];

  final Map<String, Color> deptColors = const {
    "JKE": Colors.orange,
    "JKA": Colors.teal,
    "JTMK": Colors.indigo,
    "JP": Colors.purple,
    "JKM": Colors.blueGrey,
  };

  // LOGOUT FUNCTION
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  // DIALOG POPUP UNTUK TAMBAH ADMIN BAHARU
  void _showAddAdminDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedDept = 'JTMK';
    final List<String> deptOptions = ["JKE", "JKA", "JTMK", "JP", "JKM"];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Text(
                'Tambah Admin Jabatan',
                style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Penuh / Gelaran',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-mel Rasmi',
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Kata Laluan Sementara',
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      initialValue: selectedDept,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Jabatan',
                        border: OutlineInputBorder(),
                      ),
                      items: deptOptions
                          .map((dept) => DropdownMenuItem(value: dept, child: Text(dept)))
                          .toList(),
                      onChanged: (val) => setDialogState(() => selectedDept = val!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty ||
                        emailController.text.trim().isEmpty ||
                        passwordController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sila isi semua maklumat!')),
                      );
                      return;
                    }

                    try {
                      // 1. Cipta akaun Authentication baharu di Firebase Auth
                      UserCredential userCredential = await FirebaseAuth.instance
                          .createUserWithEmailAndPassword(
                        email: emailController.text.trim(),
                        password: passwordController.text.trim(),
                      );

                      // 2. Simpan data Admin baharu ke koleksi 'users' menggunakan UID yang sepadan
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userCredential.user!.uid)
                          .set({
                        'uid': userCredential.user!.uid,
                        'name': nameController.text.trim(),
                        'email': emailController.text.trim(),
                        'department': selectedDept,
                        'role': 'admin',
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Admin Jabatan berjaya didaftarkan!')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Ralat: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Simpan Admin'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // DIALOG POPUP UNTUK TAMBAH LOKASI BAHARU
  void _showAddLocationDialog() {
    final nameController = TextEditingController();
    final latController = TextEditingController();
    final longController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text(
            'Tambah Lokasi / Bangunan',
            style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lokasi (cth: Dewan Kuliah A)',
                    prefixIcon: Icon(Icons.location_city),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: latController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Latitude (cth: 4.5891)',
                    prefixIcon: Icon(Icons.map),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: longController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Longitude (cth: 101.1234)',
                    prefixIcon: Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (nameController.text.trim().isEmpty ||
                    latController.text.trim().isEmpty ||
                    longController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sila isi semua maklumat lokasi!')),
                  );
                  return;
                }

                try {
                  double? lat = double.tryParse(latController.text.trim());
                  double? long = double.tryParse(longController.text.trim());

                  if (lat == null || long == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sila masukkan nilai Latitude & Longitude yang sah!')),
                    );
                    return;
                  }

                  // Simpan data Lokasi ke Firestore
                  await FirebaseFirestore.instance.collection('locations').add({
                    'name': nameController.text.trim(),
                    'latitude': lat,
                    'longitude': long,
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lokasi berjaya ditambah!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ralat: $e')),
                    );
                  }
                }
              },
              child: const Text('Simpan Lokasi'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 11)),
            Text("$count", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Super Admin Panel',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple[800],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: _buildSelectedTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.deepPurple[800],
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Urus Event',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.manage_accounts),
            label: 'Urus Admin/User',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Urus Lokasi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            label: 'Analytics',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              backgroundColor: Colors.deepPurple[800],
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddEventPage()),
              ),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildSelectedTab() {
    switch (_selectedIndex) {
      case 0:
        return _buildEventManagementTab();
      case 1:
        return _buildUserManagementTab();
      case 2:
        return _buildLocationManagementTab();
      case 3:
        return _buildAnalyticsTab();
      default:
        return _buildEventManagementTab();
    }
  }

  // TAB 1: Urus Event (Mengambil Data Realtime dari Firebase)
  Widget _buildEventManagementTab() {
    Query eventQuery = FirebaseFirestore.instance.collection('events');
    if (_selectedDepartment != 'Semua Jabatan') {
      eventQuery = eventQuery.where('publishDept', isEqualTo: _selectedDepartment);
    }

    return Column(
      children: [
        // 1. Kad Statistik Aktif / Akan Datang / Tamat
        StreamBuilder<QuerySnapshot>(
          stream: eventQuery.snapshots(),
          builder: (context, snapshot) {
            int aktif = 0;
            int akanDatang = 0;
            int tamat = 0;

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
              padding: const EdgeInsets.only(top: 12.0),
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

        // 2. Dropdown Filter Jabatan & Kotak Carian
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.deepPurple.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tapis Mengikut Jabatan:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<String>(
                      value: _selectedDepartment,
                      underline: const SizedBox(),
                      items: _departments.map((String dept) {
                        return DropdownMenuItem<String>(
                          value: dept,
                          child: Text(dept),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedDepartment = newValue!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  labelText: "Cari event...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
                onChanged: (val) => setState(() => _eventSearchQuery = val.toLowerCase()),
              ),
            ],
          ),
        ),

        // 3. Senarai Event
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: eventQuery.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              var docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                String title = (data['title'] ?? '').toString().toLowerCase();
                return title.contains(_eventSearchQuery);
              }).toList();

              if (docs.isEmpty) {
                return const Center(child: Text('Tiada acara dijumpai.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var doc = docs[index];
                  return EventCard(
                    eventData: doc.data() as Map<String, dynamic>,
                    deptColors: deptColors,
                    isAdmin: true,
                    onEdit: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AddEventPage(doc: doc)),
                    ),
                    onDelete: () => showDialog(
                      context: context,
                      builder: (_) => CustomPopup(
                        title: "Padam Event?",
                        content: "Adakah anda pasti mahu memadam event ini?",
                        onConfirm: () async => await doc.reference.delete(),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // TAB 2: Urus Admin & User (Live Stream dari Database Users)
  Widget _buildUserManagementTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple[800],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _showAddAdminDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('Tambah Admin Jabatan Baru'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Senarai Admin Sistem:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'admin')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text("Tiada rekod admin lagi."));

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepPurple,
                          child: Text(
                            (data['name'] ?? 'A')[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          "${data['name'] ?? 'Nama Admin'} (${data['department'] ?? 'Tiada Dept'})",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(data['email'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Chip(
                              label: Text('Admin', style: TextStyle(fontSize: 10)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => CustomPopup(
                                    title: "Padam Admin?",
                                    content: "Adakah anda pasti mahu memadam akaun admin ${data['name']}?",
                                    onConfirm: () async => await docs[index].reference.delete(),
                                  ),
                                );
                              },
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // TAB 3: Urus Lokasi (Boleh Tambah & Papar Senarai Realtime dari Firestore)
  Widget _buildLocationManagementTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                const Icon(Icons.add_location_alt, size: 60, color: Colors.deepPurple),
                const SizedBox(height: 8),
                const Text(
                  'Pengurusan Lokasi & Point of Interest',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _showAddLocationDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Lokasi / Bangunan Baru'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Senarai Lokasi Terdaftar:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('locations').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('Belum ada lokasi terdaftar. Sila tambah lokasi baharu.'),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.deepPurple,
                          child: Icon(Icons.pin_drop, color: Colors.white),
                        ),
                        title: Text(
                          data['name'] ?? 'Tiada Nama Lokasi',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Lat: ${data['latitude']} | Long: ${data['longitude']}",
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => CustomPopup(
                                title: "Padam Lokasi?",
                                content: "Adakah anda pasti mahu memadam lokasi ${data['name']}?",
                                onConfirm: () async => await docs[index].reference.delete(),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // TAB 4: Analytics
  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Analisis Keseluruhan Kampus",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('events').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              Map<String, int> deptCounts = {"JKE": 0, "JKA": 0, "JTMK": 0, "JP": 0, "JKM": 0};
              int totalEvents = snapshot.data!.docs.length;

              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                String publishDept = data['publishDept'] ?? "";
                if (deptCounts.containsKey(publishDept)) {
                  deptCounts[publishDept] = deptCounts[publishDept]! + 1;
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
                      color: Colors.deepPurple[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Jumlah Keseluruhan Aktiviti",
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "$totalEvents",
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                                color: deptColors[keys[index]] ?? Colors.deepPurple,
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
                                        color: deptColors[key] ?? Colors.deepPurple,
                                        width: 24,
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