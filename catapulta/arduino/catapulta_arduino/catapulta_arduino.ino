#include <SoftwareSerial.h>
#include <Stepper.h>

SoftwareSerial bluetooth(2, 3);
const int passosPorVolta = 2048;

Stepper motor1(passosPorVolta, 8, 9, 10, 11);
Stepper motor2(passosPorVolta, 4, 6, 5, 7);

const int ledVerde = 12;
const int ledRed   = 13;

long passosM1    = 0;
bool emEspera103 = false;
bool aguardandoValor = true;

// Flags do modo calibração
bool modoCalibrado  = false;  // true = modo normal, false = modo calibração
bool aguardandoPassosBrutos = false;

unsigned long tempoAnterior = 0;
bool estadoLedRed = LOW;

void setup() {
  bluetooth.begin(9600);
  motor1.setSpeed(10);
  motor2.setSpeed(16);
  pinMode(ledVerde, OUTPUT);
  pinMode(ledRed, OUTPUT);

  digitalWrite(ledRed, HIGH);
  digitalWrite(ledVerde, LOW);
}

void loop() {
  // Pisca o LED vermelho enquanto aguarda o comando 103 (travar)
  if (emEspera103) {
    unsigned long tempoAtual = millis();
    if (tempoAtual - tempoAnterior >= 250) {
      tempoAnterior = tempoAtual;
      estadoLedRed = !estadoLedRed;
      digitalWrite(ledRed, estadoLedRed);
    }
  }

  if (bluetooth.available() > 0) {
    int valor = bluetooth.parseInt();

    // ─────────────────────────────────────────────
    // SELETORES DE MODO
    // ─────────────────────────────────────────────

    // 500 → Modo Normal
    if (valor == 500) {
      modoCalibrado = true;
      aguardandoPassosBrutos = false;
      aguardandoValor = true;
      digitalWrite(ledRed, HIGH);
      digitalWrite(ledVerde, LOW);
      return;
    }

    // 503 → Modo Calibração: próximo valor recebido serão passos brutos
    if (valor == 503) {
      modoCalibrado = false;
      aguardandoPassosBrutos = true;
      return;
    }

    // ─────────────────────────────────────────────
    // MODO CALIBRAÇÃO
    // ─────────────────────────────────────────────
    if (!modoCalibrado) {

      // Recebe os passos brutos logo após o 503
      if (aguardandoPassosBrutos && valor > 0) {
        passosM1 = valor;
        aguardandoPassosBrutos = false;

        // Executa o carregamento com os passos brutos
        digitalWrite(ledRed, HIGH);
        digitalWrite(ledVerde, LOW);
        motor1.step(-passosM1);
        digitalWrite(ledVerde, HIGH);
        digitalWrite(ledRed, LOW);
        return;
      }

      // 102 → Lançar (igual ao modo normal)
      if (valor == 102) {
        digitalWrite(ledVerde, LOW);
        digitalWrite(ledRed, LOW);
        motor2.step(512);
        emEspera103 = true;
        tempoAnterior = millis();
        return;
      }

      // 103 → Travar e retornar (igual ao modo normal)
      if (valor == 103 && emEspera103) {
        emEspera103 = false;
        digitalWrite(ledRed, HIGH);
        motor1.step(passosM1);
        motor2.step(-512);
        aguardandoPassosBrutos = true; // libera novo ciclo de calibração
        digitalWrite(ledRed, HIGH);
        digitalWrite(ledVerde, LOW);
        return;
      }
    }

    // ─────────────────────────────────────────────
    // MODO NORMAL
    // ─────────────────────────────────────────────
    if (modoCalibrado) {

      // 0–100 → Guarda percentual e converte para passos
      if (valor >= 0 && valor <= 100 && aguardandoValor) {
        passosM1 = map(valor, 0, 100, 0, 2048);
        return;
      }

      // 101 → Carregar: executa motor1
      if (valor == 101) {
        aguardandoValor = false;
        digitalWrite(ledRed, HIGH);
        digitalWrite(ledVerde, LOW);
        motor1.step(-passosM1);
        digitalWrite(ledVerde, HIGH);
        digitalWrite(ledRed, LOW);
        return;
      }

      // 102 → Lançar: motor2 gira 90° e aguarda travamento
      if (valor == 102) {
        digitalWrite(ledVerde, LOW);
        digitalWrite(ledRed, LOW);
        motor2.step(512);
        emEspera103 = true;
        tempoAnterior = millis();
        return;
      }

      // 103 → Travar: retorna motores e reinicia ciclo
      if (valor == 103 && emEspera103) {
        emEspera103 = false;
        digitalWrite(ledRed, HIGH);
        motor1.step(passosM1);
        motor2.step(-512);
        aguardandoValor = true;
        digitalWrite(ledRed, HIGH);
        digitalWrite(ledVerde, LOW);
        return;
      }
    }
  }
}