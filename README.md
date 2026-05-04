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
```

---

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
```

---

## Dependências (Arduino IDE)

- Placa: **ESP32 Dev Module** (instalar via Boards Manager)
- Biblioteca: **Stepper** (instalar via Library Manager)
- Biblioteca nativa: `BluetoothSerial.h` (já inclusa no pacote ESP32)
