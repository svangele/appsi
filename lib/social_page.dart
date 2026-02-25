import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

class SocialPage extends StatefulWidget {
  const SocialPage({super.key});

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> {
  List<Map<String, dynamic>> _allBirthdays = [];
  bool _isLoading = true;
  int _selectedMonth = DateTime.now().month;

  final List<String> _months = [
    'ENERO', 'FEBRERO', 'MARZO', 'ABRIL', 'MAYO', 'JUNIO',
    'JULIO', 'AGOSTO', 'SEPTIEMBRE', 'OCTUBRE', 'NOVIEMBRE', 'DICIEMBRE'
  ];

  @override
  void initState() {
    super.initState();
    _fetchBirthdays();
  }

  Future<void> _fetchBirthdays() async {
    setState(() => _isLoading = true);
    try {
      // Obtenemos todos los colaboradores que tengan fecha de nacimiento
      final data = await Supabase.instance.client
          .from('cssi_contributors')
          .select('nombre, paterno, materno, fecha_nacimiento, foto_url')
          .not('fecha_nacimiento', 'is', null)
          .order('nombre');

      if (mounted) {
        setState(() {
          _allBirthdays = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching birthdays: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar cumpleaños: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredBirthdays {
    return _allBirthdays.where((item) {
      final fechaStr = item['fecha_nacimiento'] as String?;
      if (fechaStr == null || fechaStr.isEmpty) return false;
      try {
        final date = DateTime.parse(fechaStr);
        return date.month == _selectedMonth;
      } catch (_) {
        return false;
      }
    }).toList()
      ..sort((a, b) {
        final dateA = DateTime.parse(a['fecha_nacimiento']);
        final dateB = DateTime.parse(b['fecha_nacimiento']);
        return dateA.day.compareTo(dateB.day);
      });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final upcoming = _filteredBirthdays;

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(theme),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : upcoming.isEmpty
                    ? _buildEmptyState()
                    : _buildBirthdayList(upcoming, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cumpleaños 🎂',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: DropdownButton<int>(
                    value: _selectedMonth,
                    dropdownColor: theme.colorScheme.primary,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.calendar_month, color: Colors.white, size: 20),
                    items: List.generate(12, (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text(
                        _months[index],
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    )),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedMonth = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Celebrando a nuestros colaboradores en ${_months[_selectedMonth - 1]}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBirthdayList(List<Map<String, dynamic>> items, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final date = DateTime.parse(item['fecha_nacimiento']);
        final isToday = date.day == DateTime.now().day && date.month == DateTime.now().month;

        return Card(
          elevation: isToday ? 4 : 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isToday ? BorderSide(color: theme.colorScheme.secondary, width: 2) : BorderSide.none,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  backgroundImage: item['foto_url'] != null ? NetworkImage(item['foto_url']) : null,
                  child: item['foto_url'] == null 
                    ? Icon(Icons.person, color: theme.colorScheme.primary)
                    : null,
                ),
                if (isToday)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Transform.rotate(
                      angle: -0.2,
                      child: const Text('👑', style: TextStyle(fontSize: 16)),
                    ),
                  ),
              ],
            ),
            title: Text(
              '${item['nombre']} ${item['paterno']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${date.day} de ${_months[date.month - 1].toLowerCase()}',
              style: TextStyle(color: isToday ? theme.colorScheme.secondary : Colors.grey[600], fontWeight: isToday ? FontWeight.bold : FontWeight.normal),
            ),
            trailing: isToday 
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cake, color: Colors.orange),
                    Text('HOY!', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                )
              : Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${date.day}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                  ),
                ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cake_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No hay cumpleaños en ${_months[_selectedMonth - 1].toLowerCase()}',
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }
}
