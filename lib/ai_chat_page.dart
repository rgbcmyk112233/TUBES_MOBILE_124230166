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

  @override
  void initState() {
    super.initState();
    _initializeGeminiService();
  }

  Future<void> _initializeGeminiService() async {
    try {
      // Load .env file
      await dotenv.load(fileName: ".env");

      // Get API key from .env
      final String? geminiApiKey = dotenv.env['GEMINI_API_KEY'];

      if (geminiApiKey == null ||
          geminiApiKey.isEmpty ||
          geminiApiKey == 'your_actual_gemini_api_key_here') {
        throw Exception('GEMINI_API_KEY not found in .env file');
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
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'AI Service Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
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
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser)
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
          if (!message.isUser) const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Card(
                  color: message.isUser ? Colors.blue[50] : Colors.grey[100],
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      message.text,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
          if (message.isUser)
            CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue,
            child: Icon(Icons.smart_toy, color: Colors.white, size: 20),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('AI sedang mengetik...'),
                  ],
                ),
              ),
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
      reverse: false,
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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Diskusi Film dengan AI'),
            Text(
              widget.movieTitle,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Chat Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue[700], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI akan membantu Anda berdiskusi tentang film "${widget.movieTitle}"',
                    style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                  ),
                ),
              ],
            ),
          ),

          // Chat Messages
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildChatBody(),
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: _serviceInitialized,
                    decoration: InputDecoration(
                      hintText: _serviceInitialized
                          ? 'Tanyakan tentang film...'
                          : 'AI service sedang dimuat...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: _serviceInitialized
                      ? Colors.blue
                      : Colors.grey,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
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
