import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SocialMediaService {
  // Page Access Token dari Graph Explorer
  static const String _fbPageAccessToken =
      'EAAV031yuNRUBSGpJNYuDVxxcsNy2LoPmbEfcT0F0sY0nfadAK9ct3ev78CHDO3NoUUDoliieDfKpGuPko1bDXC8N7pKQ0Jvdm3SuJLucZBIE82jvn6PWmbBfpQTPPP3OMNjtvDSPYY3XmsuNNZBTUJVJRCWOmvZArNzwFm9qSxsZAZAxE8UKA44Ez0TwV5hkaiuygtna0';

  /// 1. Hantar post ke Facebook Page (Menyokong Teks, Gambar, atau Video)
  static Future<bool> postToFacebook({
    required String message,
    String? mediaUrl,     // Pautan gambar atau video dari Firebase Storage
    bool isVideo = false, // Tetapkan true jika fail tersebut adalah video
  }) async {
    try {
      String endpoint = 'https://graph.facebook.com/v25.0/me/feed';
      Map<String, String> bodyData = {
        'access_token': _fbPageAccessToken,
      };

      // Semak sama ada terdapat media (gambar atau video) yang disertakan
      if (mediaUrl != null && mediaUrl.isNotEmpty && mediaUrl != "https://via.placeholder.com/150") {
        if (isVideo) {
          // Endpoint khas untuk hantar Video ke Facebook Page
          endpoint = 'https://graph.facebook.com/v25.0/me/videos';
          bodyData['file_url'] = mediaUrl;
          bodyData['description'] = message; // Kapsyen untuk video
        } else {
          // Endpoint khas untuk hantar Gambar ke Facebook Page
          endpoint = 'https://graph.facebook.com/v25.0/me/photos';
          bodyData['url'] = mediaUrl;
          bodyData['caption'] = message; // Kapsyen untuk gambar
        }
      } else {
        // Hantaran teks biasa jika tiada media
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
      // Boleh tambah platform lain di sini nanti
    ]);

    return {
      'facebook': results[0],
    };
  }
}