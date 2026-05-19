# LEVIATHAN — Catapulta IME 2026

Projeto de engenharia desenvolvido para a **Competicao de Catapultas 2026 — IME**.
Catapulta construida com palitos de picole, controlada via **Bluetooth (HC-05)** por um app Android desenvolvido em Flutter.

---

## Estrutura do repositorio

```
catapulta/
├── lib/src/
│   ├── pages/
│   │   ├── home_page.dart          # Tela principal (LEVIATHAN)
│   │   ├── calibracao_page.dart    # Tela de calibracao (passos manuais)
│   │   ├── devices_page.dart       # Selecao do dispositivo Bluetooth
│   │   └── main_page.dart          # Navegacao entre telas
│   ├── controllers/
│   │   └── catapult_controller.dart
│   └── services/
│       └── bluetooth_service.dart
├── arduino/
│   └── catapulta_arduino/
│       └── catapulta_arduino.ino   # Firmware Arduino UNO + HC-05
├── assets/
│   └── icon/
│       └── leviathan_icon.png      # Icone do app
├── android/
└── pubspec.yaml
```

---

## Hardware

| Componente | Funcao |
|---|---|
| Arduino UNO | Microcontrolador principal |
| HC-05 | Modulo Bluetooth classico |
| Motor de passo 1 (28BYJ-48) | Tensiona o elastico (angulo de lancamento) |
| Motor de passo 2 (28BYJ-48) | Trava e solta o braco (torque) |
| 2x Driver ULN2003 | Aciona os motores de passo |
| LED Verde (pino 12) | Sistema travado / pronto para lancar |
| LED Vermelho (pino 13) | Operacao em andamento |
| Elastico de latex | Elemento de propulsao |
| Esfera de aco | Projetil fornecido pelos professores |

### Mapeamento de pinos

| Componente | Pinos Arduino |
|---|---|
| Motor 1 — tensao do elastico | 8, 9, 10, 11 |
| Motor 2 — trava/solta o braco | 4, 5, 6, 7 |
| HC-05 RX (software serial) | 2 (RX), 3 (TX) |
| LED Verde | 12 |
| LED Vermelho | 13 |

---

## Protocolo Bluetooth

Comandos enviados pelo app como texto + `\n`:

| Valor | Acao |
|---|---|
| `0` a `100` | Define distancia alvo em % (0.5 m a 4.0 m) |
| `101` | TRAVAR — Motor 2 segura o braco pelo torque |
| `102` | LANCAR — Motor 1 estica + Motor 2 solta + reset automatico |
| `103` | RESET de emergencia — volta tudo ao inicio |

Respostas do Arduino:

| Resposta | Significado |
|---|---|
| `OK:DISTANCIA_DEFINIDA` | Distancia configurada com sucesso |
| `OK:TRAVADO` | Braco travado — encaixar o elastico |
| `OK:ESTICANDO` | Motor 1 girando |
| `OK:LANCANDO` | Motor 2 soltando o braco |
| `OK:RESETANDO` | Motores voltando a posicao zero |
| `OK:PRONTO` | Ciclo concluido — pronto para novo lancamento |
| `ERRO:DEFINA_DISTANCIA_PRIMEIRO` | Envie 0-100 antes de travar |
| `ERRO:TRAVE_PRIMEIRO` | Envie 101 antes de lancar |

### Fluxo de uso

```
1. Enviar 0-100  →  define a distancia alvo
2. Enviar 101    →  Motor 2 trava o braco
3. [Manual]      →  encaixar o elastico
4. Enviar 102    →  Motor 1 estica, Motor 2 solta, motores resetam
```

---

## App Flutter — LEVIATHAN

- Requer Android com Bluetooth classico (BT 2.x / HC-05)
- Tela **CONTROLE**: define distancia, trava e lanca
- Tela **CALIBRACAO**: envia numero de passos manualmente para aferir a relacao passos x distancia

### Gerar APK

```bash
cd catapulta
flutter pub get
flutter build apk --release --target-platform android-arm64   # 64-bit
flutter build apk --release --target-platform android-arm     # 32-bit
```

---

## Calibracao

Os valores a ajustar no firmware sao:

```cpp
const long PASSOS_MIN = 256;   // passos para lancar ~0,5 m
const long PASSOS_MAX = 2048;  // passos para lancar ~4,0 m
```

Use a tela de Calibracao do app para enviar passos manuais, meca a distancia real e ajuste as constantes acima ate os resultados baterem.

---

## Requisitos atendidos

| Requisito | Status | Detalhe |
|---|---|---|
| R1 — Materiais fornecidos | OK | Palitos, Arduino, motores, elastico, esfera |
| R2 — Controle pelo celular | OK | App Flutter via Bluetooth HC-05 |
| R3 — Alimentacao por pilhas | OK | Sem conexao a tomadas |
| R4 — Distancia 0,5 a 4 m | OK | Mapeado de 0 a 100% no protocolo |
| R5 — Alvo no mesmo nivel | OK | Considerado no projeto mecanico |
| R6 — Esfera de aco | OK | Projetil fornecido pelos professores |

---

## Equipe — Turma B2

> Preencha com os nomes do grupo

---

Projeto academico — IME 2026
