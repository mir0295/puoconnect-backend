// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

// 1. Import servis social media yang anda cipta
import '../services/social_media_service.dart';

class AddEventPage extends StatefulWidget {
  final DocumentSnapshot? doc;
  const AddEventPage({super.key, this.doc});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final titleController = TextEditingController();
  final plcController = TextEditingController();
  final imageController = TextEditingController();
  bool _isLoading = false;

  ValueNotifier<String> startDate = ValueNotifier('Pilih Tarikh Mula');
  ValueNotifier<String> endDate = ValueNotifier('Pilih Tarikh Tamat');
  ValueNotifier<String> startTime = ValueNotifier('Pilih Masa Mula');
  ValueNotifier<String> endTime = ValueNotifier('Pilih Masa Tamat');

  String selectedLoc = 'Dewan Kuliah A';
  String selectedDept = 'Semua';

  @override
  void initState() {
    super.initState();
    if (widget.doc != null) {
      Map<String, dynamic> data = widget.doc!.data() as Map<String, dynamic>;
      titleController.text = data['title'] ?? '';
      plcController.text = data['plc'] ?? '';
      imageController.text = data['imageUrl'] ?? '';
      startDate.value = data['startDate'] ?? 'Pilih Tarikh Mula';
      endDate.value = data['endDate'] ?? 'Pilih Tarikh Tamat';
      startTime.value = data['startTime'] ?? 'Pilih Masa Mula';
      endTime.value = data['endTime'] ?? 'Pilih Masa Tamat';
      selectedLoc = data['location'] ?? 'Dewan Kuliah A';
      selectedDept = data['publishDept'] ?? 'Semua';
    }
  }

  Future<void> _saveEvent() async {
    if (titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sila isi nama aktiviti!")));
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'title': titleController.text,
      'plc': plcController.text,
      'imageUrl': imageController.text.isEmpty ? "https://via.placeholder.com/150" : imageController.text,
      'startDate': startDate.value,
      'endDate': endDate.value,
      'startTime': startTime.value,
      'endTime': endTime.value,
      'location': selectedLoc,
      'publishDept': selectedDept,
      'isActive': true,
    };

    try {
      if (widget.doc == null) {
        // A) Jika Tambah Aktiviti Baharu
        await FirebaseFirestore.instance.collection('events').add(data);

        // 2. Sediakan mesej ringkas & kemas untuk Facebook
        String broadcastMessage = "🔥 [AKTIVITI TERKINI PUOCONNECT] 🔥\n\n"
            "✨ Jom ramaikan dan sertai program menarik yang bakal diadakan di kampus kita!\n\n"
            "📌 Nama Aktiviti: ${titleController.text}\n"
            "🏢 Anjuran/PLC: ${plcController.text}\n"
            "🏛️ Sasaran Jabatan: $selectedDept\n\n"
            "📅 Tarikh: ${startDate.value} hingga ${endDate.value}\n"
            "⏰ Masa: ${startTime.value} - ${endTime.value}\n"
            "📍 Lokasi: $selectedLoc\n\n"
            "---------------------------------------\n"
            "📲 Muat turun aplikasi PuoNotify sekarang untuk semak jadual dan maklumat lanjut aktiviti!\n"
            "#PuoConnect #PuoNotify #CampusLife #JTMK #PolyCC";

        // 3. Post ke Facebook Page (Sokong Teks & Gambar Sekali)
        bool isFbSuccess = await SocialMediaService.postToFacebook(
          message: broadcastMessage,
          mediaUrl: imageController.text, // Hantar link gambar dari Firebase Storage
          isVideo: false,
        );

        if (!mounted) return;
        if (isFbSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Aktiviti berjaya disimpan & di-post ke Facebook!")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Aktiviti disimpan, tetapi gagal di-post ke Facebook.")),
          );
        }
      } else {
        // B) Jika Edit Aktiviti Sahaja
        await widget.doc!.reference.update(data);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Aktiviti berjaya dikemas kini!")),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ralat: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _styledCard(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
        ),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: Text(widget.doc == null ? "Tambah Aktiviti" : "Edit Aktiviti")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
                if (result != null && result.files.first.bytes != null) {
                  setState(() => _isLoading = true);
                  Uint8List fileBytes = result.files.first.bytes!;
                  String fileName = "${DateTime.now().millisecondsSinceEpoch}_${result.files.first.name}";
                  try {
                    TaskSnapshot task = await FirebaseStorage.instance.ref('event_images/$fileName').putData(fileBytes);
                    String downloadUrl = await task.ref.getDownloadURL();
                    setState(() {
                      imageController.text = downloadUrl;
                      _isLoading = false;
                    });
                  } catch (e) {
                    setState(() => _isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal muat naik: $e")));
                  }
                }
              },
              child: Container(
                height: 200, width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300], 
                  borderRadius: BorderRadius.circular(20),
                  image: imageController.text.isNotEmpty ? DecorationImage(image: NetworkImage(imageController.text), fit: BoxFit.cover) : null,
                ),
                child: imageController.text.isEmpty 
                    ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate, size: 50), Text("Tekan untuk pilih gambar")]) 
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            
            _styledCard("Maklumat Asas", [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: "Nama Aktiviti", border: OutlineInputBorder())),
              const SizedBox(height: 15),
              TextField(controller: plcController, decoration: const InputDecoration(labelText: "Nama PLC", border: OutlineInputBorder())),
            ]),
            
            _styledCard("Jadual & Lokasi", [
              _buildPicker(context, "Tarikh Mula", Icons.calendar_today, startDate, () async {
                DateTime? p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2026), lastDate: DateTime(2030));
                if (p != null) startDate.value = "${p.day}/${p.month}/${p.year}";
              }),
              _buildPicker(context, "Tarikh Tamat", Icons.calendar_today, endDate, () async {
                DateTime? p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2026), lastDate: DateTime(2030));
                if (p != null) endDate.value = "${p.day}/${p.month}/${p.year}";
              }),
              _buildPicker(context, "Masa Mula", Icons.access_time, startTime, () async {
                TimeOfDay? p = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                if (p != null) startTime.value = p.format(context);
              }),
              _buildPicker(context, "Masa Tamat", Icons.access_time, endTime, () async {
                TimeOfDay? p = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                if (p != null) endTime.value = p.format(context);
              }),
              DropdownButtonFormField<String>(
                value: selectedLoc,
                decoration: const InputDecoration(labelText: "Lokasi", border: OutlineInputBorder()),
                items: ["Dewan Kuliah A", "Dewan Kuliah B"].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                onChanged: (val) => setState(() => selectedLoc = val!),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: selectedDept,
                decoration: const InputDecoration(labelText: "Jabatan", border: OutlineInputBorder()),
                items: ["Semua", "JTMK", "JKE"].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (val) => setState(() => selectedDept = val!),
              ),
            ]),
            
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveEvent, 
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : Text(widget.doc == null ? "SIMPAN & PUBLISH AKTIVITI" : "KEMAS KINI AKTIVITI"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPicker(BuildContext context, String label, IconData icon, ValueNotifier<String> notifier, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15), 
      child: ValueListenableBuilder(
        valueListenable: notifier, 
        builder: (context, value, _) => InkWell(
          onTap: onTap, 
          child: InputDecorator(
            decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), prefixIcon: Icon(icon)), 
            child: Text(value),
          ),
        ),
      ),
    );
  }
}