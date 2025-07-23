// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elasticsearch_query_helper/main.dart';

void main() {
  testWidgets('App launches and shows connection manager', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ElasticsearchQueryHelperApp());

    // Verify that the app launches and shows the connection manager screen
    expect(find.text('Elasticsearch Query Helper'), findsOneWidget);
    
    // Verify that we can find some basic UI elements
    expect(find.byType(AppBar), findsOneWidget);
  });
}
