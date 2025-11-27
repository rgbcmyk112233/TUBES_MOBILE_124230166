import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/gemini_service.dart';

class AIChatPage extends StatefulWidget {
  final String movieTitle;
  final String initialMessage;

  const AIChatPage({
    Key? key,
    required this.movieTitle,
    required this.initialMessage,
  }) : super(key: key);

  @override
  _AIChatPageState createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final TextEditingController _messageController = TextEditingController();
  late GeminiService _geminiService;
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _initialMessageSent = false;
  bool _serviceInitialized = false;
  String _errorMessage = '';

  // Warna Tema Konsisten (Dark Mode)
  final Color _bgColor = const Color(0xFF121212);
  final Color _cardColor = const Color(0xFF1E1E1E); // Background Input
  final Color _aiBubbleColor = const Color(0xFF2C2C2C); // Bubble AI
  final Color _userBubbleColor = const Color(0xFFFFC107); // Bubble User (Amber)
  final Color _textColor = const Color(0xFFE0E0E0);

  @override
  void initState() {
    super.initState();
    _initializeGeminiService();
  }

  Future<void> _initializeGeminiService() async {
    try {
      // Load .env file
      await dotenv.load(fileName: "lib/key.env");

      // Get API key from .env
      final String? geminiApiKey = dotenv.env['GEMINI_API_KEY'];

      if (geminiApiKey == null ||
          geminiApiKey.isEmpty ||
          geminiApiKey == 'API_KEY') {
        throw Exception('KEY_NOT_FOUND');
      }

      // Initialize Gemini Service
      _geminiService = GeminiService(apiKey: geminiApiKey);

      setState(() {
        _serviceInitialized = true;
      });

      // Send initial message after service is initialized
      _sendInitialMessage();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize AI service: $e';
        _serviceInitialized = false;
      });
    }
  }

  void _sendInitialMessage() async {
    if (_initialMessageSent || !_serviceInitialized) return;

    setState(() {
      _isLoading = true;
      _initialMessageSent = true;
    });

    try {
      final response = await _geminiService.getMovieExplanation(
        widget.movieTitle,
      );

      setState(() {
        _messages.add(
          ChatMessage(text: response, isUser: false, timestamp: DateTime.now()),
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: 'Maaf, terjadi error: $e',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || !_serviceInitialized) return;

    // Add user message
    setState(() {
      _messages.add(
        ChatMessage(text: message, isUser: true, timestamp: DateTime.now()),
      );
      _messageController.clear();
      _isLoading = true;
    });

    try {
      final response = await _geminiService.sendMessage('''
Tentang film "${widget.movieTitle}": $message

Ingat: Hanya bahas tentang film "${widget.movieTitle}" dan hal yang terkait. Jangan menjawab pertanyaan di luar konteks film ini.
''');

      setState(() {
        _messages.add(
          ChatMessage(text: response, isUser: false, timestamp: DateTime.now()),
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: 'Maaf, terjadi error: $e',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            const Text(
              'AI Service Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _initializeGeminiService,
              style: ElevatedButton.styleFrom(
                backgroundColor: _userBubbleColor,
                foregroundColor: Colors.black,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.end, // Align to bottom for avatars
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          // AI Avatar
          if (!message.isUser)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                backgroundColor: Colors.grey[800],
                radius: 16,
                child: Icon(Icons.smart_toy, color: _userBubbleColor, size: 18),
              ),
            ),

          // Message Bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser ? _userBubbleColor : _aiBubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: message.isUser
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: message.isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: message.isUser ? Colors.black87 : _textColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 10,
                        color: message.isUser
                            ? Colors.black54
                            : Colors.grey[500],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // User Avatar
          if (message.isUser)
            Container(
              margin: const EdgeInsets.only(left: 8),
              child: CircleAvatar(
                backgroundColor: Colors.grey[800],
                radius: 16,
                child: const Icon(Icons.person, color: Colors.white, size: 18),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey[800],
            radius: 16,
            child: Icon(Icons.smart_toy, color: _userBubbleColor, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _aiBubbleColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(_userBubbleColor),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'AI is thinking...',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBody() {
    if (!_serviceInitialized && _errorMessage.isNotEmpty) {
      return _buildErrorWidget();
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _messages.length) {
          return _buildMessage(_messages[index]);
        } else {
          return _buildLoadingIndicator();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Assistant',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Discussing: ${widget.movieTitle}',
              style: TextStyle(
                fontSize: 12,
                color: _userBubbleColor,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Information Banner (Styled)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: _cardColor,
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[500], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI focus on "${widget.movieTitle}" only.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ),
              ],
            ),
          ),

          // Chat Messages
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildChatBody(),
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardColor,
              border: Border(top: BorderSide(color: Colors.grey[900]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: _serviceInitialized,
                    style: TextStyle(color: _textColor),
                    cursorColor: _userBubbleColor,
                    decoration: InputDecoration(
                      hintText: _serviceInitialized
                          ? 'Ask about the movie...'
                          : 'Connecting to AI...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: _bgColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: _serviceInitialized
                        ? _userBubbleColor
                        : Colors.grey[800],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.send_rounded,
                      color: _serviceInitialized
                          ? Colors.black
                          : Colors.grey[500],
                      size: 20,
                    ),
                    onPressed: _serviceInitialized ? _sendMessage : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
