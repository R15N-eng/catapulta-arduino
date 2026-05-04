# App Flutter — Catapulta ESP32

App Android de controle da catapulta via **Bluetooth clássico** ou **Wi-Fi (TCP)**.

---

## Pré-requisitos

- [Flutter SDK](https://flutter.dev/docs/get-started/install) instalado
- Android Studio com emulador **ou** celular Android com modo desenvolvedor ativado
- Cabo USB (para primeira instalação)

---

## Como rodar

```bash
# 1. Entre na pasta do projeto
cd catapulta_app

# 2. Baixe as dependências
flutter pub get

# 3. Conecte o celular ou inicie o emulador
# (para listar dispositivos disponíveis)
flutter devices

# 4. Rode o app
flutter run

# 5. Para gerar o APK e instalar direto no celular
flutter build apk --release
# O APK fica em: build/app/outputs/flutter-apk/app-release.apk
```

---

## Estrutura

```
catapulta_app/
├── lib/
│   └── main.dart              # Toda a lógica e UI do app
├── android/
│   └── app/src/main/
│       └── AndroidManifest.xml  # Permissões Bluetooth e Wi-Fi
└── pubspec.yaml               # Dependências
```

---

## Como usar o app

### Bluetooth
1. **Pareie** o ESP32 (nome: `Catapulta_ESP32`) nas configurações do Android
2. No app, selecione **Bluetooth** e toque em **Conectar**
3. Escolha `Catapulta_ESP32` na lista

### Wi-Fi
1. Conecte o celular e o ESP32 na **mesma rede Wi-Fi**
2. Descubra o IP do ESP32 (aparece no Serial Monitor ao iniciar)
3. No app, selecione **Wi-Fi**, toque em **Conectar** e digite o IP

### Fluxo de lançamento
1. Toque **Travar braço** → encaixe o elástico manualmente
2. Ajuste a **distância alvo** (50 a 400 cm)
3. Toque **Lançar** → o ESP32 estica, lança e reseta automaticamente

---

## Dependências

| Pacote | Versão | Uso |
|--------|--------|-----|
| `flutter_bluetooth_serial` | ^0.4.0 | Bluetooth clássico (HC-05 / ESP32) |
| `permission_handler` | ^11.3.0 | Permissões Android em runtime |
| `network_info_plus` | ^5.0.0 | Info da rede Wi-Fi |
