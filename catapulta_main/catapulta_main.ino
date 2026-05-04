// ============================================================
//  CATAPULTA DE PALITO — ESP32
//  Motor A (pinos 19,18,5,17)  → trava/solta (torque)
//  Motor B (pinos 16,4,2,15)   → tensão do elástico (ângulo)
// ============================================================

#include <BluetoothSerial.h>   // Bluetooth clássico nativo do ESP32
#include <Stepper.h>

// --- Constantes de hardware ---
const int PASSOS_POR_VOLTA = 2048;   // 28BYJ-48

// Motor A: trava o braço segurando pelo torque
Stepper motorA(PASSOS_POR_VOLTA, 19, 5, 18, 17);

// Motor B: estica o elástico girando N graus
Stepper motorB(PASSOS_POR_VOLTA, 16, 2, 4, 15);

// LEDs de status
const int LED_VERDE    = 25;
const int LED_VERMELHO = 26;

BluetoothSerial BT;

// --- Estado da máquina ---
enum Estado { REPOUSO, TRAVADO, ESTRICANDO, LANCANDO, RESETANDO };
Estado estadoAtual = REPOUSO;

// Quantos passos o Motor B deu (para poder voltar)
int passosMotorB = 0;

// ============================================================
void setup() {
  Serial.begin(115200);
  BT.begin("Catapulta_B2");   // Nome visível no celular

  motorA.setSpeed(10);
  motorB.setSpeed(10);

  pinMode(LED_VERDE,    OUTPUT);
  pinMode(LED_VERMELHO, OUTPUT);

  setLED(REPOUSO);
  Serial.println("Catapulta pronta. Aguardando comandos Bluetooth.");
}

// ============================================================
void loop() {
  if (BT.available()) {
    String msg = BT.readStringUntil('\n');
    msg.trim();
    processarComando(msg);
  }
}

// ============================================================
//  PROCESSAMENTO DE COMANDOS
//  Comandos esperados do app:
//    "TRAVAR"         → trava o braço (Motor A segura por torque)
//    "LANCAR:50"      → estica 50 cm equivalente, depois lança
//    "RESET"          → volta Motor B para zero (manual de emergência)
// ============================================================
void processarComando(String msg) {
  Serial.print("Recebido: "); Serial.println(msg);

  // --- TRAVAR ---
  if (msg == "TRAVAR" && estadoAtual == REPOUSO) {
    estadoAtual = TRAVADO;
    setLED(TRAVADO);
    // Motor A não precisa girar: ele já segura pelo torque
    // (as bobinas ficam energizadas enquanto o Arduino estiver ligado)
    BT.println("OK:TRAVADO");
  }

  // --- LANCAR:<distancia_cm> ---
  else if (msg.startsWith("LANCAR:") && estadoAtual == TRAVADO) {
    int distCm = msg.substring(7).toInt();
    if (distCm <= 0 || distCm > 500) {
      BT.println("ERRO:distancia_invalida");
      return;
    }

    // Converte distância → ângulo → passos
    // ATENÇÃO: os valores abaixo precisam ser calibrados nos seus testes!
    // Fórmula linear provisória: 1 cm ≈ 0.5 graus (ajuste conforme experimento)
    float graus  = distCm * 0.5;        // ← CALIBRAR
    graus = constrain(graus, 0, 270);   // limite mecânico
    int passos   = (int)((graus / 360.0) * PASSOS_POR_VOLTA);

    // 1) Estica o elástico
    estadoAtual = ESTRICANDO;
    setLED(ESTRICANDO);
    BT.println("OK:ESTICANDO");

    motorB.step(passos);
    passosMotorB = passos;   // guarda para resetar depois

    // 2) Lança — Motor A solta o braço
    estadoAtual = LANCANDO;
    setLED(LANCANDO);
    BT.println("OK:LANCANDO");

    // Um pequeno giro do Motor A destravar é suficiente
    // (sentido anti-horário = soltar; ajuste se necessário)
    motorA.step(-PASSOS_POR_VOLTA / 4);
    delay(300);   // aguarda o braço completar o lançamento

    // 3) Reseta Motor B
    estadoAtual = RESETANDO;
    setLED(RESETANDO);
    BT.println("OK:RESETANDO");

    motorB.step(-passosMotorB);   // volta à posição zero
    passosMotorB = 0;

    // 4) Motor A volta à posição de repouso
    motorA.step(PASSOS_POR_VOLTA / 4);

    estadoAtual = REPOUSO;
    setLED(REPOUSO);
    BT.println("OK:PRONTO");
  }

  // --- RESET de emergência ---
  else if (msg == "RESET") {
    motorB.step(-passosMotorB);
    passosMotorB = 0;
    estadoAtual = REPOUSO;
    setLED(REPOUSO);
    BT.println("OK:RESET_EMERGENCIA");
  }

  else {
    BT.println("ERRO:comando_desconhecido_ou_estado_incorreto");
  }
}

// ============================================================
//  LEDs de feedback visual
// ============================================================
void setLED(Estado e) {
  switch (e) {
    case REPOUSO:
      digitalWrite(LED_VERDE,    LOW);
      digitalWrite(LED_VERMELHO, LOW);
      break;
    case TRAVADO:
      digitalWrite(LED_VERDE,    HIGH);   // verde = pronto para usar
      digitalWrite(LED_VERMELHO, LOW);
      break;
    case ESTRICANDO:
    case LANCANDO:
    case RESETANDO:
      digitalWrite(LED_VERDE,    LOW);
      digitalWrite(LED_VERMELHO, HIGH);   // vermelho = em operação
      break;
  }
}