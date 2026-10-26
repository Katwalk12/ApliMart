class Message {
  final String id;
  final String userId;
  final String userName;
  final String sender; // 'user' or 'support'
  final String content;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.userId,
    required this.userName,
    required this.sender,
    required this.content,
    required this.createdAt,
  });

  bool get isFromUser => sender == 'user';

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        userName: json['user_name']?.toString() ?? 'User',
        sender: json['sender']?.toString() ?? 'user',
        content: json['content']?.toString() ?? '',
        createdAt:
            DateTime.tryParse(json['created_at']?.toString() ?? '') ??
                DateTime.now(),
      );
}
