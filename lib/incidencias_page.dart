import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
          .select('role, cssi_contributors(nombre, paterno, materno)')
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null) {
        final contrib = profile['cssi_contributors'];
        final fullName = contrib != null 
            ? '${contrib['nombre']} ${contrib['paterno']} ${contrib['materno'] ?? ''}'.trim()
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
          _incidencias = List<Map<String, dynamic>>.from(response);
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
                Text(_userFullName ?? '...', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                        'nombre_usuario': _userFullName,
                        'periodo': periodController.text,
                        'dias': int.parse(diasController.text),
                        'fecha_inicio': fechaInicio.toIso8601String(),
                        'fecha_fin': fechaFin.toIso8601String(),
                        'fecha_regreso': fechaRegreso.toIso8601String(),
                        'usuario_id': Supabase.instance.client.auth.currentUser!.id,
                      };

                      try {
                        if (isEditing) {
                          await Supabase.instance.client.from('incidencias').update(data).eq('id', incidencia['id']);
                        } else {
                          await Supabase.instance.client.from('incidencias').insert(data);
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
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _incidencias.length,
            itemBuilder: (context, index) {
              final inc = _incidencias[index];
              return Card(
                child: ListTile(
                  leading: _getStatusIcon(inc['status']),
                  title: Text(inc['periodo']),
                  subtitle: Text('Días: ${inc['dias']} | Inicio: ${_formatDate(inc['fecha_inicio'])}'),
                  trailing: _userRole == 'admin' 
                    ? PopupMenuButton<String>(
                        onSelected: (val) async {
                          await Supabase.instance.client.from('incidencias').update({'status': val}).eq('id', inc['id']);
                          _fetchIncidencias();
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 'APROBADA', child: Text('Aprobar')),
                          const PopupMenuItem(value: 'CANCELADA', child: Text('Cancelar')),
                          const PopupMenuItem(value: 'PENDIENTE', child: Text('Pendiente')),
                        ],
                      )
                    : (inc['status'] == 'PENDIENTE' 
                        ? IconButton(icon: const Icon(Icons.edit), onPressed: () => _showIncidenciaForm(incidencia: inc))
                        : null),
                ),
              );
            },
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showIncidenciaForm(),
        label: const Text('Nueva Petición'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'APROBADA': return const Icon(Icons.check_circle, color: Colors.green);
      case 'CANCELADA': return const Icon(Icons.cancel, color: Colors.red);
      default: return const Icon(Icons.pending, color: Colors.orange);
    }
  }

  String _formatDate(String iso) {
    final d = DateTime.parse(iso);
    return '${d.day}/${d.month}/${d.year}';
  }
}
