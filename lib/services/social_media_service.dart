import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class SocialMediaService {
  // Ambil token secara dinamik mengikut dokumen target yang dipilih
  static Future<Map<String, dynamic>?> _getConfig(String targetConfig) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc(targetConfig) // Baca ikut target (Main / Jabatan)
          .get();
          
      if (doc.exists && doc.data() != null) {
        return doc.data();
      }
    } catch (e) {
      debugPrint('Ralat ambil config dari Firestore: $e');
    }
    return null;
  }

  /// Hantar post ke Facebook Page mengikut akaun sasaran
  static Future<bool> postToFacebook({
    required String message,
    String? mediaUrl,     
    bool isVideo = false, 
    required String targetConfig, // Tambah parameter ini (cth: 'facebook_config')
  }) async {
    try {
      final config = await _getConfig(targetConfig);
      final String? accessToken = config?['access_token'];
      final String? pageId = config?['page_id'] ?? 'me'; // Guna page_id jika ada

      if (accessToken == null || accessToken.isEmpty) {
        debugPrint('FB Post Gagal: Access Token tidak dijumpai untuk $targetConfig.');
        return false;
      }

      // Jika ada page_id khusus, guna graph.facebook.com/v25.0/{page_id}/feed
      String endpoint = 'https://graph.facebook.com/v25.0/$pageId/feed';
      Map<String, String> bodyData = {
        'access_token': accessToken,
      };

      if (mediaUrl != null && mediaUrl.isNotEmpty && mediaUrl != "https://via.placeholder.com/150") {
        if (isVideo) {
          endpoint = 'https://graph.facebook.com/v25.0/$pageId/videos';
          bodyData['file_url'] = mediaUrl;
          bodyData['description'] = message;
        } else {
          endpoint = 'https://graph.facebook.com/v25.0/$pageId/photos';
          bodyData['url'] = mediaUrl;
          bodyData['caption'] = message;
        }
      } else {
        bodyData['message'] = message;
      }

      final response = await http.post(
        Uri.parse(endpoint),
        body: bodyData,
      );

      if (response.statusCode == 200) {
        debugPrint('FB Post Berjaya ke $targetConfig: ${response.body}');
        return true;
      } else {
        debugPrint('FB Post Gagal: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error Facebook API: $e');
      return false;
    }
  }
}