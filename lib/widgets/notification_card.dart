import 'package:flutter/material.dart';
import '../models/notification.dart';

class NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onDismiss;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isRead
              ? Theme.of(context).colorScheme.outline.withOpacity(0.2)
              : Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: notification.isRead ? 1 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: notification.isRead
                ? Colors.black.withOpacity(0.05)
                : Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getTypeColor(notification.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getTypeIcon(notification.type),
            color: _getTypeColor(notification.type),
            size: 24,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
            color: notification.isRead
                ? Colors.grey[700]
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.message,
              style: TextStyle(
                color:
                    notification.isRead ? Colors.grey[600] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(notification.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                ),
                const Spacer(),
                if (!notification.isRead)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'NEW',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'dismiss':
                onDismiss?.call();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'dismiss',
              child: Row(
                children: [
                  Icon(Icons.close_rounded),
                  SizedBox(width: 8),
                  Text('Dismiss'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'sms':
        return Colors.blue;
      case 'push':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'sms':
        return Icons.sms_rounded;
      case 'push':
        return Icons.notifications_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}
