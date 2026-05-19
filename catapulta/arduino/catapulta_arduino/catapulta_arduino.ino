#include <SoftwareSerial.h>
#include <Stepper.h>

SoftwareSerial bluetooth(2, 3); 
const int passosPorVolta = 2048;

Stepper motor1(passosPorVolta, 8, 9, 10, 11);
Stepper motor2(passosPorVolta, 4, 6, 5, 7);

const int ledVerde = 12;
const int ledRed = 13;

long passosM1 = 0;
bool emEspera103 = false;
bool aguardandoValor = true;
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

    // 1. Recebe 0 a 100: Guarda o valor do Motor 1
    //    A flag aguardandoValor protege passosM1 durante o ciclo
    if (valor >= 0 && valor <= 100 && aguardandoValor) {
      passosM1 = map(valor, 0, 100, 0, 2048);
    }

    // 2. Recebe 101: Executa Motor 1 e trava novos valores
    else if (valor == 101) {
      aguardandoValor = false;
      digitalWrite(ledRed, HIGH);
      digitalWrite(ledVerde, LOW);
      motor1.step(-passosM1);
      digitalWrite(ledVerde, HIGH);
      digitalWrite(ledRed, LOW);
    }

    // 3. Recebe 102: Motor 2 gira 90° e começa a piscar
    else if (valor == 102) {
      digitalWrite(ledVerde, LOW);
      digitalWrite(ledRed, LOW);
      motor2.step(512);
      emEspera103 = true;
      tempoAnterior = millis(); // Garante que o piscar começa sincronizado
    }

    // 4. Recebe 103: Para piscar, volta os motores e reinicia o ciclo
    else if (valor == 103 && emEspera103) {
      emEspera103 = false;
      digitalWrite(ledRed, HIGH);
      motor1.step(passosM1);   // Agora passosM1 está preservado
      motor2.step(-512);
      
      // Reinicia o ciclo liberando novo valor
      aguardandoValor = true;
      digitalWrite(ledRed, HIGH);
      digitalWrite(ledVerde, LOW);
    }
  }
}