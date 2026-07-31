import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

class SocialMediaService {
  // Fungsi untuk ambil token terkini secara dinamik dari Firestore
  static Future<String?> _getLatestAccessToken() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('facebook_config')
          .get();
          
      if (doc.exists && doc.data() != null) {
        return doc.data()!['access_token'] as String?;
      }
    } catch (e) {
      debugPrint('Ralat ambil token dari Firestore: $e');
    }
    return null;
  }

  /// 1. Hantar post ke Facebook Page (Menggunakan token live dari Firestore)
  static Future<bool> postToFacebook({
    required String message,
    String? mediaUrl,     
    bool isVideo = false, 
  }) async {
    try {
      // Ambil token terkini dari Firestore sebelum post
      final String? accessToken = await _getLatestAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        debugPrint('FB Post Gagal: Access Token tidak dijumpai di Firestore.');
        return false;
      }

      String endpoint = 'https://graph.facebook.com/v25.0/me/feed';
      Map<String, String> bodyData = {
        'access_token': accessToken,
      };

      if (mediaUrl != null && mediaUrl.isNotEmpty && mediaUrl != "https://via.placeholder.com/150") {
        if (isVideo) {
          endpoint = 'https://graph.facebook.com/v25.0/me/videos';
          bodyData['file_url'] = mediaUrl;
          bodyData['description'] = message;
        } else {
          endpoint = 'https://graph.facebook.com/v25.0/me/photos';
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
        debugPrint('FB Post Bergambar/Video Berjaya: ${response.body}');
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

  /// 2. Fungsi Multi-Posting (Penghantaran Serentak)
  static Future<Map<String, bool>> publishToAll({
    required String message,
    String? mediaUrl,
    bool isVideo = false,
  }) async {
    final results = await Future.wait([
      postToFacebook(message: message, mediaUrl: mediaUrl, isVideo: isVideo),
    ]);

    return {
      'facebook': results[0],
    };
  }
}