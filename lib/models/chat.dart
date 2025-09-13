class Chat {
  final String id;
  final String? conversationId;
  final String? senderId;
  final String? receiverId;
  final String? message;
  final Map<String, dynamic>? meta;
  final DateTime? createdAt;

  Chat({
    required this.id,
    this.conversationId,
    this.senderId,
    this.receiverId,
    this.message,
    this.meta,
    this.createdAt,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'],
      conversationId: json['conversation_id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      message: json['message'],
      meta: json['meta'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'meta': meta,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}