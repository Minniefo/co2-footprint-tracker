import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/community_post.dart';
import '../../providers/community_provider.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';
import 'edit_post_screen.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(feedControllerProvider.notifier).fetchMore();
    }
  }

  Future<void> _refresh() async {
    await ref.read(feedControllerProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final feedStateAsync = ref.watch(feedControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostScreen()));
        },
        child: const Icon(Icons.add),
      ),
      body: feedStateAsync.when(
        data: (feed) {
          if (feed.posts.isEmpty) {
            return const Center(child: Text('No posts yet! Be the first to share.'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: feed.posts.length + (feed.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == feed.posts.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final post = feed.posts[index];
                return PostCard(post: post);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class PostCard extends ConsumerWidget {
  final CommunityPost post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLiked = ref.watch(likedPostsProvider)[post.id] ?? false;
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser?.uid == post.authorId;
    
    // Automatically query the status silently when the card builds (optimistic check)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(communityActionControllerProvider.notifier).syncLikeStatus(post.id);
    });

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (post.isRepost) ...[
                Row(
                  children: [
                    const Icon(Icons.repeat, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${post.authorName} reposted', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: post.authorAvatar != null ? NetworkImage(post.authorAvatar!) : null,
                    backgroundColor: Colors.blueAccent,
                    child: post.authorAvatar == null ? Text(post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white)) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.isRepost ? (post.originalAuthorName ?? 'Unknown') : post.authorName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          DateFormat('MMM d, y • h:mm a').format(post.createdAt.toDate()),
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (isOwner)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => EditPostScreen(post: post)));
                        } else if (value == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Post?'),
                              content: const Text('Are you sure you want to delete this post?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true), 
                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              await ref.read(communityActionControllerProvider.notifier).deletePost(post.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post deleted')));
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                            }
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (post.content.isNotEmpty) Text(post.content, style: const TextStyle(fontSize: 15)),
              if (post.mediaUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(post.mediaUrl!, fit: BoxFit.cover, height: 200, width: double.infinity),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InteractionButton(
                    icon: isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.grey,
                    count: post.likesCount,
                    onTap: () {
                      ref.read(communityActionControllerProvider.notifier).toggleLike(post);
                    },
                  ),
                  _InteractionButton(
                    icon: Icons.chat_bubble_outline,
                    color: Colors.blue,
                    count: post.commentsCount,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)));
                    },
                  ),
                  _InteractionButton(
                     icon: Icons.repeat,
                     color: Colors.green,
                     count: post.repostsCount,
                     onTap: () {
                        // Normally prompt for confirmation
                     },
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int count;
  final VoidCallback onTap;

  const _InteractionButton({
    required this.icon,
    required this.color,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Text(count.toString(), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
