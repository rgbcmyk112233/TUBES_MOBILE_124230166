import 'package:flutter/material.dart';
import '../models/omdb_movie_model.dart';
import '../models/comment_model.dart';
import '../sqlite/user_model.dart';
import '../services/omdb_service.dart';
import '../services/supabase_service.dart';
import 'ai_chat_page.dart';

class MovieDetailPage extends StatefulWidget {
  final String imdbId;
  final User? user;

  const MovieDetailPage({Key? key, required this.imdbId, this.user})
    : super(key: key);

  @override
  _MovieDetailPageState createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  final OmdbService _omdbService = OmdbService();
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _commentController = TextEditingController();

  OmdbMovie? _movie;
  List<Comment> _comments = [];
  bool _isLoading = true;
  bool _isLoadingComments = true;
  bool _isPostingComment = false;
  String _errorMessage = '';

  // Fitur Konversi Mata Uang
  bool _showInIdr = false; // State untuk toggle currency
  final double _usdToIdrRate = 16250.0; // Estimasi kurs

  // Warna Tema Konsisten (Dark Mode)
  final Color _bgColor = const Color(0xFF121212);
  final Color _cardColor = const Color(0xFF1E1E1E);
  final Color _inputColor = const Color(0xFF2C2C2C);
  final Color _accentColor = const Color(0xFFFFC107); // Amber/Gold
  final Color _textColor = const Color(0xFFE0E0E0);
  final Color _subTextColor = const Color(0xFFB0B0B0);

  @override
  void initState() {
    super.initState();
    _loadMovieDetails();
    _loadComments();
    _initializeSupabase();
  }

  Future<void> _initializeSupabase() async {
    await _supabaseService.initialize();
  }

  Future<void> _loadMovieDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final movie = await _omdbService.getMovieDetails(widget.imdbId);
      setState(() {
        _movie = movie;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoadingComments = true;
    });

    try {
      final comments = await _supabaseService.getComments(widget.imdbId);
      setState(() {
        _comments = comments;
        _isLoadingComments = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingComments = false;
      });
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty || widget.user == null) return;

    setState(() {
      _isPostingComment = true;
    });

