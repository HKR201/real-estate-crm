import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// သင်၏ Supabase URL နှင့် Key များကို ဤနေရာတွင် အစားထိုးပါ။
const String supabaseUrl = 'YOUR_SUPABASE_URL';
const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

void main() async {
  // Flutter အခြေခံစနစ်များကို အရင်အသက်သွင်းပါမယ်
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase (Cloud Database) ကို ချိတ်ဆက်ပါမယ်
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // ဖုန်းမျက်နှာပြင်အပြည့် (Edge-to-Edge) သုံးနိုင်ရန်နှင့် စနစ် Navigation Bar များကို ဖျောက်ထားရန်
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
      themeMode: ThemeMode.system, // ဖုန်း Setting အတိုင်း အလင်း/အမှောင် အလိုလို ပြောင်းပေးပါမယ်
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: const MainDashboard(),
    );
  }

  // သင်သတ်မှတ်ထားသော အရောင်များ (Color Palette) နှင့် 8px ထောင့်ဝိုင်းဒီဇိုင်းများ
  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: isDark ? const Color(0xFF4DB6AC) : const Color(0xFF008080),
        brightness: brightness,
        surface: isDark ? const Color(0xFF1E2626) : const Color(0xFFFFFFFF),
        // Deprecated မဖြစ်စေရန် background အစား surface တွင်သာ အဓိက အရောင်များ သုံးထားပါသည်
      ),
      scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F8F8),
      cardTheme: CardTheme(
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); // Option (Drawer) ဖွင့်ရန် Key

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('CRM Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // ရှာဖွေရေး အပိုင်း လာပါမည်
            },
          ),
        ],
      ),
      // Option Menu (ဘေးမှ ထွက်လာမည့် Drawer)
      drawer: Drawer(
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
      // ညာဘက်အောက်ထောင့်ရှိ အပေါင်း (+) ခလုတ်
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        onPressed: () {
          // Tab အလိုက် အသစ်ထည့်ရန် ဖောင်များ ပွင့်လာပါမည်
        },
        child: const Icon(Icons.add),
      ),
      // အောက်ခြေ Navigation (Edge-to-Edge နှင့် အဆင်ပြေစေရန် NavigationBar ကိုသုံးထားပါသည်)
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex == 2 ? 0 : _currentIndex, // Option နှိပ်လျှင် Drawer သာပွင့်ရန်
        onDestinationSelected: (index) {
          if (index == 2) {
            _scaffoldKey.currentState?.openDrawer(); // Option ကိုနှိပ်လျှင် ဘေးမှ Drawer ထွက်လာပါမည်
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
