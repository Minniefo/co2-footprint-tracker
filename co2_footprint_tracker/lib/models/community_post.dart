import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPost {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final String? mediaUrl;
  final Timestamp createdAt;
  final int likesCount;
  final int commentsCount;
  final int repostsCount;
  final bool isRepost;
  final String? originalPostId;
  final String? originalAuthorName;

  CommunityPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.content,
    this.mediaUrl,
    required this.createdAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.repostsCount = 0,
    this.isRepost = false,
    this.originalPostId,
    this.originalAuthorName,
  });

  factory CommunityPost.fromMap(String id, Map<String, dynamic> map) {
    return CommunityPost(
      id: id,
      authorId: map['authorId'] as String? ?? '',
      authorName: map['authorName'] as String? ?? 'Unknown User',
      authorAvatar: map['authorAvatar'] as String?,
      content: map['content'] as String? ?? '',
      mediaUrl: map['mediaUrl'] as String?,
      createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
      likesCount: map['likesCount'] is num ? (map['likesCount'] as num).toInt() : int.tryParse(map['likesCount']?.toString() ?? '0') ?? 0,
      commentsCount: map['commentsCount'] is num ? (map['commentsCount'] as num).toInt() : int.tryParse(map['commentsCount']?.toString() ?? '0') ?? 0,
      repostsCount: map['repostsCount'] is num ? (map['repostsCount'] as num).toInt() : int.tryParse(map['repostsCount']?.toString() ?? '0') ?? 0,
      isRepost: map['isRepost'] as bool? ?? false,
      originalPostId: map['originalPostId'] as String?,
      originalAuthorName: map['originalAuthorName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      if (authorAvatar != null) 'authorAvatar': authorAvatar,
      'content': content,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      'createdAt': createdAt,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'repostsCount': repostsCount,
      'isRepost': isRepost,
      if (originalPostId != null) 'originalPostId': originalPostId,
      if (originalAuthorName != null) 'originalAuthorName': originalAuthorName,
    };
  }

  CommunityPost copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? content,
    String? mediaUrl,
    Timestamp? createdAt,
    int? likesCount,
    int? commentsCount,
    int? repostsCount,
    bool? isRepost,
    String? originalPostId,
    String? originalAuthorName,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      createdAt: createdAt ?? this.createdAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      repostsCount: repostsCount ?? this.repostsCount,
      isRepost: isRepost ?? this.isRepost,
      originalPostId: originalPostId ?? this.originalPostId,
      originalAuthorName: originalAuthorName ?? this.originalAuthorName,
    );
  }
}
