import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

// ============================================================
//  CATAPULTA ESP32 — App Flutter
//  Paleta: #0F2A1D · #375534 · #6B9071 · #AEC3B0 · #E3EED4
// ============================================================

void main() {
  runApp(const CatapultaApp());
}

// ── Cores da paleta ─────────────────────────────────────────
class AppColors {
  static const g1 = Color(0xFF0F2A1D);
  static const g2 = Color(0xFF375534);
  static const g3 = Color(0xFF6B9071);
  static const g4 = Color(0xFFAEC3B0);
  static const g5 = Color(0xFFE3EED4);
  static const white = Color(0xFFFFFFFF);
  static const error = Color(0xFFB91C1C);
  static const errorBg = Color(0xFFFEF2F2);
}

// ── Enum de estados da máquina ───────────────────────────────
enum CatapultaEstado {
  repouso,
  travado,
  esticando,
  lancando,
  resetando,
}

extension EstadoInfo on CatapultaEstado {
  String get titulo {
    switch (this) {
      case CatapultaEstado.repouso:   return 'Pronto para travar';
      case CatapultaEstado.travado:   return 'Travado — encaixe o elástico';
      case CatapultaEstado.esticando: return 'Esticando...';
      case CatapultaEstado.lancando:  return 'Lançando!';
      case CatapultaEstado.resetando: return 'Resetando posição';
    }
  }

  String get subtitulo {
    switch (this) {
      case CatapultaEstado.repouso:   return 'Posicione o braço na horizontal';
      case CatapultaEstado.travado:   return 'Defina a distância e toque em Lançar';
      case CatapultaEstado.esticando: return 'Motor B girando até o ângulo calculado';
      case CatapultaEstado.lancando:  return 'Motor A soltando o braço...';
      case CatapultaEstado.resetando: return 'Voltando à posição inicial';
    }
  }

  String get icone {
    switch (this) {
      case CatapultaEstado.repouso:   return '🔒';
      case CatapultaEstado.travado:   return '🎯';
      case CatapultaEstado.esticando: return '⚡';
      case CatapultaEstado.lancando:  return '🚀';
      case CatapultaEstado.resetando: return '🔄';
    }
  }

  int get indice {
    return CatapultaEstado.values.indexOf(this);
  }
}

// ── Enum de modo de conexão ──────────────────────────────────
enum ModoConexao { bluetooth, wifi }

// ============================================================
//  App root
// ============================================================
class CatapultaApp extends StatelessWidget {
  const CatapultaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catapulta ESP32',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: AppColors.g5,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.g2,
          background: AppColors.g5,
        ),
      ),
      home: const TelaHome(),
    );
  }
}

// ============================================================
//  Tela principal
// ============================================================
class TelaHome extends StatefulWidget {
  const TelaHome({super.key});

  @override
  State<TelaHome> createState() => _TelaHomeState();
}

class _TelaHomeState extends State<TelaHome> {
  // Conexão
  ModoConexao _modo = ModoConexao.bluetooth;
  bool _conectado = false;
  String _enderecoWifi = '';
  final int _portaWifi = 8080;

  // Bluetooth
  BluetoothConnection? _btConexao;
  List<BluetoothDevice> _dispositivosBt = [];

  // Wi-Fi
  Socket? _wifiSocket;

  // Estado da catapulta
  CatapultaEstado _estado = CatapultaEstado.repouso;

  // Distância
  double _distanciaCm = 100;
  final TextEditingController _distCtrl = TextEditingController(text: '100');

  // Log de mensagens
  final List<String> _log = [];

  @override
  void dispose() {
    _btConexao?.dispose();
    _wifiSocket?.destroy();
    _distCtrl.dispose();
    super.dispose();
  }

  // ── Utilitários ─────────────────────────────────────────────

  void _addLog(String msg) {
    setState(() {
      _log.insert(0, '[${TimeOfDay.now().format(context)}] $msg');
      if (_log.length > 50) _log.removeLast();
    });
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _mostrarSucesso(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: AppColors.g1)),
        backgroundColor: AppColors.g4,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Envio de comandos ────────────────────────────────────────

