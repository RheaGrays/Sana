import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/acoustic_event.dart';
import '../../state/app_state.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  String selectedClass = 'All';
  String selectedTier = 'All';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Acoustic Event Journal (AEJ)', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear Journal',
            onPressed: () => _confirmClearDialog(context, state),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blueGrey.shade900.withValues(alpha: 0.3),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedClass,
                    underline: const SizedBox(),
                    items: ['All', ...AppConstants.soundClasses]
                        .map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => selectedClass = val);
                        state.refreshJournal(filterClass: val, filterTier: selectedTier);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: selectedTier,
                  underline: const SizedBox(),
                  items: ['All', 'HIGH', 'MEDIUM', 'LOW']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => selectedTier = val);
                      state.refreshJournal(filterClass: selectedClass, filterTier: val);
                    }
                  },
                ),
              ],
            ),
          ),

          // Events List
          Expanded(
            child: state.recentEvents.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu_book, size: 60, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No acoustic events match the filter.', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: state.recentEvents.length,
                    itemBuilder: (context, index) {
                      final event = state.recentEvents[index];
                      return _buildEventTile(context, event);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventTile(BuildContext context, AcousticEvent event) {
    final icon = AppConstants.classIcons[event.soundClass] ?? Icons.volume_up;
    final Color tierColor = event.priorityTier == 'HIGH'
        ? Colors.redAccent
        : event.priorityTier == 'MEDIUM'
            ? Colors.amber.shade700
            : Colors.blueGrey;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: tierColor.withValues(alpha: 0.2),
          child: Icon(icon, color: tierColor),
        ),
        title: Text(event.soundClass, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${DateFormat('MMM dd, yyyy • hh:mm:ss a').format(event.timestamp)}\nZone: ${event.geofenceZone} | Time: ${event.timeOfDayLabel}',
          style: const TextStyle(fontSize: 12),
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Chip(
              label: Text(
                event.priorityTier,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              backgroundColor: tierColor,
              padding: EdgeInsets.zero,
            ),
            Text('Sp: ${event.priorityScore.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        onTap: () => _showEventDetailsModal(context, event),
      ),
    );
  }

  void _showEventDetailsModal(BuildContext context, AcousticEvent event) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.soundClass,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _detailRow('Event ID', '#${event.eventId ?? 'N/A'}'),
              _detailRow('Timestamp', DateFormat('yyyy-MM-dd HH:mm:ss').format(event.timestamp)),
              _detailRow('CASPA Priority Score', event.priorityScore.toStringAsFixed(4)),
              _detailRow('Classification Confidence', '${(event.confidence * 100).toStringAsFixed(1)}%'),
              _detailRow('Priority Tier', event.priorityTier),
              _detailRow('Geofence Zone', event.geofenceZone),
              _detailRow('Time-of-Day Context', event.timeOfDayLabel),
              if (event.latitude != null)
                _detailRow('GPS Location', '${event.latitude!.toStringAsFixed(4)}, ${event.longitude!.toStringAsFixed(4)}'),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _confirmClearDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Journal'),
        content: const Text('Are you sure you want to delete all stored acoustic events?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              state.clearJournal();
              Navigator.pop(context);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
