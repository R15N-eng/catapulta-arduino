#include <SoftwareSerial.h>
#include <Stepper.h>

// Bluetooth
SoftwareSerial BT(10, 11); // RX, TX

// Motor
const int passosPorVolta = 2048;
Stepper motor(passosPorVolta, 8, 12, 9, 13);

// LED RGB
int ledVermelho = 6;
int ledVerde = 5;

char comando;

void setup() {
  pinMode(ledVermelho, OUTPUT);
  pinMode(ledVerde, OUTPUT);

  motor.setSpeed(10);
  BT.begin(9600);
}

void loop() {
  if (BT.available()) {
    comando = BT.read();
  }

  if (comando == '1') {
    // LED verde
    digitalWrite(ledVerde, HIGH);
    digitalWrite(ledVermelho, LOW);

    // gira sentido horário
    motor.step(10);
  }

  if (comando == '0') {
    // LED vermelho
    digitalWrite(ledVerde, LOW);
    digitalWrite(ledVermelho, HIGH);

    // gira sentido anti-horário
    motor.step(-10);
  }
}