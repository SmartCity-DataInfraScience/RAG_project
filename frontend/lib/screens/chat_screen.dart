import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  String? _typingText;

  Future<void> sendQuestion(String question) async {
    setState(() {
      _isLoading = true;
      _messages.add({"role": "user", "text": question});
    });

    final url = Uri.parse('http://172.24.243.61:8000/chat');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "question": question,
          "history": _messages.map((msg) => msg['text'] ?? "").toList(),
          "top_k": 5
        }),
      );

      final responseData = json.decode(response.body);
      final fullAnswer = responseData['answer'] ?? "❗ Null response";

      await _animateBotReply(fullAnswer);
    } catch (e) {
      setState(() {
        _messages.add({"role": "bot", "text": "❗ Error occurred: $e"});
      });
    }

    setState(() {
      _isLoading = false;
      _controller.clear();
    });
  }

  Future<void> _animateBotReply(String fullText) async {
    const delay = Duration(milliseconds: 20);
    String displayText = "";

    for (int i = 0; i < fullText.length; i++) {
      displayText += fullText[i];
      setState(() {
        _typingText = displayText;
      });
      await Future.delayed(delay);
    }

    setState(() {
      _messages.add({"role": "bot", "text": displayText});
      _typingText = null;
    });
  }

  Future<void> clearChat() async {
    try {
      await http.post(
        Uri.parse('http://172.24.243.61:8000/clear_chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"session_id": "user1"}),
      );
    } catch (_) {}

    setState(() {
      _messages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text("CREX.AI", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF111428),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Clear Chat',
            onPressed: clearChat,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          const Text(
            "What would you like to know today?",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _messages.length + (_typingText != null ? 1 : 0),
              itemBuilder: (context, index) {
                if (_typingText != null && index == _messages.length) {
                  return _buildBotMessage(_typingText!);
                }
                final msg = _messages[index];
                final isUser = msg["role"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 300),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[300] : Colors.grey[800],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: Radius.circular(isUser ? 12 : 0),
                        bottomRight: Radius.circular(isUser ? 0 : 12),
                      ),
                    ),
                    child: Text(
                      msg["text"] ?? "",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    minLines: 1,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: "Ask me anything...",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.lightBlueAccent),
                  onPressed: _isLoading
                      ? null
                      : () {
                          final question = _controller.text.trim();
                          if (question.isNotEmpty) {
                            sendQuestion(question);
                          }
                        },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotMessage(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
