<<<<<<< HEAD
# 🏹 Catapulta ESP32 — IME 2026

Projeto de engenharia desenvolvido para a **Competição de Catapultas 2026**.
Catapulta construída com palitos de picolé, controlada via **Bluetooth ou Wi-Fi** por um app Android desenvolvido em Flutter.

---

## 📁 Estrutura do repositório

```
catapulta-arduino/
├── catapulta_app/          # App Android (Flutter)
│   ├── lib/
│   │   └── main.dart       # Código completo do app
│   ├── android/
│   │   └── app/src/main/
│   │       └── AndroidManifest.xml
│   ├── pubspec.yaml
│   └── README_APP.md
│
├── catapulta-arduino/      # Firmware ESP32
│   ├── src/
│   │   ├── catapulta_main/
│   │   │   └── catapulta_main.ino   # Código principal
│   │   └── testes/
│   │       ├── motor_de_passo.ino   # Teste básico de rotação
│   │       └── test.ino             # Protótipo inicial
│   └── README_ARDUINO.md
│
└── README.md               # Este arquivo
=======
# Catapulta de Palito — ESP32

Projeto de engenharia: catapulta de palito de picolé controlada via Bluetooth por um ESP32, com dois motores de passo 28BYJ-48.

---

## Como funciona

1. App envia comando **TRAVAR** → Motor A trava o braço pelo torque
2. Encaixar o elástico manualmente no braço
3. App envia **LANCAR:50** (distância desejada em cm) → Motor B estica o elástico até o ângulo calculado
4. Ao atingir o ângulo, Motor A solta → lançamento
5. Motor B reseta automaticamente para a posição inicial

---

## Hardware necessário

- ESP32 Dev Module
- 2x Motor de passo 28BYJ-48
- 2x Driver ULN2003
- 2x LED (vermelho e verde) para feedback de status
- Fonte de alimentação (bateria Li-Ion 3.7V ou 3x AA)

---

## Mapeamento de pinos

| Componente       | Pinos ESP32     |
|------------------|-----------------|
| Motor A (trava)  | 19, 18, 5, 17   |
| Motor B (tensão) | 16, 4, 2, 15    |
| LED Verde        | 25              |
| LED Vermelho     | 26              |

---

## Comandos Bluetooth

Conecte ao dispositivo **Catapulta_ESP32** pelo app de sua preferência e envie os comandos abaixo:

| Comando       | Descrição                                              |
|---------------|--------------------------------------------------------|
| `TRAVAR`      | Trava o braço na posição horizontal (Motor A)          |
| `LANCAR:50`   | Estica o elástico mirando 50 cm e lança automaticamente |
| `RESET`       | Reset de emergência — Motor B volta à posição zero     |

---

## Respostas do ESP32

O ESP32 responde via Bluetooth confirmando cada etapa:

| Resposta                | Significado                        |
|-------------------------|------------------------------------|
| `OK:TRAVADO`            | Braço travado, pode encaixar o elástico |
| `OK:ESTICANDO`          | Motor B girando                    |
| `OK:LANCANDO`           | Motor A soltando o braço           |
| `OK:RESETANDO`          | Motor B voltando para posição zero |
| `OK:PRONTO`             | Ciclo concluído, pronto para novo lançamento |
| `ERRO:distancia_invalida` | Distância fora do intervalo 1–500 cm |

---

## Estrutura do repositório

```
catapulta-arduino/
├── src/
│   ├── catapulta_main/
│   │   └── catapulta_main.ino   # código principal
│   └── testes/
│       ├── motor_de_passo.ino   # teste básico de rotação
│       └── test.ino             # protótipo inicial com Bluetooth
└── README.md
>>>>>>> 400c370d34196fad8976d4379c735801f2cfefec
```

---

<<<<<<< HEAD
## ⚙️ Como funciona

### Hardware
| Componente | Função |
|---|---|
| ESP32 Dev Module | Microcontrolador principal |
| Motor de passo A (28BYJ-48) | Trava e solta o braço pelo torque |
| Motor de passo B (28BYJ-48) | Estica o elástico até o ângulo calculado |
| 2x Driver ULN2003 | Aciona os motores de passo |
| LED Verde | Indica sistema travado / pronto |
| LED Vermelho | Indica operação em andamento |
| Botão físico | Liga/desliga o sistema (Requisito 8) |
| Elástico de látex | Elemento de propulsão |
| Esfera de aço | Projétil fornecido pelos professores |

### Mapeamento de pinos

| Componente | Pinos ESP32 |
|---|---|
| Motor A (trava) | 19, 18, 5, 17 |
| Motor B (tensão) | 16, 4, 2, 15 |
| LED Verde | 25 |
| LED Vermelho | 26 |
| Botão físico | 34 |

---

## 🚀 Fluxo de lançamento

```
1. App envia "TRAVAR"
   └─ Motor A energiza as bobinas e segura o braço pelo torque

