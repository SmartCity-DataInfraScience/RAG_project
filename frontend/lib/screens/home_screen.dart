import 'package:flutter/material.dart';
import 'chat_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ✅ 이미지 비율 유지하면서 전체 배경으로 넣기 (너무 확대되지 않게 조절)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.fitHeight, // 화면 높이에 맞추되 과도하게 확대되지 않음
              alignment: Alignment.center,
              child: Image.asset(
                'assets/crex_home_bg.png',
              ),
            ),
          ),

          // ✅ Start 버튼 위치 조정
          Positioned(
            bottom: 100, // 조금 위로 올림
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: const BorderSide(color: Colors.white),
                  ),
                ),
                child: const Text(
                  "Start",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
