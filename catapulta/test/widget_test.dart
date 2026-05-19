import 'package:flutter_test/flutter_test.dart';
import 'package:nome_do_projeto/src/app_widget.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AppWidget());
  });
}