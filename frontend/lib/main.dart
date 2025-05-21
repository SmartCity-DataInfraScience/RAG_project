import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ChatScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  Future<void> sendQuestion(String question) async {
    setState(() {
      _isLoading = true;
      _messages.add({"role": "user", "text": question});
    });

    final url = Uri.parse('http://172.20.10.6:8000/chat');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"question": question, "history": [], "top_k": 5}),
      );

      final responseData = json.decode(response.body);
      final answer = responseData['answer'];

      setState(() {
        _messages.add({"role": "bot", "text": answer});
      });
    } catch (e) {
      setState(() {
        _messages.add({"role": "bot", "text": "❗오류 발생: $e"});
      });
    }

    setState(() {
      _isLoading = false;
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("건설안전 챗봇")),
      body: Column(
        children: [
          const SizedBox(height: 10),
          const Text("오늘은 무슨 생각을 하고 계신가요?", style: TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["role"] == "user";
                return ListTile(
                  leading: isUser ? null : const Icon(Icons.smart_toy),
                  trailing: isUser ? const Icon(Icons.person) : null,
                  title: Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.blue[100] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(msg["text"] ?? ""),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) const CircularProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "무엇이든 물어보세요",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
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
}
