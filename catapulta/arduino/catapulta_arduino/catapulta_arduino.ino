#include <SoftwareSerial.h>
#include <Stepper.h>

SoftwareSerial bluetooth(2, 3);
const int passosPorVolta = 2048;

Stepper motor1(passosPorVolta, 8, 9, 10, 11);
Stepper motor2(passosPorVolta, 4, 6, 5, 7);

const int ledVerde = 12;
const int ledRed   = 13;

long passosM1 = 0;
bool emEspera103 = false;
bool aguardandoValor = true;

// false = calibração, true = normal
// começa em calibração por segurança
bool modoNormal = false;

unsigned long tempoAnterior = 0;
bool estadoLedRed = LOW;

void setup() {
  bluetooth.begin(9600);
  motor1.setSpeed(10);
  motor2.setSpeed(-16);
  pinMode(ledVerde, OUTPUT);
  pinMode(ledRed, OUTPUT);

  digitalWrite(ledRed, HIGH);
  digitalWrite(ledVerde, LOW);
}

void loop() {
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

    // ── Troca de modo ──────────────────────────────
    if (valor == 503) {
      modoNormal = false;
      aguardandoValor = true;
      digitalWrite(ledRed, HIGH);
      digitalWrite(ledVerde, LOW);
      return;
    }

    if (valor == 504) {
      modoNormal = true;
      aguardandoValor = true;
      digitalWrite(ledRed, HIGH);
      digitalWrite(ledVerde, LOW);
      return;
    }

    // ── Modo Calibração ────────────────────────────
    if (!modoNormal) {

      // Recebe passos brutos diretamente
      if (valor > 0 && valor <= 9999) {
        passosM1 = valor;
        digitalWrite(ledRed, HIGH);
        digitalWrite(ledVerde, LOW);
        motor1.step(-passosM1);
        digitalWrite(ledVerde, HIGH);
        digitalWrite(ledRed, LOW);
        return;
      }

      if (valor == 102) {
        digitalWrite(ledVerde, LOW);
        digitalWrite(ledRed, LOW);
        motor2.step(-512);
        emEspera103 = true;
        tempoAnterior = millis();
        return;
      }

      if (valor == 103 && emEspera103) {
        emEspera103 = false;
        digitalWrite(ledRed, HIGH);
        motor1.step(passosM1);
        motor2.step(512);
        digitalWrite(ledRed, HIGH);
        digitalWrite(ledVerde, LOW);
        return;
      }
    }

    // ── Modo Normal ────────────────────────────────
    if (modoNormal) {

      if (valor >= 0 && valor <= 100 && aguardandoValor) {
        passosM1 = map(valor, 0, 100, 0, 2048);
        return;
      }

      if (valor == 101) {
        aguardandoValor = false;
        digitalWrite(ledRed, HIGH);
        digitalWrite(ledVerde, LOW);
        motor1.step(-passosM1);
        digitalWrite(ledVerde, HIGH);
        digitalWrite(ledRed, LOW);
        return;
      }

      if (valor == 102) {
        digitalWrite(ledVerde, LOW);
        digitalWrite(ledRed, LOW);
        motor2.step(-512);
        emEspera103 = true;
        tempoAnterior = millis();
        return;
      }

      if (valor == 103 && emEspera103) {
        emEspera103 = false;
        digitalWrite(ledRed, HIGH);
        motor1.step(passosM1);
        motor2.step(512);
        aguardandoValor = true;
        digitalWrite(ledRed, HIGH);
        digitalWrite(ledVerde, LOW);
        return;
      }
    }
  }
}