  Future<void> _enviarComando(String cmd) async {
    if (!_conectado) {
      _mostrarErro('Não conectado ao ESP32');
      return;
    }
    try {
      final dados = '$cmd\n';
      if (_modo == ModoConexao.bluetooth && _btConexao != null) {
        _btConexao!.output.add(Uint8List.fromList(dados.codeUnits));
        await _btConexao!.output.allSent;
      } else if (_modo == ModoConexao.wifi && _wifiSocket != null) {
        _wifiSocket!.write(dados);
      }
      _addLog('→ $cmd');
    } catch (e) {
      _mostrarErro('Erro ao enviar: $e');
      _addLog('ERRO: $e');
    }
  }

  void _processarResposta(String resp) {
    _addLog('← $resp');
    setState(() {
      switch (resp.trim()) {
        case 'OK:TRAVADO':
          _estado = CatapultaEstado.travado;
          break;
        case 'OK:ESTICANDO':
          _estado = CatapultaEstado.esticando;
          break;
        case 'OK:LANCANDO':
          _estado = CatapultaEstado.lancando;
          break;
        case 'OK:RESETANDO':
          _estado = CatapultaEstado.resetando;
          break;
        case 'OK:PRONTO':
        case 'OK:RESET_EMERGENCIA':
          _estado = CatapultaEstado.repouso;
          _mostrarSucesso('Ciclo concluído — pronto para novo lançamento');
          break;
        default:
          if (resp.startsWith('ERRO:')) {
            _mostrarErro('ESP32: $resp');
          }
      }
    });
  }

  // ── Bluetooth ────────────────────────────────────────────────

  Future<void> _escanearBluetooth() async {
    // Solicita permissões
    final status = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();

    final negadas = status.values.where((s) => s.isDenied);
    if (negadas.isNotEmpty) {
      _mostrarErro('Permissões Bluetooth negadas');
      return;
    }

    try {
      final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      setState(() => _dispositivosBt = devices);

      if (devices.isEmpty) {
        _mostrarErro('Nenhum dispositivo pareado. Pareie o ESP32 nas configurações do Android.');
        return;
      }

      _mostrarDialogBluetooth();
    } catch (e) {
      _mostrarErro('Erro ao buscar dispositivos: $e');
    }
  }

