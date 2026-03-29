import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/router.dart';
import '../../widgets/app_text_field.dart';

class VendorDashboardScreen extends ConsumerWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(stockSummaryProvider);
    final sensorAsync = ref.watch(sensorRefreshProvider);
    final productsAsync = ref.watch(productsProvider);
    final user = ref.watch(authProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour, ${user?.name.split(' ').first ?? 'Vendeur'} 👋',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              DateFormat('EEEE d MMMM', 'fr').format(DateTime.now()),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.invalidate(productsProvider),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _showLogoutDialog(context, ref),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primary.withOpacity(0.1),
                child: Text(
                  user?.name.substring(0, 1).toUpperCase() ?? 'V',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(productsProvider);
          ref.invalidate(latestSensorProvider);
        },
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Capteurs ─────────────────────────────────────────
              _SensorWidget(sensorAsync: sensorAsync),
              const SizedBox(height: 20),

              // ── Résumé stock ─────────────────────────────────────
              SectionHeader(
                title: 'Vue d\'ensemble',
                actionLabel: 'Voir tout',
                onAction: () => context.go(AppRoutes.inventory),
              ),
              const SizedBox(height: 12),
              summaryAsync.when(
                data: (s) => _StockSummaryGrid(summary: s),
                loading: () => const _SummaryGridSkeleton(),
                error: (e, _) => ErrorCard(message: e.toString(), onRetry: () => ref.invalidate(stockSummaryProvider)),
              ),
              const SizedBox(height: 20),

              // ── Graphe qualité ───────────────────────────────────
              summaryAsync.when(
                data: (s) => _QualityChart(summary: s),
                loading: () => const LoadingCard(height: 200),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),

              // ── Alertes rapides ──────────────────────────────────
              productsAsync.when(
                data: (products) {
                  final urgent = products
                      .where((p) => p.isExpiringSoon || p.isExpired || p.quality == QualityStatus.mauvais)
                      .toList();
                  if (urgent.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: 'Attention requise 🚨',
                        actionLabel: 'Tout voir',
                        onAction: () => context.go(AppRoutes.vendorAlerts),
                      ),
                      const SizedBox(height: 12),
                      ...urgent.take(3).map((p) => _UrgentProductCard(product: p)),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),

              // ── Produits récents ─────────────────────────────────
              SectionHeader(
                title: 'Stock récent',
                actionLabel: 'Gérer',
                onAction: () => context.go(AppRoutes.inventory),
              ),
              const SizedBox(height: 12),
              productsAsync.when(
                data: (products) {
                  final recent = products.take(5).toList();
                  return Column(
                    children: recent.map((p) => _ProductListTile(product: p)).toList(),
                  );
                },
                loading: () => Column(
                  children: List.generate(3, (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: LoadingCard(height: 72),
                  )),
                ),
                error: (e, _) => ErrorCard(message: e.toString()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
            child: Text('Déconnecter', style: TextStyle(color: AppTheme.qualityBad)),
          ),
        ],
      ),
    );
  }
}

// ── Widget Capteurs ──────────────────────────────────────────────────
class _SensorWidget extends StatelessWidget {
  final AsyncValue<SensorData> sensorAsync;
  const _SensorWidget({required this.sensorAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryDark, AppTheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: sensorAsync.when(
        data: (sensor) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Conditions de stockage',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
                if (sensor.hasAlert)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.qualityBad,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Alerte', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Normal', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _SensorValue(
                  icon: '🌡️',
                  label: 'Température',
                  value: '${sensor.temperature.toStringAsFixed(1)}°C',
                  isAlert: sensor.isTemperatureAlert,
                )),
                const SizedBox(width: 12),
                Expanded(child: _SensorValue(
                  icon: '💧',
                  label: 'Humidité',
                  value: '${sensor.humidity.toStringAsFixed(1)}%',
                  isAlert: sensor.isHumidityAlert,
                )),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Dernière lecture : ${DateFormat('HH:mm').format(sensor.timestamp)}',
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
            ),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
        error: (e, _) => Row(
          children: [
            const Text('📡', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(child: Text(
              'Capteurs hors ligne',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            )),
          ],
        ),
      ),
    );
  }
}

