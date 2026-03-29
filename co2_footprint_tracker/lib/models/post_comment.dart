import 'package:cloud_firestore/cloud_firestore.dart';

class PostComment {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final Timestamp createdAt;

  PostComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.content,
    required this.createdAt,
  });

  factory PostComment.fromMap(String id, Map<String, dynamic> map) {
    return PostComment(
      id: id,
      authorId: map['authorId'] as String? ?? '',
      authorName: map['authorName'] as String? ?? 'Unknown',
      authorAvatar: map['authorAvatar'] as String?,
      content: map['content'] as String? ?? '',
      createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      if (authorAvatar != null) 'authorAvatar': authorAvatar,
      'content': content,
      'createdAt': createdAt,
    };
  }
}
