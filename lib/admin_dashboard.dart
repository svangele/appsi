import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _collaborators = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _fetchCollaborators();
  }

  Future<void> _fetchCollaborators() async {
    try {
      final data = await Supabase.instance.client
          .from('cssi_contributors')
          .select('id, nombre, paterno, materno, numero_empleado')
          .order('nombre');
      setState(() => _collaborators = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('Error fetching collaborators: $e');
    }
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .order('created_at', ascending: false);
      setState(() => _users = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar usuarios: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUser(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 32),
                  const SizedBox(width: 12),
                  Text(
                    'Eliminar Usuario',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                '¿Estás seguro de que deseas eliminar este perfil? Esta acción no se puede deshacer.',
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('CANCELAR'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('ELIMINAR'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await Supabase.instance.client.rpc('delete_user_admin', params: {'user_id': id});
        _fetchUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario y perfil eliminados correctamente')),
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

  void _showUserForm({Map<String, dynamic>? user}) {
    final isEditing = user != null;
    final nameController = TextEditingController(text: user?['full_name']);
    final employeeNumberController = TextEditingController(text: user?['numero_empleado']);
    final emailController = TextEditingController(text: user?['email']);
    final passwordController = TextEditingController();
    String role = user?['role'] ?? 'usuario';
    String? selectedCssiId = user?['cssi_id'];
    bool isBlocked = user?['is_blocked'] ?? false;

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
                          isEditing ? 'Editar Usuario' : 'Crear Nuevo Usuario',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Correo Electrónico', prefixIcon: Icon(Icons.email)),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      if (!isEditing) ...[
                        TextField(
                          controller: passwordController,
                          decoration: const InputDecoration(labelText: 'Contraseña', prefixIcon: Icon(Icons.lock)),
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
                      ],
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nombre Completo', prefixIcon: Icon(Icons.person)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: employeeNumberController,
                      decoration: const InputDecoration(labelText: 'Número de Empleado', prefixIcon: Icon(Icons.badge_outlined)),
                      readOnly: true, // Only filled via collaborator selection
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String?>(
                      value: selectedCssiId,
                      decoration: const InputDecoration(
                        labelText: 'Vincular con Colaborador CSSI (Opcional)',
                        prefixIcon: Icon(Icons.link),
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Ninguno / Externo'),
                        ),
                        ..._collaborators.map((colab) {
                          final fullName = '${colab['nombre']} ${colab['paterno']}';
                          final numEmp = colab['numero_empleado'] ?? 'N/A';
                          return DropdownMenuItem<String?>(
                            value: colab['id'],
                            child: Text('$numEmp | $fullName'),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setDialogState(() {
                          selectedCssiId = val;
                          if (val != null) {
                            final colab = _collaborators.firstWhere((c) => c['id'] == val);
                            nameController.text = '${colab['nombre']} ${colab['paterno']} ${colab['materno'] ?? ''}'.trim().toUpperCase();
                            employeeNumberController.text = colab['numero_empleado'] ?? '';
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: role,
                      decoration: const InputDecoration(labelText: 'Rol del Sistema', prefixIcon: Icon(Icons.admin_panel_settings)),
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'usuario', child: Text('Usuario')),
                        DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                      ],
                      onChanged: (val) => setDialogState(() => role = val!),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Estado de la Cuenta'),
                      subtitle: Text(isBlocked ? 'BLOQUEADA' : 'ACTIVA'),
                      secondary: Icon(isBlocked ? Icons.block : Icons.check_circle, color: isBlocked ? Colors.red : Colors.green),
                      value: !isBlocked,
                      onChanged: (val) => setDialogState(() => isBlocked = !val),
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
                              if (!isEditing) {
                                if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Correo y contraseña son obligatorios')),
                                  );
                                  return;
                                }
                                if (passwordController.text.trim().length < 8) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('La contraseña debe tener al menos 8 caracteres')),
                                  );
                                  return;
                                }
                              }
                              try {
                                if (isEditing) {
                                  await Supabase.instance.client.rpc('update_user_admin', params: {
                                    'user_id_param': user['id'],
                                    'new_email': emailController.text.trim(),
                                    'new_full_name': nameController.text.trim(),
                                    'new_role': role,
                                    'new_cssi_id': selectedCssiId,
                                    'new_numero_empleado': employeeNumberController.text.trim(),
                                    'is_blocked_param': isBlocked,
                                  });
                                } else {
                                  // 1. Create the user via RPC
                                  final response = await Supabase.instance.client.rpc('create_user_admin', params: {
                                    'email': emailController.text.trim(),
                                    'password': passwordController.text.trim(),
                                    'full_name': nameController.text.trim(),
                                    'user_role': role,
                                  });

                                  // 2. If we have a CSSI link, we need to update the newly created profile
                                  // The RPC should return the user ID. If not, we'll have to find it.
                                  if (selectedCssiId != null) {
                                    final userId = response as String?;
                                    if (userId != null) {
                                      await Supabase.instance.client.from('profiles').update({
                                        'cssi_id': selectedCssiId,
                                        'numero_empleado': employeeNumberController.text.trim(),
                                      }).eq('id', userId);
                                    }
                                  }
                                }
                                if (mounted) {
                                  Navigator.pop(context);
                                  _fetchUsers();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(isEditing ? 'Usuario actualizado' : 'Usuario creado con éxito'),
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

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    final query = _searchQuery.toLowerCase();
    return _users.where((user) {
      final name = (user['full_name'] ?? '').toString().toLowerCase();
      final role = (user['role'] ?? '').toString().toLowerCase();
      final numEmp = (user['numero_empleado'] ?? '').toString().toLowerCase();
      return name.contains(query) || role.contains(query) || numEmp.contains(query);
    }).toList();
  }

  Widget _buildShimmerItem() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(backgroundColor: Colors.grey[200]),
        title: Container(height: 14, width: 120, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4))),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(height: 10, width: 60, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4))),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final users = _filteredUsers;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserForm(),
        backgroundColor: theme.colorScheme.secondary,
        icon: const Icon(Icons.person_add),
        label: const Text('NUEVO USUARIO'),
      ),
      body: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  color: theme.colorScheme.primary.withValues(alpha: 0.05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Panel de Control',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total: ${_users.length} usuarios registrados',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre o rol...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (value) => setState(() => _searchQuery = value),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: 6,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, __) => _buildShimmerItem(),
                        )
                      : RefreshIndicator(
                    onRefresh: _fetchUsers,
                    child: users.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 80),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.person_search, size: 64, color: Colors.grey[300]),
                                    const SizedBox(height: 16),
                                    Text(
                                      _searchQuery.isNotEmpty ? 'Sin resultados para "$_searchQuery"' : 'No hay usuarios registrados',
                                      style: TextStyle(color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: users.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final String role = user['role'] ?? 'usuario';
                        
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey[200]!),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: role == 'admin' 
                                  ? theme.colorScheme.tertiary.withValues(alpha: 0.1)
                                  : theme.colorScheme.secondary.withValues(alpha: 0.1),
                              child: Icon(
                                role == 'admin' ? Icons.admin_panel_settings : Icons.person_outline,
                                color: role == 'admin' 
                                    ? theme.colorScheme.tertiary 
                                    : theme.colorScheme.secondary,
                              ),
                            ),
                            title: Text(
                              '${user['numero_empleado'] != null ? '${user['numero_empleado']} | ' : ''}${user['full_name'] ?? 'Usuario sin nombre'}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: (user['is_blocked'] ?? false) ? TextDecoration.lineThrough : null,
                                color: (user['is_blocked'] ?? false) ? Colors.grey : null,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user['email'] ?? 'Sin correo', style: const TextStyle(fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: role == 'admin' 
                                              ? theme.colorScheme.tertiary.withValues(alpha: 0.1)
                                              : theme.colorScheme.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          role.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: role == 'admin' 
                                                ? theme.colorScheme.tertiary 
                                                : theme.colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                      if (user['is_blocked'] ?? false) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'BLOQUEADO',
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
                                  onPressed: () => _showUserForm(user: user),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () => _deleteUser(user['id']),
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
