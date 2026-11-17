import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lab1_chat_ui/main.dart';

void main() {
  testWidgets('실습 1: 빈 상태와 입력창이 보인다', (tester) async {
    await tester.pumpWidget(const ChatLabApp());

    expect(find.text('AI Chat — 실습 1·4'), findsOneWidget);
    expect(find.text('무엇이든 물어보세요'), findsAtLeastNWidgets(1));
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
  });

  testWidgets('실습 1: 메시지를 보내면 사용자 말풍선이 추가된다', (tester) async {
    await tester.pumpWidget(const ChatLabApp());

    await tester.enterText(find.byType(TextField), '안녕하세요');
    await tester.tap(find.byIcon(Icons.arrow_upward));
    await tester.pump();

    expect(find.text('안녕하세요'), findsOneWidget);
  });

  testWidgets('실습 4: 500 오류 뒤 다시 시도가 보인다', (tester) async {
    await tester.pumpWidget(const ChatLabApp());

    await tester.enterText(find.byType(TextField), '500');
    await tester.tap(find.byIcon(Icons.arrow_upward));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('응답을 받지 못했습니다'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
  });
}
