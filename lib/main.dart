import 'dart:async';

import 'package:flutter/material.dart';

void main() => runApp(const ChatLabApp());

class ChatLabApp extends StatelessWidget {
  const ChatLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chat — 실습 1·4',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2F6FE4),
        ),
        useMaterial3: true,
      ),
      home: const ChatPage(),
    );
  }
}

/// 대화 한 줄. 서버 없이 실습 1·4를 확인하기 위한 최소 모델.
class ChatMessage {
  const ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

/// 실습 4의 HTTP/timeout 상황을 로컬에서 재현하기 위한 예외.
class FakeApiException implements Exception {
  const FakeApiException({this.status, this.isTimeout = false});

  final int? status;
  final bool isTimeout;
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];

  bool _sending = false;
  String? _errorMessage;
  int? _lastErrorStatus;
  String? _lastUserText;
  int _retryAttempt = 0;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    _controller.clear();
    _lastUserText = text;
    _retryAttempt = 0;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _errorMessage = null;
      _lastErrorStatus = null;
    });

    _toBottom();
    await _requestAnswer(text, isRetry: false);
  }

  Future<void> _retry() async {
    final text = _lastUserText;
    if (text == null || _sending) return;

    // 실습 4: 429면 1초 → 2초 지수 백오프.
    if (_lastErrorStatus == 429) {
      final waitSeconds = _retryAttempt <= 1 ? 1 : 2;
      await Future<void>.delayed(Duration(seconds: waitSeconds));
    }

    await _requestAnswer(text, isRetry: true);
  }

  Future<void> _requestAnswer(String text, {required bool isRetry}) async {
    setState(() {
      _sending = true;
      if (isRetry) {
        _errorMessage = null;
      }
    });

    try {
      final answer = await _fakeAiReply(text, attempt: _retryAttempt);

      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(text: answer, isUser: false));
        _errorMessage = null;
        _lastErrorStatus = null;
      });
      _toBottom();
    } on FakeApiException catch (e) {
      if (!mounted) return;

      final message = switch (e.status) {
        401 => '키/권한을 확인해 주세요',
        429 => '잠시 후 다시 시도해 주세요',
        500 => '응답을 받지 못했습니다',
        _ when e.isTimeout => '네트워크를 확인해 주세요',
        _ => '네트워크를 확인해 주세요',
      };

      setState(() {
        _errorMessage = message;
        _lastErrorStatus = e.status;
        _retryAttempt += 1;
      });
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  /// 실제 API 대신 수업 중 오류/재시도 동작을 재현한다.
  ///
  /// 입력 예시:
  /// - 401      → 권한 오류 (재시도해도 계속 오류)
  /// - 429      → 두 번 실패 후 성공, retry 사이 1s → 2s
  /// - 500      → 첫 요청 실패, 한 번 재시도 후 성공
  /// - timeout  → 첫 요청 실패, 한 번 재시도 후 성공
  Future<String> _fakeAiReply(String text, {required int attempt}) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final lower = text.toLowerCase();

    if (lower.contains('401')) {
      throw const FakeApiException(status: 401);
    }

    if (lower.contains('429') && attempt < 2) {
      throw const FakeApiException(status: 429);
    }

    if (lower.contains('500') && attempt < 1) {
      throw const FakeApiException(status: 500);
    }

    if (lower.contains('timeout') && attempt < 1) {
      throw const FakeApiException(isTimeout: true);
    }

    return '“$text”에 대한 응답입니다. 실습에서는 실제 API 대신 가짜 응답을 사용합니다.';
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 실습 1 TODO 5: 키보드가 올라오면 입력창이 함께 올라온다.
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('AI Chat — 실습 1·4'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  // 실습 1 할 일 1: 최신 메시지가 아래에 오도록 reverse 사용.
                  ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message =
                          _messages[_messages.length - 1 - index];
                      return _Bubble(message: message);
                    },
                  ),

                  // 실습 1 TODO 4: 빈 상태.
                  if (_messages.isEmpty)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 42,
                            color: Theme.of(context)
                                .colorScheme
                                .outline,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '무엇이든 물어보세요',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '오류 테스트: 401 · 429 · 500 · timeout',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // 실습 4: 오류 상태를 말풍선처럼 남기고 AnimatedSwitcher로 전환.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _errorMessage == null
                  ? const SizedBox.shrink(key: ValueKey('no-error'))
                  : _ErrorBubble(
                      key: ValueKey(_errorMessage),
                      message: _errorMessage!,
                      sending: _sending,
                      onRetry: _retry,
                    ),
            ),

            if (_sending)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: LinearProgressIndicator(minHeight: 2),
              ),

            // 실습 1 TODO 3: 입력창 + 전송 버튼.
            _InputBar(
              controller: _controller,
              sending: _sending,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

/// 실습 1 TODO 2: 사용자 오른쪽 / AI 왼쪽 말풍선.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment:
          message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: message.isUser
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isUser ? 16 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 16),
          ),
        ),
        child: Text(message.text),
      ),
    );
  }
}

/// 실습 4: 오류 말풍선 + 다시 시도.
class _ErrorBubble extends StatelessWidget {
  const _ErrorBubble({
    super.key,
    required this.message,
    required this.sending,
    required this.onRetry,
  });

  final String message;
  final bool sending;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 8),
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(color: colors.onErrorContainer),
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: sending ? null : onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !sending,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              minLines: 1,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: '무엇이든 물어보세요',
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: sending ? null : onSend,
            icon: sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_upward),
            tooltip: '전송',
          ),
        ],
      ),
    );
  }
}
