import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../controllers/catapult_controller.dart';
import 'devices_page.dart';

class CalibracaoPage extends StatefulWidget {
  final CatapultController controller;

  const CalibracaoPage({super.key, required this.controller});

  @override
  State<CalibracaoPage> createState() => _CalibracaoPageState();
}

class _CalibracaoPageState extends State<CalibracaoPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  late TextEditingController _passosController;

  bool _isSending = false;
  String _sendingLabel = '';

  static const neonBlue = Color(0xFF00BFFF);
  static const neonPurple = Color(0xFF1A5F8A);
  static const neonGreen = Color(0xFF1E90FF);
  static const darkSurface = Color(0xFF0D1117);

  @override
  void initState() {
    super.initState();
    _passosController = TextEditingController(text: '1024');

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
    _passosController.dispose();
    super.dispose();
  }

  int get _passos {
    final parsed = int.tryParse(_passosController.text);
    if (parsed == null || parsed < 0) return 0;
    return parsed;
  }

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

  Future<void> _navigateToDevices() async {
    await [Permission.bluetoothScan, Permission.bluetoothConnect].request();
    try {
      final enabled = await widget.controller.isBluetoothEnabled();
      if (!enabled) await widget.controller.requestBluetoothEnable();
    } catch (e) {
      if (mounted) _showSnackBar('Erro ao ativar Bluetooth: ${e.toString()}', isError: true);
      return;
    }

    if (!mounted) return;
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
      _showSnackBar('Sem conexão. Conecte ao HC-05 primeiro.', isError: true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(child: CustomPaint(painter: _GridPainter())),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildConnectionCard(),
                  const SizedBox(height: 28),
                  _buildAviso(),
                  const SizedBox(height: 28),
                  _buildPassosInput(),
                  const SizedBox(height: 32),
                  _buildBotoes(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
                colors: [neonGreen, neonBlue],
              ).createShader(bounds),
              child: const Text(
                'CALIBRAÇÃO',
                style: TextStyle(
                  fontSize: 32,
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
          'MODO DE TESTES — PASSOS MANUAIS',
          style: TextStyle(
            fontSize: 11,
            color: neonGreen.withOpacity(0.6),
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }

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
        ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: neonBlue.withOpacity(0.5)),
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

  Widget _buildAviso() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: neonGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: neonGreen.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: neonGreen.withOpacity(0.7), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Neste modo o motor 1 gira exatamente o número de passos inserido. Use para aferir a relação passos → distância e preencher a tabela de calibração.',
              style: TextStyle(
                color: neonGreen.withOpacity(0.7),
                fontSize: 11,
                letterSpacing: 0.5,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassosInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: neonGreen.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'PASSOS',
            style: TextStyle(
              color: neonGreen.withOpacity(0.7),
              fontSize: 11,
              letterSpacing: 3,
            ),
          ),
          SizedBox(
            width: 180,
            child: TextField(
              controller: _passosController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 42,
                color: neonGreen,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: neonGreen.withOpacity(0.6),
                    blurRadius: 12,
                  ),
                ],
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: '0',
                hintStyle: TextStyle(
                  fontSize: 42,
                  color: neonGreen.withOpacity(0.3),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotoes() {
    return Column(
      children: [
        _buildGlowButton(
          label: 'CARREGAR',
          icon: Icons.compress,
          color: neonGreen,
          isSending: _isSending && _sendingLabel == 'CARREGAR',
          onTap: () => _executeCommand(
            'CARREGAR',
            () => widget.controller.testar(_passos),
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

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E90FF).withOpacity(0.02)
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