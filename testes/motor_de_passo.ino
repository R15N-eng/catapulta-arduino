#include <Stepper.h>

const int passosPorVolta = 2048; // 28BYJ-48

Stepper motor(passosPorVolta, 8, 10, 9, 11);

void setup() {
  motor.setSpeed(10); // RPM
}

void loop() {
  motor.step(passosPorVolta); // 1 volta
  delay(1000);

  motor.step(-passosPorVolta); // volta ao início
  delay(1000);
}