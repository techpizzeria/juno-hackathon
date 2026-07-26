/// One message in an AI program-creation conversation.
///
/// Plain value type shared between the chat screen and the LLM service; the
/// service maps it onto each vendor's message wire shape.
class ChatMessage {
  const ChatMessage({required this.fromUser, required this.text});

  /// True when the user sent it, false for the assistant.
  final bool fromUser;

  /// The message text.
  final String text;

  /// Vendor-neutral role string (`user` or `assistant`).
  String get role => fromUser ? 'user' : 'assistant';
}
