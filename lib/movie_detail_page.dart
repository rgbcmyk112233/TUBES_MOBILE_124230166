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
        const SnackBar(
          content: Text('Komentar berhasil ditambahkan'),
          backgroundColor: Colors.green,
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

  Widget _buildComment(Comment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ), // Added horizontal padding
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
              image: comment.userPhoto != null && comment.userPhoto!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(comment.userPhoto!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: comment.userPhoto == null || comment.userPhoto!.isEmpty
                ? const Icon(Icons.person, size: 20, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 12),

          // Comment Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info and Time
                  Row(
                    children: [
                      Text(
                        comment.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87,
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
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
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
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ), // Added horizontal padding
          child: const Text(
            'Komentar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Comment Input (only if user is logged in)
        if (widget.user != null) ...[
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 16,
            ), // Added horizontal margin
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Tulis komentar tentang film ini...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[400]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                    hintStyle: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isPostingComment ? null : _postComment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: _isPostingComment
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Post Komentar',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ] else ...[
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 16,
            ), // Added horizontal margin
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Login untuk menambahkan komentar',
                    style: TextStyle(color: Colors.orange[800], fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Comments List
        if (_isLoadingComments)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text(
                    'Memuat komentar...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else if (_comments.isEmpty)
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 16,
            ), // Added horizontal margin
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: const Column(
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'Belum ada komentar',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Jadilah yang pertama berkomentar!',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          )
        else
          Column(children: _comments.map(_buildComment).toList()),
      ],
    );
  }

  Widget _buildPosterSection() {
    return Container(
      width: double.infinity,
      height: 400,
      child: Stack(
        children: [
          // Background Poster
          _movie?.poster != null && _movie!.poster != 'N/A'
              ? Image.network(
                  _movie!.poster,
                  width: double.infinity,
                  height: 400,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholderPoster();
                  },
                )
              : _buildPlaceholderPoster(),

          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
              ),
            ),
          ),

          // Movie Info Overlay
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _movie?.title ?? 'Loading...',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (_movie?.year != null) ...[
                      _buildInfoChip(_movie!.year),
                      const SizedBox(width: 8),
                    ],
                    if (_movie?.rated != null && _movie!.rated != 'N/A') ...[
                      _buildInfoChip(_movie!.rated),
                      const SizedBox(width: 8),
                    ],
                    if (_movie?.runtime != null && _movie!.runtime != 'N/A')
                      _buildInfoChip(_movie!.runtime),
                  ],
                ),
                const SizedBox(height: 8),
                if (_movie?.imdbRating != null && _movie!.imdbRating != 'N/A')
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${_movie!.imdbRating}/10',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_movie?.imdbVotes != null &&
                          _movie!.imdbVotes != 'N/A')
                        Text(
                          '(${_movie!.imdbVotes} votes)',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderPoster() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie, size: 60, color: Colors.grey),
            SizedBox(height: 8),
            Text('No Image Available', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value != 'N/A' ? value : 'Not available',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingChip(Rating rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rating.source,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            rating.value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_movie == null) return Container();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Genre
          if (_movie!.genre != 'N/A')
            Wrap(
              children: _movie!.genre.split(', ').map((genre) {
                return Container(
                  margin: const EdgeInsets.only(right: 8, bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    genre,
                    style: TextStyle(color: Colors.green[800], fontSize: 12),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 20),

          // Plot
          if (_movie!.plot != 'N/A') ...[
            const Text(
              'Plot',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _movie!.plot,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),
          ],

          // Movie Details
          const Text(
            'Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Released', _movie!.released),
          _buildInfoRow('Director', _movie!.director),
          _buildInfoRow('Writer', _movie!.writer),
          _buildInfoRow('Actors', _movie!.actors),
          _buildInfoRow('Language', _movie!.language),
          _buildInfoRow('Country', _movie!.country),

          const SizedBox(height: 20),

          // Ratings
          if (_movie!.ratings.isNotEmpty) ...[
            const Text(
              'Ratings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            const Text(
              'Awards',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_movie!.awards),
            const SizedBox(height: 20),
          ],

          // Box Office
          if (_movie!.boxOffice != 'N/A') ...[
            const Text(
              'Box Office',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_movie!.boxOffice),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movie Details'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading movie details...'),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load movie',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loadMovieDetails,
                    child: const Text('Try Again'),
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
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: _movie != null
          ? FloatingActionButton(
              onPressed: _openAIChat,
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.smart_toy, size: 20),
                  SizedBox(height: 2),
                  Text('AI', style: TextStyle(fontSize: 10)),
                ],
              ),
              tooltip: 'Diskusi dengan AI tentang film ini',
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
