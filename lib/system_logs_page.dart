import 'package:flutter/material.dart';

class SystemLogsPage extends StatelessWidget {
  const SystemLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Lista de ejemplo para simular logs
    final logs = [
      {'action': 'Login exitoso', 'user': 'admin@sisol.red', 'time': 'Hace 2 min'},
      {'action': 'Usuario creado', 'user': 'admin@sisol.red', 'time': 'Hace 15 min'},
      {'action': 'Error de conexión', 'user': 'System', 'time': 'Hace 1 hora'},
      {'action': 'Perfil actualizado', 'user': 'usuario@test.com', 'time': 'Hace 3 horas'},
    ];

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
                'Historial de actividad y eventos críticos',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final log = logs[index];
              return ListTile(
                leading: Icon(
                  Icons.history_toggle_off,
                  color: theme.colorScheme.secondary,
                ),
                title: Text(
                  log['action']!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('Usuario: ${log['user']}'),
                trailing: Text(
                  log['time']!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
