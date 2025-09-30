import 'package:flutter/material.dart';
import '../../services/service_locator.dart';
import '../../models/consultation.dart';

class ConsultationInboxScreen extends StatelessWidget {
  const ConsultationInboxScreen({super.key});

  Color _typeColor(ConsultType t) {
    switch (t) {
      case ConsultType.chat:
        return Colors.blue;
      case ConsultType.call:
        return Colors.teal;
      case ConsultType.video:
        return Colors.purple;
    }
  }

  IconData _typeIcon(ConsultType t) {
    switch (t) {
      case ConsultType.chat:
        return Icons.chat_bubble_outline;
      case ConsultType.call:
        return Icons.call_outlined;
      case ConsultType.video:
        return Icons.videocam_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locator = ServiceLocator();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultation Inbox'),
      ),
      body: StreamBuilder<List<ConsultRequest>>(
        stream: locator.watchConsultRequests(),
        builder: (context, snap) {
          final list = snap.data ?? const <ConsultRequest>[];
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.withValues(alpha: 0.5)),
                  const SizedBox(height: 8),
                  Text('No consultation requests yet', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final r = list[i];
              final color = _typeColor(r.type);
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.15)),
                  color: color.withValues(alpha: 0.03),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                      child: Icon(_typeIcon(r.type), color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.customerName, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text('${r.type.name.toUpperCase()} • KES ${r.price.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(r.status.name, style: Theme.of(context).textTheme.labelSmall),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _actions(context, r),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _actions(BuildContext context, ConsultRequest r) {
    final locator = ServiceLocator();
    switch (r.status) {
      case ConsultStatus.requested:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => locator.setConsultRequestStatus(r.id, ConsultStatus.accepted),
              child: const Text('Accept'),
            ),
            const SizedBox(width: 4),
            TextButton(
              onPressed: () => locator.setConsultRequestStatus(r.id, ConsultStatus.cancelled),
              child: const Text('Decline'),
            ),
          ],
        );
      case ConsultStatus.accepted:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              onPressed: () => locator.setConsultRequestStatus(r.id, ConsultStatus.inProgress),
              child: const Text('Start'),
            ),
          ],
        );
      case ConsultStatus.inProgress:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              onPressed: () => locator.setConsultRequestStatus(r.id, ConsultStatus.completed),
              child: const Text('End'),
            ),
          ],
        );
      case ConsultStatus.completed:
      case ConsultStatus.cancelled:
        return const SizedBox.shrink();
    }
  }
}
