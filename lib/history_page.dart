// lib/pages/history_page.dart

import 'package:flutter/material.dart';
import '../models/comment_model.dart';
import '../services/omdb_service.dart';
import '../services/supabase_service.dart';
import '../sqlite/user_model.dart';
import '../services/time_utils.dart';

class HistoryPage extends StatefulWidget {
  final User user;
  const HistoryPage({Key? key, required this.user}) : super(key: key);

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final SupabaseService _supabaseService = SupabaseService();
  final OmdbService _omdbService = OmdbService();

  late Future<List<Comment>> _historyFuture;
  final Map<String, String> _movieTitles = {};

  // Warna Tema Konsisten (Dark Mode)
  final Color _bgColor = const Color(0xFF121212);
  final Color _cardColor = const Color(0xFF1E1E1E);
  final Color _accentColor = const Color(0xFFFFC107); // Amber/Gold
  final Color _textColor = const Color(0xFFE0E0E0);
  final Color _subTextColor = const Color(0xFFB0B0B0);

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadHistory();
  }

  Future<List<Comment>> _loadHistory() async {
    final comments = await _supabaseService.getCommentsByUser(
      widget.user.userId,
    );

    // Ambil semua IMDB-ID unik
    final uniqueIds = comments.map((c) => c.imdbId).toSet();

    // Fetch semua judul film secara paralel
    await _fetchMovieTitles(uniqueIds);

    return comments;
  }

  Future<void> _fetchMovieTitles(Set<String> imdbIds) async {
    for (String id in imdbIds) {
      if (!_movieTitles.containsKey(id)) {
        try {
          final movie = await _omdbService.getMovieDetails(id);
          if (mounted) {
            setState(() {
              _movieTitles[id] = movie.title;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _movieTitles[id] = 'Unknown Title';
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      // Jika butuh AppBar sendiri:
      // appBar: AppBar(title: Text('History'), backgroundColor: _bgColor, foregroundColor: Colors.white),
      body: FutureBuilder<List<Comment>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: _accentColor),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading history',
                    style: TextStyle(color: _textColor),
                  ),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(color: _subTextColor, fontSize: 12),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_toggle_off,
                    size: 64,
                    color: Colors.grey[800],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No comment history found',
                    style: TextStyle(fontSize: 18, color: _subTextColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start commenting on movies to see them here.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            );
          }

          final comments = snapshot.data!;
          return RefreshIndicator(
            color: _accentColor,
            backgroundColor: _cardColor,
            onRefresh: () async {
              setState(() {
                _historyFuture = _loadHistory();
              });
              await _historyFuture;
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 16, bottom: 80),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                return _buildHistoryCard(comment);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(Comment comment) {
    final movieTitle = _movieTitles[comment.imdbId] ?? 'Loading title...';
    final timezones = TimeUtil.getFormattedTimezones(comment.posted);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Movie Title & Icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.movie, size: 20, color: _accentColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    movieTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // User Comment Bubble
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C), // Slightly lighter than card
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.grey[700],
                        backgroundImage:
                            comment.userPhoto != null &&
                                comment.userPhoto!.isNotEmpty
                            ? NetworkImage(comment.userPhoto!)
                            : null,
                        child:
                            comment.userPhoto == null ||
                                comment.userPhoto!.isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 12,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        comment.userName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: _accentColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    comment.userComment,
                    style: TextStyle(
                      fontSize: 14,
                      color: _textColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Divider(color: Colors.grey[800]),
            const SizedBox(height: 8),

            // Timezones Info
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: _subTextColor),
                const SizedBox(width: 6),
                Text(
                  'Posted on:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _subTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Grid of Timezones
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTimeChip('WIB', timezones['WIB']!),
                _buildTimeChip('WITA', timezones['WITA']!),
                _buildTimeChip('WIT', timezones['WIT']!),
                _buildTimeChip('LDN', timezones['London']!),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeChip(String label, String time) {
    return Container(
      // Padding horizontal diperluas (12) agar teks tidak mepet
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _bgColor, // Menggunakan warna background dasar agar clean
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min, // Agar lebar kotak menyesuaikan isi teks
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11, // Ukuran font label
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8), // Jarak pemisah
            height: 12,
            width: 1,
            color: Colors.grey[700],
          ),
          Text(
            time, // Menampilkan waktu FULL tanpa dipotong (.substring dihapus)
            style: TextStyle(
              fontSize: 12, // Ukuran font waktu
              color: _textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
