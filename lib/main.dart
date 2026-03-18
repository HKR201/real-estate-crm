import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// သင်၏ Supabase URL နှင့် Key များကို ဤနေရာတွင် အစားထိုးပါ။
const String supabaseUrl = 'YOUR_SUPABASE_URL';
const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      statusBarColor: Colors.transparent,
    ),
  );

  runApp(const RealEstateCrmApp());
}

class RealEstateCrmApp extends StatelessWidget {
  const RealEstateCrmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real Estate CRM',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system, 
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: const MainDashboard(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: isDark ? const Color(0xFF4DB6AC) : const Color(0xFF008080),
        brightness: brightness,
        surface: isDark ? const Color(0xFF1E2626) : const Color(0xFFFFFFFF),
      ),
      scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F8F8),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        automaticallyImplyLeading: false, 
        title: const Text('CRM Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // ရှာဖွေရေး ခလုတ် (Search)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          // မှတ်ချက် - AppBar တွင် actions ထည့်ထားသောကြောင့် Flutter သည် ညာဘက်တွင် default menu icon ကို အလိုအလျောက် ထည့်ပေးတော့မည်မဟုတ်ပါ။
        ],
      ),
      // ဤနေရာတွင် drawer အစား endDrawer သို့ ပြောင်းလဲလိုက်ပါသည် (ညာဘက်မှ ထွက်လာရန်)
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF008080)),
              child: Text('Options', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Owner List'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.cloud_sync),
              title: const Text('Cloud Sync (Manual)'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Recycle Bin'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {},
            ),
          ],
        ),
      ),
      body: Center(
        child: Text(
          _currentIndex == 0 ? 'Home (Listing) ဖော်ပြမည့်နေရာ' : 'Buyer (ဝယ်လက်) ဖော်ပြမည့်နေရာ',
          style: const TextStyle(fontSize: 18),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex == 2 ? 0 : _currentIndex, 
        onDestinationSelected: (index) {
          if (index == 2) {
            // Option ကိုနှိပ်လျှင် ညာဘက်မှ Drawer ပွင့်လာစေရန် openEndDrawer ကို ပြောင်းသုံးထားပါသည်
            _scaffoldKey.currentState?.openEndDrawer(); 
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.person_search_outlined), selectedIcon: Icon(Icons.person_search), label: 'Buyer'),
          NavigationDestination(icon: Icon(Icons.menu), label: 'Option'),
        ],
      ),
    );
  }
}
