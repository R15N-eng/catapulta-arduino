import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../controllers/catapult_controller.dart';
import 'devices_page.dart';

class HomePage extends StatefulWidget {
  final CatapultController controller;

  const HomePage({super.key, required this.controller});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  late TextEditingController _distanciaController;

  int _distanciaCm = 200;
  bool _isSending = false;
  String _sendingLabel = '';

  static const neonBlue = Color(0xFF00BFFF);
  static const neonPurple = Color(0xFF1A5F8A);
  static const darkSurface = Color(0xFF0D1117);
  
  @override
  void initState() {
    super.initState();
    // _controller já vem pelo widget, não criar aqui

    _distanciaController = TextEditingController(text: '$_distanciaCm');

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

@override
  void dispose() {
    _glowController.dispose();
    _distanciaController.dispose();
    // sem disconnect aqui
    super.dispose();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? Colors.redAccent : neonBlue,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: isError
                ? Colors.redAccent.withOpacity(0.5)
                : neonBlue.withOpacity(0.5),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _checkAndRequestBluetooth() async {
    await [Permission.bluetoothScan, Permission.bluetoothConnect].request();
    final enabled = await widget.controller.isBluetoothEnabled();
    if (!enabled) {
      await widget.controller.requestBluetoothEnable();
    }
  }

  Future<void> _navigateToDevices() async {
    try {
      await _checkAndRequestBluetooth();
    } catch (e) {
      _showSnackBar('Erro ao ativar Bluetooth: ${e.toString()}', isError: true);
      return;
    }
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DevicesPage(controller: widget.controller),
      ),
    );
    if (result == true) {
      setState(() {});
      _showSnackBar('HC-05 conectado com sucesso!');
    }
  }

