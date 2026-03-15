import 'package:flutter/material.dart';
import '../models/badge.dart';

class BadgeItem extends StatelessWidget {
  final BadgeModel badge;
  final bool isGranted;
  final DateTime? grantedAt;

  const BadgeItem({
    super.key,
    required this.badge,
    this.isGranted = false,
    this.grantedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isGranted ? 4 : 0,
      color: isGranted ? Colors.white : Colors.grey.shade200,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isGranted 
          ? BorderSide.none 
          : BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isGranted ? Colors.green.shade50 : Colors.grey.shade300,
              ),
              child: isGranted && badge.icon.isNotEmpty
                  ? (badge.icon.startsWith('http') 
                      ? Image.network(badge.icon, fit: BoxFit.cover,) 
                      : const Icon(Icons.emoji_events, color: Colors.amber, size: 32,))
                  : Icon(Icons.lock_outline, color: Colors.grey.shade500, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              badge.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isGranted ? Colors.black87 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isGranted ? Colors.black54 : Colors.grey.shade500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isGranted && grantedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Earned on ${grantedAt!.day}/${grantedAt!.month}/${grantedAt!.year}',
                style: const TextStyle(fontSize: 10, color: Colors.green),
              )
            ]
          ],
        ),
      ),
    );
  }
}
