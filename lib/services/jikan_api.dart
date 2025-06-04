// lib/services/jikan_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/anime_jikan_model.dart';

class JikanApi {
  static const String _baseUrl = 'https://api.jikan.moe/v4';

  static Future<List<Anime>> searchAnime(String query) async {
    final response = await http.get(Uri.parse('$_baseUrl/anime?q=$query&limit=20'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['data'] as List).map((json) => Anime.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load search results');
    }
  }

  static Future<List<Anime>> getSeasonNowAnime() async {
    final response = await http.get(Uri.parse('$_baseUrl/seasons/now'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['data'] as List).map((json) => Anime.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load current season anime');
    }
  }

  static Future<List<Anime>> getTopAnime({String type = 'bypopularity', int page = 1, int limit = 20}) async {
    final response = await http.get(Uri.parse('$_baseUrl/top/anime?filter=$type&page=$page&limit=$limit'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['data'] as List).map((json) => Anime.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load top anime ($type)');
    }
  }

  static Future<List<Anime>> getAllAnime({int page = 1, int limit = 20, int? genreId}) async {
    String url = '$_baseUrl/anime?page=$page&limit=$limit';
    if (genreId != null) {
      url += '&genres=$genreId';
    }
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['data'] as List).map((json) => Anime.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load all anime');
    }
  }

  static Future<Anime> getAnimeDetails(int malId) async {
    final response = await http.get(Uri.parse('$_baseUrl/anime/$malId/full'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Anime.fromJson(data['data']);
    } else {
      throw Exception('Failed to load anime details for ID: $malId');
    }
  }

  static Future<List<Genre>> getGenres() async {
    final response = await http.get(Uri.parse('$_baseUrl/genres/anime'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['data'] as List).map((json) => Genre.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load genres');
    }
  }
}