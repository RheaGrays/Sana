import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../state/app_state.dart';

class LiveAlertScreen extends StatelessWidget {
  const LiveAlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final latest = state.latestEvent;
    final caspa = state.latestCaspa;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Row(
              children: [
                Icon(Icons.hearing, color: Colors.blueAccent),
                SizedBox(width: 8),
                Text('SANA Live Monitor', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              Chip(
                avatar: const Icon(Icons.location_on, size: 16, color: Colors.white),
                label: Text(state.currentZone, style: const TextStyle(color: Colors.white, fontSize: 12)),
                backgroundColor: Colors.blueGrey.shade800,
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor: state.isMonitoring ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  state.isMonitoring ? 'Monitoring Active' : 'Monitoring Paused',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () => state.toggleMonitoring(),
                              icon: Icon(state.isMonitoring ? Icons.pause : Icons.play_arrow),
                              label: Text(state.isMonitoring ? 'Pause' : 'Start'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: state.isMonitoring ? Colors.red.shade700 : Colors.green.shade700,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.graphic_eq, size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            const Text('Sound Energy: ', style: TextStyle(fontSize: 12)),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: (state.currentRms * 15).clamp(0.0, 1.0),
                                  minHeight: 12,
                                  backgroundColor: Colors.grey.shade800,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    state.currentRms > 0.03 ? Colors.orangeAccent : Colors.lightGreenAccent,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(state.currentRms * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (latest != null && caspa != null)
                  _buildLatestEventCard(context, latest, caspa)
                else
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
                      child: Column(
                        children: [
                          Icon(Icons.hearing_outlined, size: 56, color: Colors.blueGrey),
                          SizedBox(height: 12),
                          Text(
                            'Listening for environmental sounds...',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                const Text(
                  'Quick Sound Simulation Bench (Validation)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTestButton(context, "Fire Alarm / Smoke Detector", Colors.red),
                    _buildTestButton(context, "Emergency Siren", Colors.redAccent),
                    _buildTestButton(context, "Door Knocking", Colors.blue),
                    _buildTestButton(context, "Doorbell / Chime", Colors.teal),
                    _buildTestButton(context, "Baby Cry", Colors.amber.shade800),
                    _buildTestButton(context, "Dog Barking", Colors.orange),
                    _buildTestButton(context, "Vehicle Horn / Car Honking", Colors.purple),
                    _buildTestButton(context, "Speech / Talking", Colors.grey.shade700),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Live Prioritized Feed',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (state.recentEvents.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text('No events detected yet.')),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.recentEvents.take(5).length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = state.recentEvents[index];
                      final icon = AppConstants.classIcons[item.soundClass] ?? Icons.volume_up;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getTierColor(item.priorityTier).withValues(alpha: 0.2),
                          child: Icon(icon, color: _getTierColor(item.priorityTier)),
                        ),
                        title: Text(item.soundClass, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${DateFormat('HH:mm:ss').format(item.timestamp)} • ${item.geofenceZone} • Conf: ${(item.confidence * 100).toStringAsFixed(0)}%',
                        ),
                        trailing: Chip(
                          label: Text(
                            item.priorityTier,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          backgroundColor: _getTierColor(item.priorityTier),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
        if (state.isFlashingAlert)
          IgnorePointer(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                border: Border.all(color: state.flashColor, width: 14),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLatestEventCard(BuildContext context, dynamic latest, dynamic caspa) {
    final Color tierColor = _getTierColor(latest.priorityTier);
    final icon = AppConstants.classIcons[latest.soundClass] ?? Icons.warning_rounded;

    return Container(
      decoration: BoxDecoration(
        color: tierColor.withValues(alpha: 0.15),
        border: Border.all(color: tierColor, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: tierColor,
                child: Icon(icon, size: 32, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      latest.soundClass,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Detected at ${DateFormat('hh:mm:ss a').format(latest.timestamp)}',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Chip(
                backgroundColor: tierColor,
                label: Text(
                  latest.priorityTier,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric('Priority Score', latest.priorityScore.toStringAsFixed(2)),
              _buildMetric('Confidence', '${(latest.confidence * 100).toStringAsFixed(0)}%'),
              _buildMetric('Decay R(c)', caspa.decayFactor.toStringAsFixed(2)),
              _buildMetric('Zone', latest.geofenceZone),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTestButton(BuildContext context, String soundClass, Color color) {
    return ActionChip(
      avatar: Icon(AppConstants.classIcons[soundClass] ?? Icons.volume_up, size: 16, color: Colors.white),
      label: Text(soundClass, style: const TextStyle(fontSize: 12, color: Colors.white)),
      backgroundColor: color.withValues(alpha: 0.8),
      onPressed: () {
        context.read<AppState>().triggerTestSound(soundClass);
      },
    );
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'HIGH':
        return Colors.redAccent;
      case 'MEDIUM':
        return Colors.amber.shade700;
      case 'LOW':
      default:
        return Colors.blueGrey;
    }
  }
}
