import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IssiPage extends StatefulWidget {
  const IssiPage({super.key});

  @override
  State<IssiPage> createState() => _IssiPageState();
}

class _IssiPageState extends State<IssiPage> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _usuarios = [];
  bool _isLoading = true;

  static const List<String> _tipos = [
    'Laptop',
    'PC',
    'Impresora',
    'Celular',
    'Telefono',
    'Disco Duro',
    'Monitor',
    'Mouse',
  ];

  static const List<String> _condiciones = [
    'Nuevo',
    'Usado',
    'Dañado',
    'Sin Reparacion',
  ];

  @override
  void initState() {
    super.initState();
    _fetchItems();
    _fetchUsuarios();
  }

  Future<void> _fetchUsuarios() async {
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('id, full_name')
          .order('full_name');
      if (mounted) {
        setState(() {
          _usuarios = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint('Error fetching usuarios: $e');
    }
  }

  Future<void> _fetchItems() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('issi_inventory')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        _items = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching items: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar inventario: $e')),
        );
      }
    }
  }

  Future<void> _deleteItem(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Elemento'),
        content: const Text('¿Estás seguro de que deseas eliminar este elemento? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Supabase.instance.client.from('issi_inventory').delete().eq('id', id);
        _fetchItems();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Elemento eliminado correctamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showItemForm({Map<String, dynamic>? item}) {
    final isEditing = item != null;
    final ubicacionController = TextEditingController(text: item?['ubicacion']);
    final marcaController = TextEditingController(text: item?['marca']);
    final modeloController = TextEditingController(text: item?['modelo']);
    final nsController = TextEditingController(text: item?['n_s']);
    final imeiController = TextEditingController(text: item?['imei']);
    final cpuController = TextEditingController(text: item?['cpu']);
    final ssdController = TextEditingController(text: item?['ssd']);
    final ramController = TextEditingController(text: item?['ram']);
    final valorController = TextEditingController(
      text: item?['valor']?.toString() ?? '',
    );
    final observacionesController = TextEditingController(text: item?['observaciones']);
    
    String tipo = item?['tipo'] ?? _tipos.first;
    String condicion = item?['condicion'] ?? _condiciones.first;
    
    String? selectedUsuarioId = item?['usuario_id'];
    String? selectedUsuarioNombre = item?['usuario_nombre'];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: StatefulBuilder(
          builder: (context, setDialogState) => Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Editar Elemento' : 'Nuevo Elemento',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      value: selectedUsuarioId,
                      decoration: const InputDecoration(
                        labelText: 'Usuario *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      isExpanded: true,
                      items: _usuarios.map((u) => DropdownMenuItem(
                        value: u['id'] as String,
                        child: Text(u['full_name'] ?? 'Usuario'),
                      )).toList(),
                      onChanged: (val) {
                        final usuario = _usuarios.firstWhere((u) => u['id'] == val);
                        setDialogState(() {
                          selectedUsuarioId = val;
                          selectedUsuarioNombre = usuario['full_name'];
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: ubicacionController,
                      decoration: const InputDecoration(
                        labelText: 'Ubicación *',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: tipo,
                      decoration: const InputDecoration(
                        labelText: 'Tipo *',
                        prefixIcon: Icon(Icons.devices_outlined),
                      ),
                      isExpanded: true,
                      items: _tipos.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (val) => setDialogState(() => tipo = val!),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: marcaController,
                      decoration: const InputDecoration(
                        labelText: 'Marca *',
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: modeloController,
                      decoration: const InputDecoration(
                        labelText: 'Modelo *',
                        prefixIcon: Icon(Icons.label_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nsController,
                      decoration: const InputDecoration(
                        labelText: 'N/S',
                        prefixIcon: Icon(Icons.numbers),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: imeiController,
                      decoration: const InputDecoration(
                        labelText: 'IMEI',
                        prefixIcon: Icon(Icons.sim_card_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: cpuController,
                            decoration: const InputDecoration(
                              labelText: 'CPU',
                              prefixIcon: Icon(Icons.memory),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: ssdController,
                            decoration: const InputDecoration(
                              labelText: 'SSD',
                              prefixIcon: Icon(Icons.storage),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ramController,
                            decoration: const InputDecoration(
                              labelText: 'RAM',
                              prefixIcon: Icon(Icons.sd_card),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: valorController,
                            decoration: const InputDecoration(
                              labelText: 'Valor',
                              prefixIcon: Icon(Icons.attach_money),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: condicion,
                      decoration: const InputDecoration(
                        labelText: 'Condición *',
                        prefixIcon: Icon(Icons.health_and_safety_outlined),
                      ),
                      isExpanded: true,
                      items: _condiciones.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setDialogState(() => condicion = val!),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: observacionesController,
                      decoration: const InputDecoration(
                        labelText: 'Observaciones',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('CANCELAR'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (ubicacionController.text.isEmpty || marcaController.text.isEmpty || 
                                  modeloController.text.isEmpty || selectedUsuarioId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Completa los campos obligatorios (*)')),
                                );
                                return;
                              }

                              try {
                                final data = {
                                  'ubicacion': ubicacionController.text.trim(),
                                  'tipo': tipo,
                                  'marca': marcaController.text.trim(),
                                  'modelo': modeloController.text.trim(),
                                  'n_s': nsController.text.trim().isEmpty ? null : nsController.text.trim(),
                                  'imei': imeiController.text.trim().isEmpty ? null : imeiController.text.trim(),
                                  'cpu': cpuController.text.trim().isEmpty ? null : cpuController.text.trim(),
                                  'ssd': ssdController.text.trim().isEmpty ? null : ssdController.text.trim(),
                                  'ram': ramController.text.trim().isEmpty ? null : ramController.text.trim(),
                                  'valor': valorController.text.trim().isEmpty ? null : double.tryParse(valorController.text.trim()),
                                  'condicion': condicion,
                                  'observaciones': observacionesController.text.trim().isEmpty ? null : observacionesController.text.trim(),
                                  'usuario_id': selectedUsuarioId,
                                  'usuario_nombre': selectedUsuarioNombre,
                                };

                                if (isEditing) {
                                  await Supabase.instance.client.from('issi_inventory').update(data).eq('id', item['id']);
                                } else {
                                  await Supabase.instance.client.from('issi_inventory').insert(data);
                                }

                                if (mounted) {
                                  Navigator.pop(context);
                                  _fetchItems();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(isEditing ? 'Elemento actualizado' : 'Elemento creado con éxito'),
                                      backgroundColor: const Color(0xFFB1CB34),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                            child: Text(isEditing ? 'GUARDAR' : 'CREAR'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showItemForm(),
        backgroundColor: theme.colorScheme.secondary,
        icon: const Icon(Icons.add),
        label: const Text('NUEVO'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  color: theme.colorScheme.primary.withOpacity(0.05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ISSI - Inventario',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total: ${_items.length} elementos registrados',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text('No hay elementos en el inventario', style: TextStyle(color: Colors.grey[500])),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchItems,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _items.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              
                              return Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: Colors.grey[200]!),
                                ),
                                child: ExpansionTile(
                                  tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                                  leading: CircleAvatar(
                                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                                    child: Icon(
                                      _getIconForType(item['tipo']),
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  title: Text(
                                    '${item['marca']} ${item['modelo']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            item['tipo'].toString().toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _getColorForCondition(item['condicion']).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            item['condicion'].toString().toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: _getColorForCondition(item['condicion']),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
                                        onPressed: () => _showItemForm(item: item),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                        onPressed: () => _deleteItem(item['id']),
                                      ),
                                    ],
                                  ),
                                  children: [
                                    _buildDetailRow('Ubicación', item['ubicacion']),
                                    if (item['n_s'] != null) _buildDetailRow('N/S', item['n_s']),
                                    if (item['imei'] != null) _buildDetailRow('IMEI', item['imei']),
                                    if (item['cpu'] != null) _buildDetailRow('CPU', item['cpu']),
                                    if (item['ssd'] != null) _buildDetailRow('SSD', item['ssd']),
                                    if (item['ram'] != null) _buildDetailRow('RAM', item['ram']),
                                    if (item['valor'] != null) _buildDetailRow('Valor', '\$${item['valor']}'),
                                    if (item['observaciones'] != null) _buildDetailRow('Observaciones', item['observaciones']),
                                    _buildDetailRow('Registrado por', item['usuario_nombre'] ?? 'Usuario'),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String tipo) {
    switch (tipo) {
      case 'Laptop':
        return Icons.laptop_mac;
      case 'PC':
        return Icons.desktop_mac;
      case 'Impresora':
        return Icons.print;
      case 'Celular':
        return Icons.smartphone;
      case 'Telefono':
        return Icons.phone;
      case 'Disco Duro':
        return Icons.storage;
      case 'Monitor':
        return Icons.monitor;
      case 'Mouse':
        return Icons.mouse;
      default:
        return Icons.devices_other;
    }
  }

  Color _getColorForCondition(String condicion) {
    switch (condicion) {
      case 'Nuevo':
        return Colors.green;
      case 'Usado':
        return Colors.orange;
      case 'Dañado':
        return Colors.red;
      case 'Sin Reparacion':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }
}
