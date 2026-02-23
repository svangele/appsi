import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

class CssiPage extends StatefulWidget {
  const CssiPage({super.key});

  @override
  State<CssiPage> createState() => _CssiPageState();
}

class _CssiPageState extends State<CssiPage> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 0;
  static const int _itemsPerPage = 20;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('cssi_contributors')
          .select()
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _items = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching CSSI: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar colaboradores: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredItems {
    var result = _items;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((item) {
        final name = '${item['nombre']} ${item['paterno']} ${item['materno'] ?? ''}'.toLowerCase();
        final curp = (item['curp'] ?? '').toString().toLowerCase();
        final rfc = (item['rfc'] ?? '').toString().toLowerCase();
        final area = (item['area'] ?? '').toString().toLowerCase();
        final puesto = (item['puesto'] ?? '').toString().toLowerCase();
        final numEmp = (item['numero_empleado'] ?? '').toString().toLowerCase();
        return name.contains(query) || curp.contains(query) || rfc.contains(query) || area.contains(query) || puesto.contains(query) || numEmp.contains(query);
      }).toList();
    }
    return result;
  }

  List<Map<String, dynamic>> get _paginatedItems {
    final filtered = _filteredItems;
    final start = _currentPage * _itemsPerPage;
    if (start >= filtered.length) return [];
    final end = (start + _itemsPerPage).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  int get _totalPages => (_filteredItems.length / _itemsPerPage).ceil().clamp(1, 9999);

  void _exportCsv() {
    final filtered = _filteredItems;
    if (filtered.isEmpty) return;

    final headers = ['Num. Empleado', 'Nombre', 'Paterno', 'Materno', 'CURP', 'RFC', 'Puesto', 'Área', 'Ubicación', 'Correo'];
    final rows = filtered.map((item) => [
      item['numero_empleado'] ?? '',
      item['nombre'] ?? '',
      item['paterno'] ?? '',
      item['materno'] ?? '',
      item['curp'] ?? '',
      item['rfc'] ?? '',
      item['puesto'] ?? '',
      item['area'] ?? '',
      item['ubicacion'] ?? '',
      item['correo_personal'] ?? '',
    ].map((f) => '"${f.toString().replaceAll('"', '""')}"').join(',')).toList();

    final csv = [headers.join(','), ...rows].join('\n');
    debugPrint('CSV Export CSSI: ${rows.length} records');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV generado con ${rows.length} colaboradores'), backgroundColor: const Color(0xFFB1CB34)),
    );
  }

  void _deleteItem(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Colaborador'),
        content: const Text('¿Estás seguro de eliminar este registro?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('ELIMINAR')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Supabase.instance.client.from('cssi_contributors').delete().eq('id', id);
        _fetchItems();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showForm({Map<String, dynamic>? item}) {
    final isEditing = item != null;
    bool saving = false;
    
    final nombreCtrl = TextEditingController(text: item?['nombre']);
    final paternoCtrl = TextEditingController(text: item?['paterno']);
    final maternoCtrl = TextEditingController(text: item?['materno']);
    final curpCtrl = TextEditingController(text: item?['curp']);
    final rfcCtrl = TextEditingController(text: item?['rfc']);
    final imssCtrl = TextEditingController(text: item?['imss']);
    final numeroEmpleadoCtrl = TextEditingController(text: item?['numero_empleado']);
    
    final fechaNacCtrl = TextEditingController(text: item?['fecha_nacimiento']);
    final tallaCtrl = TextEditingController(text: item?['talla']);
    final detalleEscolCtrl = TextEditingController(text: item?['detalle_escolaridad']);
    
    final calleCtrl = TextEditingController(text: item?['calle']);
    final noCalleCtrl = TextEditingController(text: item?['no_calle']);
    final coloniaCtrl = TextEditingController(text: item?['colonia']);
    final municipioCtrl = TextEditingController(text: item?['municipio_alcaldia']);
    final estadoFedCtrl = TextEditingController(text: item?['estado_federal']);
    final cpCtrl = TextEditingController(text: item?['codigo_postal']);
    
    final telCtrl = TextEditingController(text: item?['telefono']);
    final celCtrl = TextEditingController(text: item?['celular']);
    final correoCtrl = TextEditingController(text: item?['correo_personal']);
    
    final bancoCtrl = TextEditingController(text: item?['banco']);
    final cuentaCtrl = TextEditingController(text: item?['cuenta']);
    final clabeCtrl = TextEditingController(text: item?['clabe']);
    
    final areaCtrl = TextEditingController(text: item?['area']);
    final puestoCtrl = TextEditingController(text: item?['puesto']);
    final ubicacionCtrl = TextEditingController(text: item?['ubicacion']);
    final empresaCtrl = TextEditingController(text: item?['empresa']);
    final jefeCtrl = TextEditingController(text: item?['jefe_inmediato']);
    final liderCtrl = TextEditingController(text: item?['lider']);
    final gerenteCtrl = TextEditingController(text: item?['gerente_regional']);
    final directorCtrl = TextEditingController(text: item?['director']);
    
    final reclutaCtrl = TextEditingController(text: item?['recluta']);
    final reclutadorCtrl = TextEditingController(text: item?['reclutador']);
    final fuenteCtrl = TextEditingController(text: item?['fuente_reclutamiento']);
    final fuenteEspecCtrl = TextEditingController(text: item?['fuente_reclutamiento_espec']);
    final obsCtrl = TextEditingController(text: item?['observaciones']);
    
    final refNombreCtrl = TextEditingController(text: item?['referencia_nombre']);
    final refTelCtrl = TextEditingController(text: item?['referencia_telefono']);
    final refRelacionCtrl = TextEditingController(text: item?['referencia_relacion']);

    String? genero = item?['genero'];
    String? estadoCivil = item?['estado_civil'];
    String? escolaridad = item?['escolaridad'];
    String? credito = item?['credito'];
    String? statusSys = item?['status_sys'] ?? 'ACTIVO';
    String? statusRh = item?['status_rh'] ?? 'ACTIVO';
    XFile? pickedFile;
    String? currentFotoUrl = item?['foto_url'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            return Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                Padding(
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Editar Colaborador' : 'Nuevo Colaborador',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionTitle('SI Colaborador'),
                        Center(
                          child: GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
                              if (image != null) setDialogState(() => pickedFile = image);
                            },
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage: pickedFile != null 
                                    ? null // Will use child Image.file
                                    : (currentFotoUrl != null ? NetworkImage(currentFotoUrl) : null),
                                  child: pickedFile != null 
                                    ? ClipOval(child: Image.network(pickedFile!.path, fit: BoxFit.cover, width: 100, height: 100))
                                    : (currentFotoUrl == null ? const Icon(Icons.person, size: 50, color: Colors.grey) : null),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: statusSys,
                                decoration: const InputDecoration(labelText: 'Status Sys'),
                                items: ['ACTIVO', 'BAJA', 'CAMBIO', 'ELIMINAR'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                onChanged: (v) => setDialogState(() => statusSys = v),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: statusRh,
                                decoration: const InputDecoration(labelText: 'Status RH'),
                                items: ['ACTIVO', 'BAJA', 'CAMBIO', 'REINGRESO'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                onChanged: (v) => setDialogState(() => statusRh = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: numeroEmpleadoCtrl,
                          decoration: const InputDecoration(labelText: 'Número de Empleado *', hintText: '4 dígitos'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre *')),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: TextField(controller: paternoCtrl, decoration: const InputDecoration(labelText: 'Paterno *'))),
                            const SizedBox(width: 8),
                            Expanded(child: TextField(controller: maternoCtrl, decoration: const InputDecoration(labelText: 'Materno'))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: TextField(controller: curpCtrl, decoration: const InputDecoration(labelText: 'CURP'))),
                            const SizedBox(width: 8),
                            Expanded(child: TextField(controller: rfcCtrl, decoration: const InputDecoration(labelText: 'RFC'))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(controller: imssCtrl, decoration: const InputDecoration(labelText: 'IMSS')),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: credito,
                          decoration: const InputDecoration(labelText: 'Crédito'),
                          items: ['FOVISTE', 'INFONAVIT', 'OTRO'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (v) => setDialogState(() => credito = v),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: fechaNacCtrl,
                                decoration: const InputDecoration(labelText: 'Fecha Nacimiento', suffixIcon: Icon(Icons.calendar_today)),
                                readOnly: true,
                                onTap: () async {
                                  final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(1950), lastDate: DateTime.now());
                                  if (d != null) setDialogState(() => fechaNacCtrl.text = d.toString().split(' ').first);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: TextField(controller: tallaCtrl, decoration: const InputDecoration(labelText: 'Talla'))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: genero,
                                decoration: const InputDecoration(labelText: 'Género'),
                                items: ['FEMENINO', 'MASCULINO'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                onChanged: (v) => setDialogState(() => genero = v),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: estadoCivil,
                                decoration: const InputDecoration(labelText: 'Estado Civil'),
                                items: ['CASADO', 'SOLTERO', 'UNION LIBRE'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                onChanged: (v) => setDialogState(() => estadoCivil = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: escolaridad,
                          decoration: const InputDecoration(labelText: 'Escolaridad'),
                          items: ['PRIMARIA', 'SECUNDARIA', 'BACHILLERATO', 'CARRERA TECNICA', 'TSU', 'LICENCIATURA TRUNCA', 'LICENCIATURA PASANTE', 'LICENCIATURA TITULADO', 'POSGRADO', 'OTROS']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (v) => setDialogState(() => escolaridad = v),
                        ),
                        const SizedBox(height: 12),
                        TextField(controller: detalleEscolCtrl, decoration: const InputDecoration(labelText: 'Detalle Escolaridad'), maxLines: 2),

                        const SizedBox(height: 24),
                        _sectionTitle('Domicilio'),
                        Row(
                          children: [
                            Expanded(flex: 3, child: TextField(controller: calleCtrl, decoration: const InputDecoration(labelText: 'Calle'))),
                            const SizedBox(width: 8),
                            Expanded(child: TextField(controller: noCalleCtrl, decoration: const InputDecoration(labelText: 'No. Calle'))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(controller: coloniaCtrl, decoration: const InputDecoration(labelText: 'Colonia')),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: TextField(controller: municipioCtrl, decoration: const InputDecoration(labelText: 'Municipio/Alcaldía'))),
                            const SizedBox(width: 8),
                            Expanded(child: TextField(controller: cpCtrl, decoration: const InputDecoration(labelText: 'C.P.'))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(controller: estadoFedCtrl, decoration: const InputDecoration(labelText: 'Estado Federal')),

                        const SizedBox(height: 24),
                        _sectionTitle('Contacto Personal'),
                        Row(
                          children: [
                            Expanded(child: TextField(controller: telCtrl, decoration: const InputDecoration(labelText: 'Teléfono'))),
                            const SizedBox(width: 8),
                            Expanded(child: TextField(controller: celCtrl, decoration: const InputDecoration(labelText: 'Celular'))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(controller: correoCtrl, decoration: const InputDecoration(labelText: 'Correo Personal')),

                        const SizedBox(height: 24),
                        _sectionTitle('Datos Bancarios'),
                        TextField(controller: bancoCtrl, decoration: const InputDecoration(labelText: 'Banco')),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: TextField(controller: cuentaCtrl, decoration: const InputDecoration(labelText: 'Cuenta'))),
                            const SizedBox(width: 8),
                            Expanded(child: TextField(controller: clabeCtrl, decoration: const InputDecoration(labelText: 'Clabe'))),
                          ],
                        ),

                        const SizedBox(height: 24),
                        _sectionTitle('Datos Empresa'),
                        TextField(controller: empresaCtrl, decoration: const InputDecoration(labelText: 'Empresa')),
                        const SizedBox(height: 12),
                        TextField(controller: areaCtrl, decoration: const InputDecoration(labelText: 'Área')),
                        const SizedBox(height: 12),
                        TextField(controller: puestoCtrl, decoration: const InputDecoration(labelText: 'Puesto')),
                        const SizedBox(height: 12),
                        TextField(controller: ubicacionCtrl, decoration: const InputDecoration(labelText: 'Ubicación')),
                        const SizedBox(height: 12),
                        TextField(controller: jefeCtrl, decoration: const InputDecoration(labelText: 'Jefe Inmediato')),
                        const SizedBox(height: 12),
                        TextField(controller: liderCtrl, decoration: const InputDecoration(labelText: 'Líder')),
                        const SizedBox(height: 12),
                        TextField(controller: gerenteCtrl, decoration: const InputDecoration(labelText: 'Gerente Regional')),
                        const SizedBox(height: 12),
                        TextField(controller: directorCtrl, decoration: const InputDecoration(labelText: 'Director')),

                        const SizedBox(height: 24),
                        _sectionTitle('Area RH'),
                        TextField(controller: reclutaCtrl, decoration: const InputDecoration(labelText: 'Recluta')),
                        const SizedBox(height: 12),
                        TextField(controller: reclutadorCtrl, decoration: const InputDecoration(labelText: 'Reclutador')),
                        const SizedBox(height: 12),
                        TextField(controller: fuenteCtrl, decoration: const InputDecoration(labelText: 'Fuente de reclutamiento')),
                        const SizedBox(height: 12),
                        TextField(controller: fuenteEspecCtrl, decoration: const InputDecoration(labelText: 'Fuente espec.')),
                        const SizedBox(height: 12),
                        TextField(controller: obsCtrl, decoration: const InputDecoration(labelText: 'Observaciones'), maxLines: 2),

                        const SizedBox(height: 24),
                        _sectionTitle('Referencia'),
                        TextField(controller: refNombreCtrl, decoration: const InputDecoration(labelText: 'Nombre Referencia')),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: TextField(controller: refTelCtrl, decoration: const InputDecoration(labelText: 'Teléfono Ref.'))),
                            const SizedBox(width: 8),
                            Expanded(child: TextField(controller: refRelacionCtrl, decoration: const InputDecoration(labelText: 'Relación'))),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
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
                          onPressed: saving ? null : () async {
                            if (nombreCtrl.text.isEmpty || paternoCtrl.text.isEmpty || numeroEmpleadoCtrl.text.length != 4) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Nombre, Paterno y Num. Empleado (4 dígitos) son obligatorios'), 
                                  backgroundColor: Colors.red
                                )
                              );
                              return;
                            }
                            
                            setDialogState(() => saving = true);

                            String? toUpper(String val) => val.trim().isEmpty ? null : val.trim().toUpperCase();
                            
                            final data = {
                              'nombre': toUpper(nombreCtrl.text)!,
                              'paterno': toUpper(paternoCtrl.text)!,
                              'materno': toUpper(maternoCtrl.text),
                              'curp': toUpper(curpCtrl.text),
                              'rfc': toUpper(rfcCtrl.text),
                              'imss': toUpper(imssCtrl.text),
                              'credito': credito,
                              'fecha_nacimiento': fechaNacCtrl.text.isEmpty ? null : fechaNacCtrl.text,
                              'genero': genero,
                              'talla': toUpper(tallaCtrl.text),
                              'estado_civil': estadoCivil,
                              'escolaridad': escolaridad,
                              'detalle_escolaridad': toUpper(detalleEscolCtrl.text),
                              'calle': toUpper(calleCtrl.text),
                              'no_calle': toUpper(noCalleCtrl.text),
                              'colonia': toUpper(coloniaCtrl.text),
                              'municipio_alcaldia': toUpper(municipioCtrl.text),
                              'estado_federal': toUpper(estadoFedCtrl.text),
                              'codigo_postal': toUpper(cpCtrl.text),
                              'telefono': toUpper(telCtrl.text),
                              'celular': toUpper(celCtrl.text),
                              'correo_personal': toUpper(correoCtrl.text),
                              'banco': toUpper(bancoCtrl.text),
                              'cuenta': toUpper(cuentaCtrl.text),
                              'clabe': toUpper(clabeCtrl.text),
                              'area': toUpper(areaCtrl.text),
                              'puesto': toUpper(puestoCtrl.text),
                              'ubicacion': toUpper(ubicacionCtrl.text),
                              'empresa': toUpper(empresaCtrl.text),
                              'jefe_inmediato': toUpper(jefeCtrl.text),
                              'lider': toUpper(liderCtrl.text),
                              'gerente_regional': toUpper(gerenteCtrl.text),
                              'director': toUpper(directorCtrl.text),
                              'recluta': toUpper(reclutaCtrl.text),
                              'reclutador': toUpper(reclutadorCtrl.text),
                              'fuente_reclutamiento': toUpper(fuenteCtrl.text),
                              'fuente_reclutamiento_espec': toUpper(fuenteEspecCtrl.text),
                              'observaciones': toUpper(obsCtrl.text),
                              'referencia_nombre': toUpper(refNombreCtrl.text),
                              'referencia_telefono': toUpper(refTelCtrl.text),
                              'referencia_relacion': toUpper(refRelacionCtrl.text),
                              'numero_empleado': numeroEmpleadoCtrl.text.trim(),
                              'status_sys': statusSys,
                              'status_rh': statusRh,
                              'foto_url': currentFotoUrl,
                              'usuario_id': Supabase.instance.client.auth.currentUser?.id,
                              'usuario_nombre': 'ADMIN',
                            };

                            try {
                              if (pickedFile != null) {
                                final bytes = await pickedFile!.readAsBytes();
                                final fileExt = pickedFile!.path.split('.').last;
                                final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
                                final path = 'photos/$fileName';
                                
                                await Supabase.instance.client.storage.from('employee_photos').uploadBinary(path, bytes);
                                data['foto_url'] = Supabase.instance.client.storage.from('employee_photos').getPublicUrl(path);
                              }

                              if (isEditing) {
                                await Supabase.instance.client.from('cssi_contributors').update(data).eq('id', item['id']);
                              } else {
                                await Supabase.instance.client.from('cssi_contributors').insert(data);
                              }
                              if (mounted) {
                                Navigator.pop(context);
                                _fetchItems();
                              }
                            } catch (e) {
                               setDialogState(() => saving = false);
                               if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                            }
                          },
                          child: saving
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(isEditing ? 'GUARDAR' : 'CREAR'),
                        ),
                      ),
                    ],
                  ),
                ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF344092), fontSize: 13, letterSpacing: 1)),
        const Divider(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      itemBuilder: (context, index) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[200]!)),
        child: Container(
          height: 80,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: Colors.grey[100]),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(height: 12, width: 150, color: Colors.grey[100]),
                    const SizedBox(height: 8),
                    Container(height: 10, width: 100, color: Colors.grey[100]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredItems;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        backgroundColor: theme.colorScheme.secondary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('NUEVO'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Colaboradores SSI',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.download_outlined, color: theme.colorScheme.primary),
                      tooltip: 'Exportar CSV',
                      onPressed: _exportCsv,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Total: ${_items.length} colaboradores${filtered.length != _items.length ? ' (mostrando ${filtered.length})' : ''}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre, CURP, RFC...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() { _searchQuery = ''; });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? _buildShimmerLoading()
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.badge_outlined, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text('No se encontraron colaboradores', style: TextStyle(color: Colors.grey[500])),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchItems,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[200]!)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF344092).withValues(alpha: 0.1),
                                  backgroundImage: item['foto_url'] != null ? NetworkImage(item['foto_url']) : null,
                                  child: item['foto_url'] == null 
                                    ? Text(item['nombre'][0], style: const TextStyle(color: Color(0xFF344092), fontWeight: FontWeight.bold))
                                    : null,
                                ),
                                title: Text('${item['numero_empleado'] ?? '---'} | ${item['nombre']} ${item['paterno']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${item['puesto'] ?? 'Sin puesto'} - ${item['area'] ?? 'Sin área'}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
                                      onPressed: () => _showForm(item: item),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      onPressed: () => _deleteItem(item['id']),
                                    ),
                                  ],
                                ),
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
}
