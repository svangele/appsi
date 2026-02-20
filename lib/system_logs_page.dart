import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SystemLogsPage extends StatefulWidget {
  const SystemLogsPage({super.key});

  @override
  State<SystemLogsPage> createState() => _SystemLogsPageState();
}

class _SystemLogsPageState extends State<SystemLogsPage> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('system_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(50);
      
      setState(() {
        _logs = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching logs: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          color: theme.colorScheme.primary.withValues(alpha: 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Logs del Sistema',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Actividad real capturada desde la base de datos',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _logs.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_toggle_off, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('No hay logs registrados aún', style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchLogs,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _logs.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      final action = log['action_type'] ?? 'ACCIÓN';
                      final target = log['target_info'] ?? '---';
                      final date = DateTime.parse(log['created_at']).toLocal();
                      
                      return ListTile(
                        leading: _getIconForAction(action, theme),
                        title: Text(
                          action,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        subtitle: Text(
                          target,
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Text(
                          _formatTime(date),
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Icon _getIconForAction(String action, ThemeData theme) {
    switch (action) {
      case 'CREACIÓN':
        return Icon(Icons.person_add_alt_1, color: theme.colorScheme.secondary);
      case 'ELIMINACIÓN':
        return const Icon(Icons.person_remove_alt_1, color: Colors.redAccent);
      case 'REGISTRO':
        return Icon(Icons.app_registration, color: theme.colorScheme.primary);
      default:
        return const Icon(Icons.history, color: Colors.blueGrey);
    }
  }

  String _formatTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} $hour:$minute';
  }
}