  Future<void> _executeCommand(
    String label,
    Future<void> Function() command,
  ) async {
    if (!widget.controller.isConnected) {
      _showSnackBar(
        'Sem conexão. Conecte ao HC-05 primeiro.',
        isError: true,
      );
      return;
    }
    setState(() {
      _isSending = true;
      _sendingLabel = label;
    });
    try {
      await command();
      _showSnackBar('$label executado!');
    } catch (e) {
      _showSnackBar('Erro: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isSending = false);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildConnectionCard(),
                  const SizedBox(height: 28),
                  _buildMechanicalVisual(),
                  const SizedBox(height: 28),
                  _buildDistanciaSection(),
                  const SizedBox(height: 32),
                  _buildCommandButtons(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Background ────────────────────────────────────────────────────────────

  Widget _buildBackground() {
    return SizedBox.expand(
      child: CustomPaint(
        painter: _GridPainter(),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildLogoIcon() {
    return ClipOval(
      child: Image.asset(
        'assets/icon/leviathan_icon.png',
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF00BFFF),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLogoIcon(),
                const SizedBox(width: 12),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [neonBlue, neonPurple],
                  ).createShader(bounds),
                  child: const Text(
                    'LEVIATHAN',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'SISTEMA DE CONTROLE v1.0',
              style: TextStyle(
                fontSize: 11,
                color: neonBlue.withOpacity(0.6),
                letterSpacing: 4,
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Connection Card ───────────────────────────────────────────────────────

  Widget _buildConnectionCard() {
    final connected = widget.controller.isConnected;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: connected
              ? neonBlue.withOpacity(0.6)
              : neonPurple.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: connected
                ? neonBlue.withOpacity(0.1)
                : neonPurple.withOpacity(0.05),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, _) {
              return Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: connected ? neonBlue : neonPurple,
                  boxShadow: [
                    BoxShadow(
                      color: (connected ? neonBlue : neonPurple)
                          .withOpacity(_glowAnimation.value),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              connected ? 'HC-05 CONECTADO' : 'SEM CONEXÃO',
              style: TextStyle(
                color: connected ? neonBlue : neonPurple,
                letterSpacing: 2,
                fontSize: 12,
              ),
            ),
          ),
          GestureDetector(
            onTap: _navigateToDevices,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: neonBlue.withOpacity(0.5),
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                connected ? 'TROCAR' : 'CONECTAR',
                style: const TextStyle(
                  color: neonBlue,
                  fontSize: 11,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Mechanical Visual ─────────────────────────────────────────────────────

  Widget _buildMechanicalVisual() {
    final progress = (_distanciaCm - 50) / 350;
    return SizedBox(
      height: 160,
      child: CustomPaint(
        painter: _CatapultPainter(
          progress: progress.clamp(0.0, 1.0),
          glowOpacity: _glowAnimation.value,
        ),
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, _) => const SizedBox.expand(),
        ),
      ),
    );
  }

  // ─── Distância Section ─────────────────────────────────────────────────────

  Widget _buildDistanciaSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: neonBlue.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'DISTÂNCIA',
            style: TextStyle(
              color: neonBlue.withOpacity(0.7),
              fontSize: 11,
              letterSpacing: 3,
            ),
          ),
          SizedBox(
            width: 160,
            child: TextField(
              controller: _distanciaController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 42,
                color: neonBlue,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: neonBlue.withOpacity(0.6),
                    blurRadius: 12,
                  ),
                ],
              ),
              decoration: InputDecoration(
                suffix: Text(
                  'cm',
                  style: TextStyle(
                    fontSize: 14,
                    color: neonBlue.withOpacity(0.7),
                  ),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: '50–400',
                hintStyle: TextStyle(
                  fontSize: 20,
                  color: neonBlue.withOpacity(0.3),
                ),
              ),
              onChanged: (text) {
                final parsed = int.tryParse(text);
                if (parsed != null) {
                  setState(() {
                    _distanciaCm = parsed.clamp(50, 400);
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Command Buttons ───────────────────────────────────────────────────────

  Widget _buildCommandButtons() {
    return Column(
      children: [
        _buildGlowButton(
          label: 'CARREGAR',
          icon: Icons.compress,
          color: neonBlue,
          isSending: _isSending && _sendingLabel == 'CARREGAR',
          onTap: () => _executeCommand(
            'CARREGAR',
            () => widget.controller.carregar(_distanciaCm),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildGlowButton(
                label: 'LANÇAR',
                icon: Icons.rocket_launch,
                color: neonPurple,
                isSending: _isSending && _sendingLabel == 'LANÇAR',
                onTap: () => _executeCommand(
                  'LANÇAR',
                  () => widget.controller.lancar(),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildGlowButton(
                label: 'TRAVAR',
                icon: Icons.lock_outline,
                color: Colors.orangeAccent,
                isSending: _isSending && _sendingLabel == 'TRAVAR',
                onTap: () => _executeCommand(
                  'TRAVAR',
                  () => widget.controller.travar(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGlowButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSending,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, _) {
        return GestureDetector(
          onTap: _isSending ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: isSending ? color.withOpacity(0.15) : darkSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(isSending ? 1.0 : 0.5),
                width: isSending ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(
                    isSending ? _glowAnimation.value * 0.5 : 0.1,
                  ),
                  blurRadius: isSending ? 20 : 8,
                  spreadRadius: isSending ? 2 : 0,
                ),
              ],
            ),
            child: isSending
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'ENVIANDO...',
                        style: TextStyle(
                          color: color,
                          letterSpacing: 2,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: color, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: TextStyle(
                          color: color,
                          letterSpacing: 3,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

// ─── Custom Painters ──────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00BFFF).withOpacity(0.03)
      ..strokeWidth = 0.5;

    const spacing = 30.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CatapultPainter extends CustomPainter {
  final double progress;
  final double glowOpacity;

  _CatapultPainter({required this.progress, required this.glowOpacity});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.75;

    final basePaint = Paint()
      ..color = const Color(0xFF00BFFF).withOpacity(0.6)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = const Color(0xFF00BFFF).withOpacity(glowOpacity * 0.3)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final accentPaint = Paint()
      ..color = const Color(0xFF1A5F8A).withOpacity(0.7)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(cx - 80, cy), Offset(cx + 80, cy), basePaint);

    canvas.drawCircle(Offset(cx - 60, cy + 12), 10, basePaint);
    canvas.drawCircle(Offset(cx + 60, cy + 12), 10, basePaint);

    canvas.drawLine(Offset(cx, cy), Offset(cx, cy - 20), basePaint);

    final armAngle = -1.2 + (progress * 1.8);
    const armLength = 70.0;
    final armEndX = cx + armLength * (armAngle > 0 ? armAngle * 0.5 : armAngle);
    final armEndY = cy - 20 - armLength * (1 - progress * 0.4);

    canvas.drawLine(Offset(cx, cy - 20), Offset(armEndX, armEndY), glowPaint);
    canvas.drawLine(Offset(cx, cy - 20), Offset(armEndX, armEndY), basePaint);

    canvas.drawCircle(Offset(armEndX, armEndY), 8, accentPaint);

    final weightX = cx - (armEndX - cx) * 0.4;
    final weightY = cy - 20 + (armEndY - (cy - 20)) * 0.3 + 20;

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(weightX, weightY),
        width: 16,
        height: 16,
      ),
      accentPaint,
    );

    canvas.drawLine(
      Offset(armEndX, armEndY),
      Offset(armEndX + 10, armEndY + 20),
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CatapultPainter old) =>
      old.progress != progress || old.glowOpacity != glowOpacity;
}