enum ChatRole { user, model }

class ChatMessage {
  final String text;
  final ChatRole role;

  ChatMessage({required this.text, required this.role});
}