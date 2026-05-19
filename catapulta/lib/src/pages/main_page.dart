import 'package:flutter/material.dart';
import '../controllers/catapult_controller.dart';
import '../services/bluetooth_service.dart';
import 'home_page.dart';
import 'calibracao_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  late final CatapultController _controller;

  static const neonBlue = Color(0xFF00BFFF);
  static const neonPurple = Color(0xFF1A5F8A);

  @override
  void initState() {
    super.initState();
    _controller = CatapultController(BluetoothService());
  }

  @override
  void dispose() {
    _controller.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomePage(controller: _controller),
          CalibracaoPage(controller: _controller),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF050508),
          border: Border(
            top: BorderSide(color: neonBlue.withOpacity(0.2)),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: neonBlue,
          unselectedItemColor: neonPurple.withOpacity(0.4),
          selectedLabelStyle: const TextStyle(
            letterSpacing: 2,
            fontSize: 10,
          ),
          unselectedLabelStyle: const TextStyle(
            letterSpacing: 2,
            fontSize: 10,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.sports_baseball_outlined),
              activeIcon: Icon(Icons.sports_baseball),
              label: 'CONTROLO',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.science_outlined),
              activeIcon: Icon(Icons.science),
              label: 'CALIBRAÇÃO',
            ),
          ],
        ),
      ),
    );
  }
}