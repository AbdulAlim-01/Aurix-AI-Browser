import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_constant.dart';
import 'ai_chat_page.dart'; // Reusing some widgets from AiChatPage
import 'chat_message_model.dart';
import 'gemini_service.dart';

class CrossTabChatPage extends StatefulWidget {
  final Map<String, String> tabsContent;

  const CrossTabChatPage({
    super.key,
    required this.tabsContent,
  });

  @override
  State<CrossTabChatPage> createState() => _CrossTabChatPageState();
}

class _CrossTabChatPageState extends State<CrossTabChatPage> {
  late final String _pageContext;

  @override
  void initState() {
    super.initState();
    _pageContext = _formatTabsContent();
  }

  String _formatTabsContent() {
    final buffer = StringBuffer();
    buffer.writeln("Here is the content from the selected browser tabs:\n");
    int tabIndex = 1;
    widget.tabsContent.forEach((title, content) {
      buffer.writeln("--- START OF TAB ${tabIndex}: $title ---");
      buffer.writeln(content);
      buffer.writeln("--- END OF TAB $tabIndex ---\n");
      tabIndex++;
    });
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AiChatPage(
      pageContext: _pageContext,
      chatTitle: 'Chat Between Tabs',
      systemPrompt: AppConstant.CROSS_TAB_CHAT_PROMPT,
    );
  }
}