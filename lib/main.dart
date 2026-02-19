import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'admin_dashboard.dart';
import 'user_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SB_URL');
  const supabaseAnonKey = String.fromEnvironment('SB_TOKEN');

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    debugPrint('Supabase: Config detectada. URL: $supabaseUrl');
    debugPrint('Supabase: Token detectado (inicio/fin): ${supabaseAnonKey.substring(0, 5)}...${supabaseAnonKey.substring(supabaseAnonKey.length - 5)}');
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  } else {
    debugPrint('Supabase: ERROR - Variables SB_URL o SB_TOKEN están VACÍAS');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Sisol Auth',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthRouter(),
    );
  }
}

class AuthRouter extends StatefulWidget {
  const AuthRouter({super.key});

  @override
  State<AuthRouter> createState() => _AuthRouterState();
}

class _AuthRouterState extends State<AuthRouter> {
  User? _user;
  String? _role;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _listenToAuth();
  }

  void _listenToAuth() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (mounted) {
        setState(() {
          _user = session?.user;
          if (_user == null) {
            _role = null;
            _isLoading = false;
          } else {
            _fetchRole();
          }
        });
      }
    });
  }

  Future<void> _fetchRole() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', _user!.id)
          .single();
      if (mounted) {
        setState(() {
          _role = data['role'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error obteniendo rol: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_user == null) {
      return const LoginPage();
    }

    if (_role == 'admin') {
      return const AdminDashboard();
    }

    return const UserDashboard();
  }
}
