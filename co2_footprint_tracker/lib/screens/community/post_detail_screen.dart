import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/community_post.dart';
import '../../providers/community_provider.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final CommunityPost post;
  
  const PostDetailScreen({super.key, required this.post});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    
    setState(() => _isSubmitting = true);
    try {
      await ref.read(communityActionControllerProvider.notifier).addComment(widget.post, content);
      _commentController.clear();
      FocusScope.of(context).unfocus();
    } catch(e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to comment: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(postCommentsProvider(widget.post.id));
    
    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOriginalPost(context),
                  const Divider(height: 32),
                  const Text('Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  commentsAsync.when(
                    data: (comments) {
                      if (comments.isEmpty) return const Center(child: Text('No comments yet.'));
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundImage: comment.authorAvatar != null ? NetworkImage(comment.authorAvatar!) : null,
                                backgroundColor: Colors.blueAccent,
                                child: comment.authorAvatar == null ? Text(comment.authorName[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12)) : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(comment.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          Text(DateFormat('MMM d, h:mm a').format(comment.createdAt.toDate()), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(comment.content, style: const TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Text('Error loading comments: $e'),
                  ),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isSubmitting
                    ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())
                    : IconButton(
                        icon: const Icon(Icons.send, color: Colors.blue),
                        onPressed: _submitComment,
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginalPost(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
           children: [
             CircleAvatar(
                backgroundImage: widget.post.authorAvatar != null ? NetworkImage(widget.post.authorAvatar!) : null,
                backgroundColor: Colors.blueAccent,
                child: widget.post.authorAvatar == null ? Text(widget.post.authorName.isNotEmpty ? widget.post.authorName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white)) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.post.isRepost ? (widget.post.originalAuthorName ?? 'Unknown') : widget.post.authorName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text(
                      DateFormat('MMM d, y • h:mm a').format(widget.post.createdAt.toDate()),
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
               ),
              ),
           ],
        ),
        const SizedBox(height: 16),
        if (widget.post.content.isNotEmpty) Text(widget.post.content, style: const TextStyle(fontSize: 16)),
        if (widget.post.mediaUrl != null) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(widget.post.mediaUrl!, fit: BoxFit.cover, width: double.infinity),
          ),
        ],
      ],
    );
  }
}
