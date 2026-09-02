import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../state/app_state.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('APMA Insights Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => state.refreshAnalytics(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => state.refreshAnalytics(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Total Logged Events',
                      '${state.recentEvents.length}',
                      Icons.history,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Detected Anomalies',
                      '${state.anomalies.length}',
                      Icons.warning_amber_rounded,
                      state.anomalies.isEmpty ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.bar_chart, color: Colors.blueAccent),
                          SizedBox(width: 8),
                          Text(
                            '24-Hour Acoustic Activity Profile D(c, h)',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Hourly density distribution of environmental sound events',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 180,
                        child: state.hourlyDensity.isEmpty
                            ? const Center(child: Text('No data recorded yet'))
                            : BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: 1.0,
                                  barTouchData: BarTouchData(enabled: true),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (val, meta) {
                                          int hour = val.toInt();
                                          if (hour % 4 == 0) {
                                            return Text('${hour}h', style: const TextStyle(fontSize: 10));
                                          }
                                          return const SizedBox();
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 28,
                                        getTitlesWidget: (val, meta) {
                                          if (val == 0.0 || val == 0.5 || val == 1.0) {
                                            return Text('${(val * 100).toInt()}%', style: const TextStyle(fontSize: 9));
                                          }
                                          return const SizedBox();
                                        },
                                      ),
                                    ),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                                  barGroups: List.generate(24, (h) {
                                    final density = state.hourlyDensity[h] ?? 0.0;
                                    return BarChartGroupData(
                                      x: h,
                                      barRods: [
                                        BarChartRodData(
                                          toY: density > 0 ? density : 0.02,
                                          color: (h >= 22 || h < 6) ? Colors.indigoAccent : Colors.tealAccent,
                                          width: 8,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ],
                                    );
                                  }),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.notification_important_rounded, color: Colors.orangeAccent),
                          SizedBox(width: 8),
                          Text(
                            'Statistical Anomalies (z > 2.0)',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Days with statistically unusual sound frequencies vs historical baseline',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                      ),
                      const SizedBox(height: 12),
                      if (state.anomalies.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Acoustic environment is within normal expected variances.',
                                  style: TextStyle(fontSize: 12, color: Colors.green),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.anomalies.length,
                          itemBuilder: (context, idx) {
                            final anom = state.anomalies[idx];
                            return ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.orange,
                                child: Icon(Icons.warning, color: Colors.white, size: 18),
                              ),
                              title: Text('${anom.soundClass} Spikes', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                '${anom.date} • ${anom.count} events (Baseline μ: ${anom.mean.toStringAsFixed(1)}, z: ${anom.zScore.toStringAsFixed(2)})',
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.schema, color: Colors.cyanAccent),
                          SizedBox(width: 8),
                          Text(
                            'Sequential Acoustic Behavioral Rules',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Automatically mined acoustic event co-occurrences',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                      ),
                      const SizedBox(height: 12),
                      if (state.sequenceRules.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            'Continuous observation in progress. Sequential patterns will emerge as events accumulate.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.sequenceRules.length,
                          itemBuilder: (context, idx) {
                            final rule = state.sequenceRules[idx];
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.shade800.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.cyanAccent),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      rule.description,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.2),
              radius: 18,
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