  void _mostrarDialogBluetooth() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.g4,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Dispositivos pareados',
              style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.g1,
              ),
            ),
          ),
          ..._dispositivosBt.map((d) => ListTile(
            leading: const Icon(Icons.bluetooth, color: AppColors.g2),
            title: Text(d.name ?? 'Sem nome',
                style: const TextStyle(color: AppColors.g1, fontWeight: FontWeight.w500)),
            subtitle: Text(d.address,
                style: const TextStyle(color: AppColors.g3, fontSize: 12)),
            onTap: () {
              Navigator.pop(context);
              _conectarBluetooth(d);
            },
          )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _conectarBluetooth(BluetoothDevice device) async {
    _addLog('Conectando ao ${device.name}...');
    try {
      final conn = await BluetoothConnection.toAddress(device.address);
      setState(() {
        _btConexao = conn;
        _conectado = true;
      });
      _mostrarSucesso('Conectado a ${device.name}');
      _addLog('Conectado: ${device.name}');

      // Escuta respostas
      conn.input!.listen((dados) {
        final resp = String.fromCharCodes(dados);
        for (final linha in resp.split('\n')) {
          if (linha.trim().isNotEmpty) _processarResposta(linha);
        }
      }, onDone: () {
        setState(() => _conectado = false);
        _addLog('Desconectado');
      });
    } catch (e) {
      _mostrarErro('Falha na conexão Bluetooth: $e');
      _addLog('ERRO BT: $e');
    }
  }

  // ── Wi-Fi ────────────────────────────────────────────────────

  Future<void> _conectarWifi() async {
    if (_enderecoWifi.isEmpty) {
      _mostrarErro('Digite o IP do ESP32');
      return;
    }
    _addLog('Conectando ao $_enderecoWifi:$_portaWifi...');
    try {
      final socket = await Socket.connect(_enderecoWifi, _portaWifi)
          .timeout(const Duration(seconds: 5));
      setState(() {
        _wifiSocket = socket;
        _conectado = true;
      });
      _mostrarSucesso('Conectado via Wi-Fi');
      _addLog('Conectado: $_enderecoWifi');

      socket.listen(
        (dados) {
          final resp = String.fromCharCodes(dados);
          for (final linha in resp.split('\n')) {
            if (linha.trim().isNotEmpty) _processarResposta(linha);
          }
        },
        onDone: () {
          setState(() => _conectado = false);
          _addLog('Wi-Fi desconectado');
        },
        onError: (e) {
          setState(() => _conectado = false);
          _addLog('ERRO Wi-Fi: $e');
        },
      );
    } catch (e) {
      _mostrarErro('Falha na conexão Wi-Fi: $e');
      _addLog('ERRO WiFi: $e');
    }
  }

  void _mostrarDialogWifi() {
    final ipCtrl = TextEditingController(text: _enderecoWifi);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('IP do ESP32',
            style: TextStyle(color: AppColors.g1, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: ipCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '192.168.1.100',
            hintStyle: TextStyle(color: AppColors.g3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.g4),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.g2, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.g3)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.g1,
              foregroundColor: AppColors.g5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              setState(() => _enderecoWifi = ipCtrl.text.trim());
              Navigator.pop(context);
              _conectarWifi();
            },
            child: const Text('Conectar'),
          ),
        ],
      ),
    );
  }

  Future<void> _desconectar() async {
    _btConexao?.dispose();
    _wifiSocket?.destroy();
    setState(() {
      _btConexao = null;
      _wifiSocket = null;
      _conectado = false;
      _estado = CatapultaEstado.repouso;
    });
    _addLog('Desconectado');
  }

  // ── Ações da catapulta ───────────────────────────────────────

  Future<void> _travar() async {
    if (_estado != CatapultaEstado.repouso) return;
    await _enviarComando('TRAVAR');
  }

  Future<void> _lancar() async {
    if (_estado != CatapultaEstado.travado) return;
    final dist = _distanciaCm.round();
    if (dist < 50 || dist > 400) {
      _mostrarErro('Distância deve ser entre 50 e 400 cm');
      return;
    }
    await _enviarComando('LANCAR:$dist');
  }

  Future<void> _resetEmergencia() async {
    await _enviarComando('RESET');
  }

  // ============================================================
  //  BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.g5,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    _buildCardConexao(),
                    const SizedBox(height: 12),
                    _buildCardDistancia(),
                    const SizedBox(height: 12),
                    _buildCardEstado(),
                    const SizedBox(height: 12),
                    _buildStepIndicator(),
                    const SizedBox(height: 16),
                    _buildBotoes(),
                    const SizedBox(height: 16),
                    _buildLog(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── TopBar ───────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      color: AppColors.g1,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Catapulta ESP32',
                  style: TextStyle(
                    color: AppColors.g5,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Controle de lançamento',
                  style: TextStyle(color: AppColors.g4, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _conectado ? AppColors.g2 : AppColors.error.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7, height: 7,
                  decoration: BoxDecoration(
                    color: _conectado ? AppColors.g5 : AppColors.errorBg,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _conectado ? 'Conectado' : 'Desconectado',
                  style: TextStyle(
                    color: _conectado ? AppColors.g5 : AppColors.errorBg,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Card Conexão ─────────────────────────────────────────────
  Widget _buildCardConexao() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labelCard('Conexão'),
          // Toggle BT / Wi-Fi
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.g5,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _toggleBtn('Bluetooth', ModoConexao.bluetooth),
                _toggleBtn('Wi-Fi', ModoConexao.wifi),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Botão conectar
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _conectado ? AppColors.g4 : AppColors.g1,
                  foregroundColor: _conectado ? AppColors.g1 : AppColors.g5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  elevation: 0,
                ),
                onPressed: _conectado
                    ? _desconectar
                    : (_modo == ModoConexao.bluetooth
                        ? _escanearBluetooth
                        : _mostrarDialogWifi),
                icon: Icon(_conectado ? Icons.link_off : Icons.link, size: 16),
                label: Text(
                  _conectado ? 'Desconectar' : 'Conectar',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              // Info do modo
              if (_conectado)
                Text(
                  _modo == ModoConexao.bluetooth ? 'Bluetooth clássico' : 'TCP $_enderecoWifi',
                  style: TextStyle(color: AppColors.g3, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, ModoConexao modo) {
    final ativo = _modo == modo;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!_conectado) setState(() => _modo = modo);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: ativo ? AppColors.g1 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: ativo ? AppColors.g5 : AppColors.g3,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // ── Card Distância ───────────────────────────────────────────
  Widget _buildCardDistancia() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labelCard('Distância alvo'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _distCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppColors.g1,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.g5,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.g4, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.g4, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.g2, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (v) {
                    final val = double.tryParse(v);
                    if (val != null) {
                      setState(() {
                        _distanciaCm = val.clamp(50, 400);
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Text('cm',
                  style: TextStyle(
                      fontSize: 16, color: AppColors.g3, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.g2,
              inactiveTrackColor: AppColors.g4,
              thumbColor: AppColors.g1,
              overlayColor: AppColors.g2.withOpacity(0.15),
              trackHeight: 4,
            ),
            child: Slider(
              min: 50,
              max: 400,
              divisions: 70,
              value: _distanciaCm.clamp(50, 400),
              onChanged: (v) {
                setState(() {
                  _distanciaCm = v;
                  _distCtrl.text = v.round().toString();
                });
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('50 cm', style: TextStyle(fontSize: 11, color: AppColors.g3)),
              Text('400 cm', style: TextStyle(fontSize: 11, color: AppColors.g3)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Card Estado ──────────────────────────────────────────────
  Widget _buildCardEstado() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.g1,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.g2,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(_estado.icone, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _estado.titulo,
                  style: const TextStyle(
                    color: AppColors.g5,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _estado.subtitulo,
                  style: TextStyle(color: AppColors.g4, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step indicator ───────────────────────────────────────────
  Widget _buildStepIndicator() {
    final total = CatapultaEstado.values.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final atual = _estado.indice;
        Color cor;
        if (i < atual) cor = AppColors.g2;
        else if (i == atual) cor = AppColors.g3;
        else cor = AppColors.g4;
        return Container(
          width: 32, height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  // ── Botões de ação ───────────────────────────────────────────
  Widget _buildBotoes() {
    final podeTravar  = _conectado && _estado == CatapultaEstado.repouso;
    final podeLancar  = _conectado && _estado == CatapultaEstado.travado;

    return Column(
      children: [
        // Travar
        _botaoAcao(
          label: 'Travar braço',
          cor: AppColors.g2,
          textCor: AppColors.g5,
          ativo: podeTravar,
          onTap: _travar,
        ),
        const SizedBox(height: 10),
        // Lançar
        _botaoAcao(
          label: 'Lançar  —  ${_distanciaCm.round()} cm',
          cor: AppColors.g1,
          textCor: AppColors.g5,
          ativo: podeLancar,
          onTap: _lancar,
        ),
        const SizedBox(height: 10),
        // Reset emergência
        _botaoAcao(
          label: 'Reset de emergência',
          cor: AppColors.g5,
          textCor: AppColors.g2,
          borda: AppColors.g4,
          ativo: _conectado,
          onTap: _resetEmergencia,
        ),
      ],
    );
  }

  Widget _botaoAcao({
    required String label,
    required Color cor,
    required Color textCor,
    Color? borda,
    required bool ativo,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: ativo ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: ativo ? 1.0 : 0.4,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.circular(14),
            border: borda != null ? Border.all(color: borda, width: 1.5) : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: textCor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  // ── Log de mensagens ─────────────────────────────────────────
  Widget _buildLog() {
    if (_log.isEmpty) return const SizedBox.shrink();
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _labelCard('Log de comunicação'),
              GestureDetector(
                onTap: () => setState(() => _log.clear()),
                child: Text('Limpar',
                    style: TextStyle(fontSize: 11, color: AppColors.g3)),
              ),
            ],
          ),
          Container(
            constraints: const BoxConstraints(maxHeight: 120),
            child: ListView.builder(
              shrinkWrap: true,
              reverse: false,
              itemCount: _log.length > 10 ? 10 : _log.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Text(
                  _log[i],
                  style: TextStyle(
                    fontSize: 11,
                    color: _log[i].contains('ERRO') ? AppColors.error : AppColors.g2,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers de layout ────────────────────────────────────────
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.g4.withOpacity(0.5), width: 0.5),
      ),
      child: child,
    );
  }

  Widget _labelCard(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        texto.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          color: AppColors.g3,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.08,
        ),
      ),
    );
  }
}
