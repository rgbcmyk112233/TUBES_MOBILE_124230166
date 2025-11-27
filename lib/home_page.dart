import 'package:flutter/material.dart';
import '../sqlite/user_model.dart';
import '../services/movie_service.dart';
import '../models/movie_model.dart';
import './movie_detail_page.dart';
import 'about_page.dart';
import 'history_page.dart';

class HomePage extends StatefulWidget {
  final User user;

  const HomePage({Key? key, required this.user}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MovieService _movieService = MovieService();
  final TextEditingController _searchController = TextEditingController();

  int _currentIndex = 0;
  List<Movie> _movies = [];
  List<Movie> _filteredMovies = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  String _currentSearch = 'spiderman';

  // Warna Tema (Hardcoded untuk Permanent Dark Mode)
  final Color _bgColor = const Color(0xFF121212);
  final Color _cardColor = const Color(0xFF1E1E1E);
  final Color _accentColor = const Color(0xFFFFC107); // Amber/Gold untuk rating
  final Color _textColor = const Color(0xFFE0E0E0);
  final Color _subTextColor = const Color(0xFFB0B0B0);

  final List<String> _pageTitles = [
    'Discover Movies', // Ubah judul jadi lebih menarik
    'Comment History',
    'My Profile',
  ];

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final movies = await _movieService.searchMovies(_currentSearch);
      if (!mounted) return;
      setState(() {
        _movies = movies;
        _filteredMovies = movies;
        _isLoading = false;
      });
    } catch (e, s) {
      if (!mounted) return;
      print('--- ERROR Load Movies ---');
      print(e);
      print(s);
      print('---------------------------');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _searchMovies(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMovies = _movies;
      } else {
        _filteredMovies = _movies
            .where(
              (movie) =>
                  movie.title.toLowerCase().contains(query.toLowerCase()) ||
                  movie.year.toLowerCase().contains(query.toLowerCase()) ||
                  movie.actors.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  Future<void> _searchNewMovies(String query) async {
    if (query.isEmpty) {
      _currentSearch = 'spiderman';
      await _loadMovies();
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
      _currentSearch = query;
    });

    try {
      final movies = await _movieService.searchMovies(query);
      if (!mounted) return;
      setState(() {
        _movies = movies;
        _filteredMovies = movies;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _navigateToMovieDetail(Movie movie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MovieDetailPage(imdbId: movie.imdbId, user: widget.user),
      ),
    );
  }

  // ========== MOVIE SEARCH PAGE (MODIFIED UI) ==========
  Widget _buildMovieCard(Movie movie) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToMovieDetail(movie),
          borderRadius: BorderRadius.circular(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster Image (Left Side)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: Container(
                  width: 110,
                  height: 160,
                  color: Colors.grey[900],
                  child:
                      movie.imagePoster.isNotEmpty && movie.imagePoster != 'N/A'
                      ? Image.network(
                          movie.imagePoster,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholderImage(),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                color: _accentColor,
                                strokeWidth: 2,
                              ),
                            );
                          },
                        )
                      : _buildPlaceholderImage(),
                ),
              ),

              // Movie Info (Right Side)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Rating Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _accentColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, size: 14, color: _accentColor),
                            const SizedBox(width: 4),
                            Text(
                              movie.formattedRating,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Title
                      Text(
                        movie.title.isNotEmpty
                            ? movie.title
                            : 'No Title Available',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _textColor,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Year
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: _subTextColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            movie.year.isNotEmpty ? movie.year : 'Unknown',
                            style: TextStyle(
                              fontSize: 13,
                              color: _subTextColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Actors
                      Text(
                        'Cast: ${movie.actors.isNotEmpty ? movie.actors : 'Unknown'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.movie_creation_outlined,
            size: 30,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 4),
          Text(
            'No Image',
            style: TextStyle(color: Colors.grey[700], fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C), // Dark Grey search bar
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: _textColor),
        decoration: InputDecoration(
          hintText: 'Search movies...',
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[500]),
                  onPressed: () {
                    _searchController.clear();
                    _searchMovies('');
                    _currentSearch = 'spiderman';
                    _loadMovies();
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
        ),
        onChanged: _searchMovies,
        onSubmitted: _searchNewMovies,
      ),
    );
  }

  Widget _buildMovieSearchBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _accentColor),
            const SizedBox(height: 16),
            Text(
              'Finding movies...',
              style: TextStyle(fontSize: 16, color: _subTextColor),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                'Failed to load movies',
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
                style: TextStyle(color: _subTextColor, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadMovies,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.black, // Hitam di atas Amber
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredMovies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[800]),
            const SizedBox(height: 16),
            Text(
              'No movies found',
              style: TextStyle(fontSize: 18, color: _subTextColor),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                _currentSearch = 'spiderman';
                _loadMovies();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _cardColor,
                foregroundColor: _accentColor,
                side: BorderSide(color: _accentColor),
              ),
              child: const Text('Back to Popular'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMovies,
      color: _accentColor,
      backgroundColor: _cardColor,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _filteredMovies.length + 1, // +1 untuk Header Recommendation
        itemBuilder: (context, index) {
          if (index == 0) {
            // Ini Header Buatan agar terlihat seperti "Rekomendasi"
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
              child: Text(
                "Recommended for you",
                style: TextStyle(
                  color: _textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }
          final movie = _filteredMovies[index - 1];
          return _buildMovieCard(movie);
        },
      ),
    );
  }

  Widget _buildMovieSearchPage() {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(child: _buildMovieSearchBody()),
      ],
    );
  }

  // ========== BOTTOM NAVIGATION BAR (MODIFIED) ==========
  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildMovieSearchPage(),
      HistoryPage(user: widget.user),
      AboutPage(user: widget.user),
    ];

    return Scaffold(
      backgroundColor: _bgColor, // Background utama hitam
      appBar: AppBar(
        title: Text(
          _pageTitles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _bgColor, // AppBar menyatu dengan background
        foregroundColor: _textColor,
        elevation: 0, // Hilangkan shadow agar terlihat flat modern
        centerTitle: true,
      ),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey[900]!, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.movie_outlined),
              activeIcon: Icon(Icons.movie),
              label: 'Movies',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          backgroundColor: _bgColor, // Bottom Nav hitam
          selectedItemColor: _accentColor, // Icon aktif warna Amber
          unselectedItemColor: Colors.grey[600], // Icon mati warna abu gelap
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
      ),
    );
  }
}
