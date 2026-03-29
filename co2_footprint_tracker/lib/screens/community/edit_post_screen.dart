import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/community_post.dart';
import '../../providers/community_provider.dart';

const _kGreen = Color(0xFF2E7D32);
const _kBg = Color(0xFFF8FAFC);

class EditPostScreen extends ConsumerStatefulWidget {
  final CommunityPost post;
  const EditPostScreen({super.key, required this.post});

  @override
  ConsumerState<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends ConsumerState<EditPostScreen> {
  late TextEditingController _contentController;
  bool _isSaving = false;
  static const int _maxChars = 500;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.post.content);
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post content cannot be empty.')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ref.read(communityActionControllerProvider.notifier).editPost(widget.post, content);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: _kGreen, content: Text('Post updated! ✓', style: GoogleFonts.inter(color: Colors.white))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final charCount = _contentController.text.length;
    final overLimit = charCount > _maxChars;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Post', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 20, color: Colors.black87)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: (_isSaving || overLimit) ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('SAVE', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _contentController,
                    maxLines: 8,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.inter(fontSize: 15, color: Colors.black87, height: 1.6),
                    decoration: InputDecoration(
                      hintText: 'Update your post...',
                      hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$charCount / $_maxChars',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: overLimit ? Colors.red.shade400 : Colors.grey.shade400,
                        fontWeight: overLimit ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (widget.post.mediaUrl != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: widget.post.mediaUrl!,
                  fit: BoxFit.cover,
                  height: 200,
                  width: double.infinity,
                  placeholder: (context, url) => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                  errorWidget: (context, url, error) => const SizedBox(height: 200, child: Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey))),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 8),
                    Text('Image editing is not supported yet.', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
