import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/property_mini_card.dart';
import 'screens/property_form_screen.dart';
import 'db/database_helper.dart'; // Database မှ ဒေတာများ ဆွဲထုတ်ရန်

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

  // Database မှ ရလာမည့် အိမ်ခြံမြေစာရင်းများကို သိမ်းထားရန် နေရာ
  List<Map<String, dynamic>> _properties = [];
  bool _isLoading = true; // ဒေတာ ဆွဲထုတ်နေစဉ် လည်နေမည့် သင်္ကေတ ပြရန်

  @override
  void initState() {
    super.initState();
    _loadProperties(); // App စဖွင့်သည်နှင့် Database ထဲမှ ဒေတာများကို ဆွဲထုတ်မည်
  }

  // Database မှ ဒေတာ အစစ်များ ဆွဲထုတ်မည့် Function
  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllProperties();
    setState(() {
      _properties = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, 
      onPopInvoked: (didPop) {
        if (didPop) return;

        if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
          Navigator.of(context).pop();
        } else if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          automaticallyImplyLeading: false, 
          title: const Text('CRM Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {},
            ),
          ],
        ),
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
        // Home Tab တွင် Database မှ ရလာသော အချက်အလက်များကို ပြသမည်
        body: _currentIndex == 0
            ? _isLoading
                ? const Center(child: CircularProgressIndicator()) // ဆွဲထုတ်နေစဉ် လည်နေမည်
                : _properties.isEmpty
                    ? const Center(
                        child: Text(
                          'အိမ်ခြံမြေစာရင်း မရှိသေးပါ။\nအပေါင်း (+) ခလုတ်ကို နှိပ်၍ အသစ်ထည့်ပါ။',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ) // စာရင်းမရှိသေးလျှင် ပြမည့်စာသား
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 80), 
                        itemCount: _properties.length, 
                        itemBuilder: (context, index) {
                          final prop = _properties[index];
                          return PropertyMiniCard(
                            title: prop['title'] ?? 'အမည်မသိ',
                            askingPriceLakhs: prop['asking_price_lakhs'] ?? 0, 
                            location: prop['location_id'] ?? 'မသိရ',
                            status: prop['status'] ?? 'Available',
                            east: prop['east_ft'] ?? 0,
                            west: prop['west_ft'] ?? 0,
                            south: prop['south_ft'] ?? 0,
                            north: prop['north_ft'] ?? 0,
                            isSynced: false, // Cloud ပေါ် မရောက်သေးကြောင်း တိမ်တိုက်အိုင်ကွန်ပြရန်
                          );
                        },
                      )
            : const Center(
                child: Text(
                  'Buyer (ဝယ်လက်) ဖော်ပြမည့်နေရာ',
                  style: TextStyle(fontSize: 18),
                ),
              ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          onPressed: () async {
            // Form မှ 'သိမ်းမည်' နှိပ်ပြီး ပြန်လာပါက result သည် true ဖြစ်မည်
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PropertyFormScreen()),
            );
            
            // အသစ်ထည့်ပြီး ပြန်လာပါက Database ကို Refresh အလိုလို လုပ်ပေးမည်
            if (result == true) {
              _loadProperties();
            }
          },
          child: const Icon(Icons.add),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex == 2 ? 0 : _currentIndex, 
          onDestinationSelected: (index) {
            if (index == 2) {
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
      ),
    );
  }
}