class _SensorValue extends StatelessWidget {
  final String icon, label, value;
  final bool isAlert;
  const _SensorValue({required this.icon, required this.label, required this.value, this.isAlert = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAlert
            ? AppTheme.qualityBad.withOpacity(0.3)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white, fontWeight: FontWeight.w700,
          )),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Résumé Stock Grid ────────────────────────────────────────────────
class _StockSummaryGrid extends StatelessWidget {
  final StockSummary summary;
  const _StockSummaryGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        StatCard(value: '${summary.totalItems}', label: 'Unités en stock', emoji: '📦', color: AppTheme.primary),
        StatCard(value: '${summary.goodQualityCount}', label: 'Bonne qualité', emoji: '✅', color: AppTheme.qualityGood),
        StatCard(value: '${summary.expiringSoonCount}', label: 'Expirent bientôt', emoji: '⏰', color: AppTheme.qualityMedium),
        StatCard(value: '${summary.badQualityCount}', label: 'Mauvaise qualité', emoji: '❌', color: AppTheme.qualityBad),
      ],
    );
  }
}

class _SummaryGridSkeleton extends StatelessWidget {
  const _SummaryGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: List.generate(4, (_) => const LoadingCard()),
    );
  }
}

// ── Graphe Qualité ───────────────────────────────────────────────────
class _QualityChart extends StatelessWidget {
  final StockSummary summary;
  const _QualityChart({required this.summary});

  @override
  Widget build(BuildContext context) {
    final total = summary.goodQualityCount + summary.mediumQualityCount + summary.badQualityCount;
    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Répartition qualité', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: summary.goodQualityCount.toDouble(),
                          color: AppTheme.qualityGood,
                          title: '${summary.goodQualityCount}',
                          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                          radius: 60,
                        ),
                        PieChartSectionData(
                          value: summary.mediumQualityCount.toDouble(),
                          color: AppTheme.qualityMedium,
                          title: '${summary.mediumQualityCount}',
                          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                          radius: 60,
                        ),
                        PieChartSectionData(
                          value: summary.badQualityCount.toDouble(),
                          color: AppTheme.qualityBad,
                          title: '${summary.badQualityCount}',
                          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                          radius: 60,
                        ),
                      ],
                      borderData: FlBorderData(show: false),
                      centerSpaceRadius: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Legend(color: AppTheme.qualityGood, label: 'Bon', count: summary.goodQualityCount),
                    const SizedBox(height: 10),
                    _Legend(color: AppTheme.qualityMedium, label: 'Moyen', count: summary.mediumQualityCount),
                    const SizedBox(height: 10),
                    _Legend(color: AppTheme.qualityBad, label: 'Mauvais', count: summary.badQualityCount),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  const _Legend({required this.color, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text('$label ($count)', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

// ── Carte Produit Urgent ─────────────────────────────────────────────
class _UrgentProductCard extends StatelessWidget {
  final ProductModel product;
  const _UrgentProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final isExpired = product.isExpired;
    final isExpiringSoon = product.isExpiringSoon;
    final isBadQuality = product.quality == QualityStatus.mauvais;

    String reason;
    Color color;
    String icon;

    if (isExpired) { reason = 'Expiré'; color = AppTheme.qualityBad; icon = '💀'; }
    else if (isExpiringSoon) { reason = 'Expire dans ${product.daysRemaining}j'; color = AppTheme.qualityMedium; icon = '⏰'; }
    else { reason = 'Mauvaise qualité'; color = AppTheme.qualityBad; icon = '❌'; }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: Theme.of(context).textTheme.titleMedium),
                Text('${product.quantity} unités · $reason',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: color, size: 20),
        ],
      ),
    );
  }
}

// ── Ligne Produit ────────────────────────────────────────────────────
class _ProductListTile extends StatelessWidget {
  final ProductModel product;
  const _ProductListTile({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(_emoji(product.category), style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text('${product.quantity} unités · ${product.category}',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                FreshnessBar(percent: product.freshnessPercent),
              ],
            ),
          ),
          const SizedBox(width: 12),
          QualityBadge(quality: product.quality.label),
        ],
      ),
    );
  }

  String _emoji(String category) {
    switch (category.toLowerCase()) {
      case 'pomme': case 'pommes': return '🍎';
      case 'tomate': case 'tomates': return '🍅';
      case 'banane': case 'bananes': return '🍌';
      case 'orange': case 'oranges': return '🍊';
      case 'citron': case 'citrons': return '🍋';
      case 'raisin': return '🍇';
      case 'fraise': case 'fraises': return '🍓';
      case 'laitue': case 'salade': return '🥬';
      case 'carotte': case 'carottes': return '🥕';
      default: return '🫐';
    }
  }
}