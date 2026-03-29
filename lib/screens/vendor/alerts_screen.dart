// lib/screens/vendor/alerts_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_text_field.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertes'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(alertServiceProvider).markAllAsRead();
              ref.invalidate(alertsProvider);
            },
            child: const Text('Tout lire'),
          ),
        ],
      ),
      body: alertsAsync.when(
        data: (alerts) {
          if (alerts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🎉', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text('Aucune alerte'),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            itemBuilder: (ctx, i) => _AlertCard(alert: alerts[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorCard(message: e.toString()),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AlertModel alert;
  const _AlertCard({required this.alert});

  Color _alertColor() {
    switch (alert.type) {
      case AlertType.qualite: return AppTheme.qualityBad;
      case AlertType.expiration: return AppTheme.qualityMedium;
      case AlertType.temperature: return const Color(0xFFE85D04);
      case AlertType.humidite: return const Color(0xFF0096C7);
      case AlertType.stock: return AppTheme.primary;
    }
  }

  String _alertIcon() {
    switch (alert.type) {
      case AlertType.qualite: return '❌';
      case AlertType.expiration: return '⏰';
      case AlertType.temperature: return '🌡️';
      case AlertType.humidite: return '💧';
      case AlertType.stock: return '📦';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _alertColor();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: alert.isRead ? AppTheme.surfaceCard : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: alert.isRead ? AppTheme.divider : color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_alertIcon(), style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        alert.type.label,
                        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      timeago.format(alert.createdAt, locale: 'fr'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(alert.message, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          if (!alert.isRead)
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}