2. [Manual] Encaixar o elástico no braço

3. App envia "LANCAR:150" (distância em cm)
   └─ Motor B gira até o ângulo calculado (estica o elástico)
   └─ Motor A gira levemente → braço solta → lançamento!
   └─ Motor B volta automaticamente à posição zero
```

---

## 📱 App Flutter

### Pré-requisitos
- Flutter SDK 3.x instalado
- Android com Bluetooth clássico habilitado

### Como rodar
```bash
cd catapulta_app
flutter pub get
flutter run          # celular conectado via USB
flutter build apk    # gera o APK para instalar
```

### Comandos enviados ao ESP32
| Comando | Descrição |
|---|---|
| `TRAVAR` | Trava o braço |
| `LANCAR:<cm>` | Estica e lança (ex: `LANCAR:150`) |
| `RESET` | Reset de emergência |
| `STATUS` | Retorna estado atual |
| `CALIBRAR:<fator>` | Atualiza fator de calibração (ex: `CALIBRAR:0.72`) |

### Respostas do ESP32
| Resposta | Significado |
|---|---|
| `OK:TRAVADO` | Braço travado |
| `OK:ESTICANDO` | Motor B girando |
| `OK:LANCANDO` | Motor A soltando |
| `OK:RESETANDO` | Motor B voltando ao zero |
| `OK:PRONTO` | Ciclo concluído |
| `ERRO:*` | Erro com descrição |

---

## 🔌 Firmware ESP32

### Dependências (Arduino IDE)
1. Placa: **ESP32 Dev Module**
   - Boards Manager URL:
     `https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json`
2. Biblioteca: **Stepper** (Library Manager)
3. `BluetoothSerial.h` — já inclusa no pacote ESP32

### Configuração antes de compilar
No arquivo `catapulta_main.ino`, altere as linhas:
```cpp
const char* WIFI_SSID     = "NomeDaSuaRede";
const char* WIFI_PASSWORD = "SenhaDaRede";
```

### Calibração
A conversão de distância para ângulo usa a constante:
```cpp
float FATOR_CALIBRACAO = 0.5;  // graus por cm — ajustar nos testes
```
Durante os testes, é possível atualizar sem recompilar enviando pelo app:
```
CALIBRAR:0.72
=======
## Calibração

A conversão de distância para ângulo usa a constante abaixo, que deve ser ajustada com base nos testes:

```cpp
float graus = distCm * 0.5;   // ← ajustar após testes experimentais
```

Faça lançamentos com diferentes valores, meça a distância real atingida e ajuste a constante até o modelo bater com a realidade.

---

## Como subir o código (primeira vez)

```bash
git init
git add .
git commit -m "primeiro commit - catapulta ESP32"
git remote add origin https://github.com/SEU-USUARIO/catapulta-arduino.git
git push -u origin main
>>>>>>> 400c370d34196fad8976d4379c735801f2cfefec
```

---

<<<<<<< HEAD
## 📋 Requisitos atendidos

| Requisito | Status | Detalhe |
|---|---|---|
| R1 — Materiais | ✅ | Palitos, ESP32, motores de passo, elástico |
| R2 — Controle pelo celular | ✅ | App Flutter via Bluetooth e Wi-Fi |
| R3 — Alimentação por pilhas | ✅ | Sem conexão a tomadas |
| R4 — Distância 0,5 a 4 m | ✅ | Faixa 50–400 cm validada no código |
| R5 — Alvo no mesmo nível | ✅ | Considerado no projeto mecânico |
| R6 — Esfera de aço | ✅ | Projétil fornecido pelos professores |
| R8 — Botão liga/desliga | ✅ | Pino 34, com debounce |

---

## 👥 Equipe

> Preencha com os nomes do grupo

---

## 📄 Licença

Projeto acadêmico — IME 2026
=======
## Dependências (Arduino IDE)

- Placa: **ESP32 Dev Module** (instalar via Boards Manager)
- Biblioteca: **Stepper** (instalar via Library Manager)
- Biblioteca nativa: `BluetoothSerial.h` (já inclusa no pacote ESP32)
>>>>>>> 400c370d34196fad8976d4379c735801f2cfefec
