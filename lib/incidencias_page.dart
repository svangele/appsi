import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/notification_service.dart';
import 'widgets/page_header.dart';

class IncidenciasPage extends StatefulWidget {
  const IncidenciasPage({super.key});

  @override
  State<IncidenciasPage> createState() => _IncidenciasPageState();
}

class _IncidenciasPageState extends State<IncidenciasPage> {
  List<Map<String, dynamic>> _incidencias = [];
  bool _isLoading = true;
  String? _userRole;
  String? _userFullName;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // Fetch role and name
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role, nombre, paterno, materno')
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null) {
        final fullName = (profile['nombre'] != null)
            ? '${profile['nombre']} ${profile['paterno']} ${profile['materno'] ?? ''}'.trim()
            : user.email ?? 'Usuario';
        
        if (mounted) {
          setState(() {
            _userRole = profile['role'];
            _userFullName = fullName;
          });
        }
      }
      _fetchIncidencias();
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  Future<void> _fetchIncidencias() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('incidencias')
          .select()
          .order('created_at', ascending: false);
      
      if (mounted) {
        setState(() {
          _incidencias = List<Map<String, dynamic>>.from(response)
            ..sort((a, b) {
              const order = {'PENDIENTE': 0, 'APROBADA': 1, 'CANCELADA': 2};
              final aOrder = order[a['status']] ?? 99;
              final bOrder = order[b['status']] ?? 99;
              if (aOrder != bOrder) return aOrder.compareTo(bOrder);
              return (b['created_at'] as String).compareTo(a['created_at'] as String);
            });
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching incidencias: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showIncidenciaForm({Map<String, dynamic>? incidencia}) {
    final isEditing = incidencia != null;
    final status = incidencia?['status'] ?? 'PENDIENTE';
    
    // Si no es admin y el estatus no es PENDIENTE, no se puede editar
    if (isEditing && _userRole != 'admin' && status != 'PENDIENTE') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solo se pueden editar incidencias en estado PENDIENTE')),
      );
      return;
    }

    final periodController = TextEditingController(text: incidencia?['periodo'] ?? '2025 – 2026');
    final diasController = TextEditingController(text: incidencia?['dias']?.toString() ?? '');
    DateTime fechaInicio = incidencia != null ? DateTime.parse(incidencia['fecha_inicio']) : DateTime.now();
    DateTime fechaFin = incidencia != null ? DateTime.parse(incidencia['fecha_fin']) : DateTime.now().add(const Duration(days: 1));
    DateTime fechaRegreso = incidencia != null ? DateTime.parse(incidencia['fecha_regreso']) : DateTime.now().add(const Duration(days: 2));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20, left: 20, right: 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Editar Incidencia' : 'Nueva Incidencia',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF344092)),
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFieldLabel('Nombre (Automático)'),
                Text(isEditing ? (incidencia['nombre_usuario'] ?? '...') : (_userFullName ?? '...'), style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildFieldLabel('Periodo'),
                DropdownButtonFormField<String>(
                  value: periodController.text,
                  items: ['2020 – 2021', '2021 – 2022', '2022 – 2023', '2024 – 2025', '2025 – 2026']
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (val) => periodController.text = val!,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                _buildFieldLabel('Días'),
                TextField(
                  controller: diasController,
                  keyboardType: TextInputType.number,
                  maxLength: 2,
                  decoration: const InputDecoration(border: OutlineInputBorder(), counterText: ""),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDatePicker('Fecha Inicio', fechaInicio, (d) => setModalState(() => fechaInicio = d)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDatePicker('Fecha Final', fechaFin, (d) => setModalState(() => fechaFin = d)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDatePicker('Fecha Regreso', fechaRegreso, (d) => setModalState(() => fechaRegreso = d)),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (diasController.text.isEmpty) return;
                      
                      final data = {
                        if (!isEditing) 'nombre_usuario': _userFullName,
                        'periodo': periodController.text,
                        'dias': int.parse(diasController.text),
                        'fecha_inicio': fechaInicio.toIso8601String(),
                        'fecha_fin': fechaFin.toIso8601String(),
                        'fecha_regreso': fechaRegreso.toIso8601String(),
                        if (!isEditing) 'usuario_id': Supabase.instance.client.auth.currentUser!.id,
                      };

                      try {
                        if (isEditing) {
                          await Supabase.instance.client.from('incidencias').update(data).eq('id', incidencia['id']);
                        } else {
                          await Supabase.instance.client.from('incidencias').insert(data);
                          // Notificar a administradores (global)
                          await NotificationService.send(
                            title: 'Nueva Incidencia',
                            message: '$_userFullName ha creado una nueva petición.',
                            type: 'new_incidencia',
                          );
                        }
                        if (mounted) {
                          Navigator.pop(context);
                          _fetchIncidencias();
                        }
                      } catch (e) {
                        debugPrint('Error saving incidencia: $e');
                      }
                    },
                    child: Text(isEditing ? 'GUARDAR CAMBIOS' : 'CREAR PETICIÓN'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
  );

  Widget _buildDatePicker(String label, DateTime current, Function(DateTime) onPick) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        InkWell(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: current,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (d != null) onPick(d);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${current.day}/${current.month}/${current.year}'),
                const Icon(Icons.calendar_today, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showIncidenciaForm(),
        backgroundColor: theme.colorScheme.secondary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('NUEVO'),
      ),
      body: Column(
        children: [
          PageHeader(
            title: 'Incidencias y Peticiones',
            subtitle: 'Total: ${_incidencias.length} registros',
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _incidencias.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final inc = _incidencias[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey[200]!),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        title: Text(
                          inc['nombre_usuario'] ?? 'Usuario',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Días: ${inc['dias']} | Creado: ${_formatDate(inc['created_at'])}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(inc['status']).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                inc['status'],
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(inc['status']),
                                ),
                              ),
                            ),
                            if (_userRole == 'admin') 
                              PopupMenuButton<String>(
                                onSelected: (val) async {
                                  if (val == 'EDIT') {
                                    _showIncidenciaForm(incidencia: inc);
                                  } else {
                                    await Supabase.instance.client.from('incidencias').update({'status': val}).eq('id', inc['id']);
                                    // Notificar al usuario del cambio de estado
                                    await NotificationService.send(
                                      title: 'Tu incidencia fue $val',
                                      message: 'El estado de tu petición ha cambiado a $val.',
                                      userId: inc['usuario_id'],
                                      type: 'incidencia_status',
                                    );
                                    _fetchIncidencias();
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(value: 'EDIT', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Editar'), dense: true)),
                                  const PopupMenuDivider(),
                                  const PopupMenuItem(value: 'APROBADA', child: Text('Aprobar')),
                                  const PopupMenuItem(value: 'CANCELADA', child: Text('Cancelar')),
                                  const PopupMenuItem(value: 'PENDIENTE', child: Text('Pendiente')),
                                ],
                              )
                            else if (inc['status'] == 'PENDIENTE')
                              IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _showIncidenciaForm(incidencia: inc)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIconData(String status) {
    switch (status) {
      case 'APROBADA': return Icons.check_circle_outline;
      case 'CANCELADA': return Icons.cancel_outlined;
      default: return Icons.pending_outlined;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'APROBADA': return Colors.green;
      case 'CANCELADA': return Colors.red;
      default: return Colors.orange;
    }
  }

  Widget _getStatusIcon(String status) {
    return Icon(_getStatusIconData(status), color: _getStatusColor(status));
  }

  String _formatDate(String iso) {
    final d = DateTime.parse(iso);
    return '${d.day}/${d.month}/${d.year}';
  }
}
