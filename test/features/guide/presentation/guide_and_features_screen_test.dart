import 'package:chess_master/features/guide/presentation/feature_catalog_screen.dart';
import 'package:chess_master/features/guide/presentation/guide_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/localized_test_app.dart';

void main() {
  testWidgets('guide searches localized rules and privacy content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(localizedTestApp(const GuideScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Chess-Master guide'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'relay');
    await tester.pump();
    expect(find.text('Friend matches'), findsOneWidget);
    expect(find.text('How chess works'), findsNothing);
  });

  testWidgets('feature catalog exposes honest availability labels', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(localizedTestApp(const FeatureCatalogScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Features catalog'), findsOneWidget);
    expect(find.text('Available'), findsWidgets);
    expect(find.text('Beta'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'premium');
    await tester.pump();
    expect(find.text('Possible premium edition'), findsOneWidget);
    expect(find.text('Premium candidate'), findsOneWidget);
  });
}
