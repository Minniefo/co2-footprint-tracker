import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/community_post.dart';
import '../../providers/community_provider.dart';
import '../public_profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

const _kGreen = Color(0xFF2E7D32);
const _kBg = Color(0xFFF8FAFC);

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
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(postCommentsProvider(widget.post.id));

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.black54, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Post', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 20, color: Colors.black87)),
      ),
      body: Column(
        children: [
          // ── Scrollable content ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Original post card ──
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PublicProfileScreen(uid: widget.post.authorId))),
                              child: _Avatar(name: widget.post.authorName, avatarUrl: widget.post.authorAvatar, radius: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.post.isRepost ? (widget.post.originalAuthorName ?? 'Unknown') : widget.post.authorName,
                                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black87)),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('MMM d, y • h:mm a').format(widget.post.createdAt.toDate()),
                                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (widget.post.content.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(widget.post.content, style: GoogleFonts.inter(fontSize: 15, height: 1.6, color: Colors.black87)),
                        ],
                        if (widget.post.mediaUrl != null) ...[
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: widget.post.mediaUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              placeholder: (context, url) => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                              errorWidget: (context, url, error) => const SizedBox(height: 200, child: Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey))),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Comments header ──
                  Text('Comments', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.black87)),
                  const SizedBox(height: 12),

                  // ── Comments list ──
                  commentsAsync.when(
                    data: (comments) {
                      if (comments.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text('No comments yet.', style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 15)),
                                const SizedBox(height: 4),
                                Text('Be the first to share your thoughts!', style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13)),
                              ],
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final c = comments[index];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PublicProfileScreen(uid: c.authorId))),
                                  child: _Avatar(name: c.authorName, avatarUrl: c.authorAvatar, radius: 16),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(c.authorName, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                                          Text(
                                            DateFormat('MMM d, h:mm a').format(c.createdAt.toDate()),
                                            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade400),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(c.content, style: GoogleFonts.inter(fontSize: 14, color: Colors.black87, height: 1.4)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                  ),
                ],
              ),
            ),
          ),

          // ── Sticky comment input ──
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, -4))],
            ),
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _commentController,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _isSubmitting ? null : _submitComment,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(color: _kGreen, shape: BoxShape.circle),
                    child: _isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double radius;
  const _Avatar({required this.name, this.avatarUrl, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty) ? CachedNetworkImageProvider(avatarUrl!) : null,
      backgroundColor: _kGreen,
      child: (avatarUrl == null || avatarUrl!.isEmpty)
          ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: radius * 0.85))
          : null,
    );
  }
}
