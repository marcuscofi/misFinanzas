import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mis_finanzas/main.dart';

void main() {
  testWidgets('La app arranca y muestra el mensaje inicial', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.textContaining('Firebase'), findsOneWidget);
  });
}