    try {
      await _supabaseService.addComment(
        imdbId: widget.imdbId,
        userId: widget.user!.userId,
        userName: widget.user!.userName,
        userComment: _commentController.text.trim(),
        userPhoto: widget.user!.userPhoto,
      );

      _commentController.clear();
      await _loadComments();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Komentar berhasil ditambahkan',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green[800],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isPostingComment = false;
      });
    }
  }

  void _openAIChat() {
    if (_movie != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AIChatPage(
            movieTitle: _movie!.title,
            initialMessage:
                'jelaskan saya tentang film "${_movie!.title}" dan harus diingat, tidak boleh membalas selain hal diluar konteks film tersebut',
          ),
        ),
      );
    }
  }

  // --- LOGIKA KONVERSI MATA UANG ---
  String _formatCurrency(String boxOfficeValue) {
    if (boxOfficeValue == 'N/A') return 'N/A';

    // Jika user memilih USD, kembalikan nilai asli
    if (!_showInIdr) return boxOfficeValue;

    // Bersihkan string (hapus '$' dan ',')
    String cleanValue = boxOfficeValue.replaceAll(RegExp(r'[$,]'), '');
    double? valueInUsd = double.tryParse(cleanValue);

    if (valueInUsd == null) return boxOfficeValue;

    // Hitung IDR
    double valueInIdr = valueInUsd * _usdToIdrRate;

    // Format manual ke Rupiah (tanpa dependency intl biar aman)
    // Menggunakan regex untuk menambahkan titik setiap 3 digit
    String idrString = valueInIdr.toStringAsFixed(0);
    String formatted = '';
    int count = 0;
    for (int i = idrString.length - 1; i >= 0; i--) {
      count++;
      formatted = idrString[i] + formatted;
      if (count % 3 == 0 && i != 0) {
        formatted = '.' + formatted;
      }
    }

    return 'Rp $formatted';
  }

  // --- WIDGET BUILDERS ---

  Widget _buildComment(Comment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _inputColor,
              border: Border.all(color: Colors.grey[800]!),
              image: comment.userPhoto != null && comment.userPhoto!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(comment.userPhoto!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: comment.userPhoto == null || comment.userPhoto!.isEmpty
                ? Icon(Icons.person, size: 20, color: _subTextColor)
                : null,
          ),
          const SizedBox(width: 12),

          // Comment Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _cardColor, // Menggunakan warna kartu gelap
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info and Time
                  Row(
                    children: [
                      Text(
                        comment.userName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _accentColor, // Nama user pakai warna aksen
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        comment.timeAgo,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Comment Text
                  Text(
                    comment.userComment,
                    style: TextStyle(
                      fontSize: 14,
                      color: _textColor, // Teks putih/terang
                      height: 1.4,
                    ),
                    maxLines: 10,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.comment, color: _accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Comments',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Comment Input (only if user is logged in)
        if (widget.user != null) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  style: TextStyle(color: _textColor),
                  decoration: InputDecoration(
                    hintText: 'Share your thoughts on this movie...',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: _inputColor, // Background input gelap
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _accentColor, width: 1),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isPostingComment ? null : _postComment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor:
                          Colors.black, // Teks hitam di atas tombol gold/amber
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isPostingComment
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black,
                              ),
                            ),
                          )
                        : const Text(
                            'Post Comment',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ] else ...[
          // Login Prompt (Dark Styled)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2214), // Darker orange/brown bg
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.orange[400], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Please login to add a comment.',
                    style: TextStyle(color: Colors.orange[200], fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Comments List
        if (_isLoadingComments)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: CircularProgressIndicator(color: _accentColor),
            ),
          )
        else if (_comments.isEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _inputColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 40,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No comments yet',
                    style: TextStyle(
                      color: _subTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Be the first to share your opinion!',
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          Column(children: _comments.map(_buildComment).toList()),
      ],
    );
  }

  Widget _buildPosterSection() {
    return SizedBox(
      width: double.infinity,
      height: 420,
      child: Stack(
        children: [
          // Background Poster
          _movie?.poster != null && _movie!.poster != 'N/A'
              ? Image.network(
                  _movie!.poster,
                  width: double.infinity,
                  height: 420,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholderPoster();
                  },
                )
              : _buildPlaceholderPoster(),

          // Gradient Overlay (Darker at bottom)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  _bgColor.withOpacity(0.0), // Transparent mid
                  _bgColor.withOpacity(0.9), // Fade to black bg
                  _bgColor, // Solid black at very bottom
                ],
                stops: const [0.0, 0.4, 0.8, 1.0],
              ),
            ),
          ),

          // Movie Info Overlay
          Positioned(
            left: 16,
            right: 16,
            bottom: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  _movie?.title ?? 'Loading...',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Chips Row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_movie?.year != null)
                      _buildInfoChip(_movie!.year, Icons.calendar_today),
                    if (_movie?.runtime != null && _movie!.runtime != 'N/A')
                      _buildInfoChip(_movie!.runtime, Icons.access_time),
                    if (_movie?.rated != null && _movie!.rated != 'N/A')
                      _buildInfoChip(
                        _movie!.rated,
                        Icons.verified_user_outlined,
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // IMDB Rating (Prominent)
                if (_movie?.imdbRating != null && _movie!.imdbRating != 'N/A')
                  Row(
                    children: [
                      Icon(Icons.star, color: _accentColor, size: 24),
                      const SizedBox(width: 6),
                      Text(
                        _movie!.imdbRating,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        '/10',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      if (_movie?.imdbVotes != null &&
                          _movie!.imdbVotes != 'N/A')
                        Text(
                          '(${_movie!.imdbVotes} votes)',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),

          // Custom Back Button
          Positioned(
            top: 40,
            left: 16,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderPoster() {
    return Container(
      color: _cardColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie, size: 60, color: Colors.grey[800]),
            const SizedBox(height: 8),
            Text('No Image', style: TextStyle(color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1), // Glassmorphism-like
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value != 'N/A' ? value : '-',
              style: TextStyle(fontSize: 15, color: _textColor),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildRatingChip(Rating rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rating.source,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _accentColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            rating.value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_movie == null) return Container();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Genre (Updated Style)
          if (_movie!.genre != 'N/A')
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _movie!.genre.split(', ').map((genre) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _inputColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[800]!),
                  ),
                  child: Text(
                    genre,
                    style: TextStyle(color: _subTextColor, fontSize: 13),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 24),

          // Plot
          if (_movie!.plot != 'N/A') ...[
            Text(
              'Synopsis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _movie!.plot,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Movie Details
          Text(
            'Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey[800]),
          _buildInfoRow('Director', _movie!.director),
          _buildInfoRow('Writer', _movie!.writer),
          _buildInfoRow('Cast', _movie!.actors),
          _buildInfoRow('Released', _movie!.released),

          // --- BOX OFFICE DENGAN KONVERSI ---
          if (_movie!.boxOffice != 'N/A')
            _buildInfoRow(
              'Box Office',
              _formatCurrency(_movie!.boxOffice),
              trailing: Container(
                height: 24,
                decoration: BoxDecoration(
                  color: _inputColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _currencyToggleItem('USD', !_showInIdr),
                    Container(width: 1, color: Colors.grey[800]),
                    _currencyToggleItem('IDR', _showInIdr),
                  ],
                ),
              ),
            ),

          Divider(color: Colors.grey[800]),

          const SizedBox(height: 20),

          // Ratings
          if (_movie!.ratings.isNotEmpty) ...[
            Text(
              'Other Ratings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              children: _movie!.ratings
                  .map((rating) => _buildRatingChip(rating))
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],

          // Awards
          if (_movie!.awards != 'N/A') ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _accentColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.emoji_events, color: _accentColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _movie!.awards,
                      style: TextStyle(color: Colors.orange[100]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Widget kecil untuk toggle tombol currency
  Widget _currencyToggleItem(String text, bool isActive) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showInIdr = (text == 'IDR');
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        color: isActive ? _accentColor.withOpacity(0.2) : Colors.transparent,
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isActive ? _accentColor : Colors.grey,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      // AppBar kita buat transparan/hide karena sudah ada custom back button di Stack poster
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _accentColor),
                  const SizedBox(height: 16),
                  Text(
                    'Loading movie details...',
                    style: TextStyle(color: _subTextColor),
                  ),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load movie',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _subTextColor),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loadMovieDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                    ),
                    child: const Text(
                      'Try Again',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildPosterSection(),
                        _buildContent(),
                        _buildCommentsSection(),
                        const SizedBox(height: 40), // Bottom padding
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: _movie != null
          ? FloatingActionButton(
              onPressed: _openAIChat,
              backgroundColor: _accentColor,
              foregroundColor: Colors.black,
              child: const Icon(Icons.smart_toy_outlined),
              tooltip: 'Ask AI about this movie',
            )
          : null,
    );
  }
}
