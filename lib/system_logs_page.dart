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
  DateTime? _startDate;
  DateTime? _endDate;


  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() => _isLoading = true);
    try {
      var query = Supabase.instance.client
          .from('system_logs')
          .select();

      if (_startDate != null) {
        query = query.gte('created_at', _startDate!.toIso8601String());
      }
      if (_endDate != null) {
        // Add 23:59:59 to include the whole end day if using only dates
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
        query = query.lte('created_at', end.toIso8601String());
      }

      final data = await query.order('created_at', ascending: false).limit(100);

      
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
          color: theme.colorScheme.primary.withOpacity(0.05),
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
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildDateSelector(
                      label: _startDate == null ? 'Desde' : _formatDateOnly(_startDate!),
                      icon: Icons.calendar_today,
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2024),
                          lastDate: DateTime.now(),
                        );
                        if (d != null) {
                          setState(() => _startDate = d);
                          _fetchLogs();
                        }
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                    ),
                    _buildDateSelector(
                      label: _endDate == null ? 'Hasta' : _formatDateOnly(_endDate!),
                      icon: Icons.event,
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: _startDate ?? DateTime(2024),
                          lastDate: DateTime.now(),
                        );
                        if (d != null) {
                          setState(() => _endDate = d);
                          _fetchLogs();
                        }
                      },
                    ),
                    if (_startDate != null || _endDate != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _startDate = null;
                              _endDate = null;
                            });
                            _fetchLogs();
                          },
                          icon: const Icon(Icons.clear_all, size: 18),
                          label: const Text('Limpiar'),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                        ),
                      ),
                  ],
                ),
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

  String _formatDateOnly(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildDateSelector({required String label, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF344092)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
