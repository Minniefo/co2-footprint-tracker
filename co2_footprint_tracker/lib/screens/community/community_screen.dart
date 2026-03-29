import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/community_post.dart';
import '../../providers/community_provider.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';
import 'edit_post_screen.dart';
import '../../screens/public_profile_screen.dart';

const _kBg = Color(0xFFF8FAFC);
const _kGreen = Color(0xFF2E7D32);
const _kGreenLight = Color(0xFFE8F5E9);
const _kCardShadow = [
  BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 4)),
];

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
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Community', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 22, color: Colors.black87)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black54),
            onPressed: _refresh,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostScreen())),
        backgroundColor: _kGreen,
        icon: const Icon(Icons.edit_rounded, color: Colors.white),
        label: Text('Post', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: feedStateAsync.when(
        data: (feed) {
          if (feed.posts.isEmpty) {
            return _EmptyFeedState(onPost: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostScreen())));
          }
          return RefreshIndicator(
            color: _kGreen,
            onRefresh: _refresh,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 12, bottom: 80),
              itemCount: feed.posts.length + (feed.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == feed.posts.length) {
                  return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
                }
                return PostCard(post: feed.posts[index]);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading feed: $e')),
      ),
    );
  }
}

class _EmptyFeedState extends StatelessWidget {
  final VoidCallback onPost;
  const _EmptyFeedState({required this.onPost});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: _kGreenLight, shape: BoxShape.circle),
            child: const Icon(Icons.people_alt_rounded, size: 56, color: _kGreen),
          ),
          const SizedBox(height: 20),
          Text('No posts yet!', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          Text('Be the first to share your eco journey.', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onPost,
            icon: const Icon(Icons.add_rounded),
            label: Text('Create Post', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(backgroundColor: _kGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
          ),
        ],
      ),
    );
  }
}

// ─── Public reusable PostCard ────────────────────────────────────────────────

class PostCard extends ConsumerWidget {
  final CommunityPost post;
  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLiked = ref.watch(likedPostsProvider)[post.id] ?? false;
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser?.uid == post.authorId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(communityActionControllerProvider.notifier).syncLikeStatus(post.id);
    });

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _kCardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(post: post))),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Repost banner ──
                if (post.isRepost)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.repeat_rounded, size: 14, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 4),
                        Text('${post.authorName} reposted', style: GoogleFonts.inter(fontSize: 12, color: _kGreen, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),

                // ── Header row ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PublicProfileScreen(uid: post.authorId))),
                      child: _Avatar(name: post.isRepost ? (post.originalAuthorName ?? 'User') : post.authorName, avatarUrl: post.authorAvatar),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.isRepost ? (post.originalAuthorName ?? 'Unknown') : post.authorName,
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black87),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _timeAgo(post.createdAt.toDate()),
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    if (isOwner)
                      _OwnerMenu(
                        onEdit: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditPostScreen(post: post))),
                        onDelete: () => _confirmDelete(context, ref),
                      ),
                  ],
                ),

                // ── Content ──
                if (post.content.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(post.content, style: GoogleFonts.inter(fontSize: 14.5, color: Colors.black87, height: 1.5)),
                ],

                // ── Image ──
                if (post.mediaUrl != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: post.mediaUrl!,
                      fit: BoxFit.cover,
                      height: 200,
                      width: double.infinity,
                      placeholder: (context, url) => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                      errorWidget: (context, url, error) => const SizedBox(height: 200, child: Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey))),
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // ── Actions ──
                Row(
                  children: [
                    _ActionChip(
                      icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isLiked ? Colors.red.shade400 : Colors.grey.shade500,
                      label: _count(post.likesCount),
                      onTap: () => ref.read(communityActionControllerProvider.notifier).toggleLike(post),
                    ),
                    const SizedBox(width: 4),
                    _ActionChip(
                      icon: Icons.chat_bubble_outline_rounded,
                      color: Colors.blue.shade400,
                      label: _count(post.commentsCount),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(post: post))),
                    ),
                    const SizedBox(width: 4),
                    _ActionChip(
                      icon: Icons.repeat_rounded,
                      color: Colors.green.shade600,
                      label: _count(post.repostsCount),
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _count(int n) => n > 0 ? n.toString() : '';

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Post?', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('This action cannot be undone.', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.inter())),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ref.read(communityActionControllerProvider.notifier).deletePost(post.id);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post deleted')));
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

// ─── Helper Widgets ──────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double radius;

  const _Avatar({required this.name, this.avatarUrl, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl!) : null,
      backgroundColor: _kGreen,
      child: avatarUrl == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: radius * 0.9),
            )
          : null,
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({required this.icon, required this.color, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 19, color: color),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(label, style: GoogleFonts.inter(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }
}

class _OwnerMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _OwnerMenu({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz_rounded, color: Colors.grey.shade400),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (v) {
        if (v == 'edit') onEdit();
        if (v == 'delete') onDelete();
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit_outlined, size: 18), const SizedBox(width: 8), Text('Edit', style: GoogleFonts.inter())])),
        PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400), const SizedBox(width: 8), Text('Delete', style: GoogleFonts.inter(color: Colors.red.shade400))])),
      ],
    );
  }
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat('MMM d, y').format(dt);
}
