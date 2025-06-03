import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/anime_result.dart';

class TraceMoeApi {
  static Future<List<AnimeResult>> searchAnime(File imageFile) async {
    final uri = Uri.parse('https://api.trace.moe/search');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath(
        'image', imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      ));

    final response = await request.send();

    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final jsonData = jsonDecode(respStr);

      if (jsonData['error'] != null && jsonData['error'].isNotEmpty) {
        throw Exception('API Error: ${jsonData['error']}');
      }

      final results = jsonData['result'] as List;
      return results.map((e) => AnimeResult.fromJson(e)).toList();
    } else {
      throw Exception('HTTP ${response.statusCode}');
    }
  }
}
