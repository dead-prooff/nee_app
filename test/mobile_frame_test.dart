import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nee_app/core/widgets/mobile_frame.dart';

const _probe = Key('contenido');

/// Dibuja [MobileFrame] en una ventana de [width] x 800 y devuelve el ancho
/// del contenido y el ancho de pantalla que ve la app.
Future<(double, double)> _measure(
  WidgetTester tester,
  double width, {
  bool enabled = true,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  late double reportedWidth;
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MobileFrame(enabled: enabled, child: child!),
      home: Builder(
        builder: (context) {
          reportedWidth = MediaQuery.sizeOf(context).width;
          return const Scaffold(body: SizedBox.expand(key: _probe));
        },
      ),
    ),
  );
  return (tester.getSize(find.byKey(_probe)).width, reportedWidth);
}

void main() {
  testWidgets('en pantalla ancha limita la app a 480 px centrada', (
    tester,
  ) async {
    final (width, reported) = await _measure(tester, 1280);
    expect(width, MobileFrame.maxWidth);
    expect(reported, MobileFrame.maxWidth, reason: 'la app cree que mide 480');
    expect(tester.getCenter(find.byKey(_probe)).dx, 640, reason: 'centrada');
  });

  testWidgets('en pantalla de celular ocupa todo el ancho', (tester) async {
    final (width, reported) = await _measure(tester, 400);
    expect(width, 400);
    expect(reported, 400);
  });

  testWidgets('desactivado (Android/iOS) no cambia nada', (tester) async {
    final (width, _) = await _measure(tester, 1280, enabled: false);
    expect(width, 1280);
  });
}
