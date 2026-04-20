import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'app_constant.dart';
import 'chat_message_model.dart';
import 'gemini_service.dart';
import 'supabase_service.dart';
import 'package:markdown/markdown.dart' as md;

class AiChatPage extends StatefulWidget {
  final String pageContext;
  final String chatTitle;
  final String systemPrompt;
  final String? initialMessage;
  
  const AiChatPage({
    super.key, 
    required this.pageContext, 
    this.initialMessage, 
    required this.chatTitle, 
    required this.systemPrompt
  });

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  int _userMessageCount = 0;
  bool _isPaidUser = false;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.text = widget.initialMessage!;
        _sendMessage();
      });
    }
  }

  Future<void> _checkUserStatus() async {
    final isPaid = await SupabaseService.isPaidUser();
    if (mounted) {
      setState(() {
        _isPaidUser = isPaid;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final limit = _isPaidUser ? AppConstant.PAID_CHAT_MESSAGE_LIMIT : AppConstant.CHAT_MESSAGE_LIMIT;
    if (_userMessageCount >= limit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Chat limit reached for this session.")),
      );
      return;
    }

    final userMessage = ChatMessage(text: text, role: ChatRole.user);

    _controller.clear();
    setState(() {
      _messages.add(userMessage);
      _userMessageCount++;
      _isLoading = true;
      // Add a placeholder message for the AI response immediately
      _messages.add(ChatMessage(text: "", role: ChatRole.model));
    });

    // The index of the model's message in the list
    final modelMessageIndex = _messages.length - 1;
    StringBuffer responseBuffer = StringBuffer();

    try {
      // Pass history excluding the empty placeholder message
      final historyForApi = _messages.sublist(0, modelMessageIndex);
      
      final stream = GeminiService.getChatResponseStream(
        pageContext: widget.pageContext,
        history: historyForApi,
        systemPrompt: widget.systemPrompt,
      );
      
      await for (final chunk in stream) {
        if (!mounted) break;
        responseBuffer.write(chunk);
        setState(() {
          _messages[modelMessageIndex] = ChatMessage(
            text: responseBuffer.toString(), 
            role: ChatRole.model
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to get a response. Please try again.'),
            backgroundColor: AppConstant.ERROR_COLOR,
          ),
        );
        setState(() {
          _messages[modelMessageIndex] = ChatMessage(
            text: responseBuffer.isNotEmpty ? responseBuffer.toString() : "Sorry, I couldn't get a response.", 
            role: ChatRole.model
          );
        });
      }
    } finally {
      if(mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatTitle, style: GoogleFonts.poppins()),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppConstant.PADDING_MEDIUM),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final limit = _isPaidUser ? AppConstant.PAID_CHAT_MESSAGE_LIMIT : AppConstant.CHAT_MESSAGE_LIMIT;
    final remaining = limit - _userMessageCount;
    return Container(
      padding: const EdgeInsets.all(AppConstant.PADDING_MEDIUM),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                "$remaining messages left",
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Ask a follow-up question...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstant.BORDER_RADIUS_XL),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.background,
                    ),
                  ),
                ),
                const SizedBox(width: AppConstant.PADDING_SMALL),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isLoading ? null : _sendMessage,
                  style: IconButton.styleFrom(
                    backgroundColor: AppConstant.PRIMARY_COLOR,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == ChatRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(
          vertical: AppConstant.PADDING_SMALL,
          horizontal: AppConstant.PADDING_MEDIUM,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? AppConstant.PRIMARY_COLOR
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppConstant.BORDER_RADIUS_LARGE),
        ),
        child: isUser
            ? Text(
                message.text,
                style: const TextStyle(color: Colors.white),
              )
            : MarkdownBody(
                data: message.text,
                selectable: true,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                  p: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                builders: {'latex': LatexElementBuilder()},
                inlineSyntaxes: [LatexInlineSyntax()],
                blockSyntaxes: const [LatexBlockSyntax()],
              ),
      ),
    );
  }
  
}

// Helper classes for LaTeX rendering in Markdown

/// An inline syntax for parsing single `$` delimited LaTeX expressions.
class LatexInlineSyntax extends md.InlineSyntax {
  LatexInlineSyntax() : super(r'\$((?!\s)(?:.*?[^\s])?)\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final content = match.group(1)!;
    parser.addNode(md.Element.text('latex', content)..attributes['display'] = 'inline');
    return true;
  }
}

/// A block syntax for parsing `$$` delimited LaTeX expressions.
class LatexBlockSyntax extends md.BlockSyntax {
  @override
  RegExp get pattern => RegExp(r'^\$\$\n((?:.|\n)*?)\n\$\$', multiLine: true);

  const LatexBlockSyntax();

  @override
  md.Node parse(md.BlockParser parser) {
    var match = pattern.firstMatch(parser.current.content)!;
    final content = match.group(1)!;
    final element = md.Element.text('latex', content)..attributes['display'] = 'block';
    parser.advance();
    return element;
  }
}

/// A markdown builder for rendering `latex` elements.
class LatexElementBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final displayMode = element.attributes['display'];
    final textContent = element.textContent;
    try {
      // return Math.tex(
      //   textContent,
      //   mathStyle: displayMode == 'block' ? MathStyle.display : MathStyle.text,
      //   textStyle: preferredStyle,
      // );
      return Text(
        textContent,
      ); 
    } catch (e) {
      return Text(
        'Error rendering math: $textContent',
        style: preferredStyle?.copyWith(color: Colors.red),
      );
    }
  }
}
