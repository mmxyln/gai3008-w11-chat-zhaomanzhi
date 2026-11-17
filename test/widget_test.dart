import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lab1_chat_ui/main.dart';

void main() {
  testWidgets('실습 1: 빈 상태와 입력창이 보인다', (tester) async {
    await tester.pumpWidget(const ChatLabApp());

    expect(find.text('AI Chat — 실습 1'), findsOneWidget);
    expect(find.text('무엇이든 물어보세요'), findsAtLeastNWidgets(1));
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
  });
}
