import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/property_mini_card.dart';
import 'screens/property_form_screen.dart'; // အခုလေးတင်ရေးခဲ့သော Form ဖိုင်ကို လှမ်းချိတ်ခြင်း

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
    // ဤနေရာတွင် သင်တောင်းဆိုထားသော Back ခလုတ် ထိန်းချုပ်သည့်စနစ် (PopScope) ကို ထည့်သွင်းထားပါသည်
    return PopScope(
      canPop: false, // အလိုအလျောက် App ပြင်ပသို့ ထွက်သွားခြင်းကို ပိတ်ထားသည်
      onPopInvoked: (didPop) {
        if (didPop) return;

        // ညာဘက် Option Drawer ပွင့်နေလျှင် Drawer ကိုသာ ပိတ်မည်
        if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
          Navigator.of(context).pop();
        } 
        // Home tab တွင် မဟုတ်ပါက Home သို့ ပြန်သွားမည်
        else if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        } 
        // Home tab လည်းဖြစ် Drawer လည်း မပွင့်နေမှသာ App ထဲမှ ထွက်မည်
        else {
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
        body: _currentIndex == 0
            ? ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 80), 
                itemCount: 5, 
                itemBuilder: (context, index) {
                  return PropertyMiniCard(
                    title: 'လှိုင်မြို့နယ်ရှိ 2RC လုံးချင်းအိမ်သစ် ${index + 1}',
                    askingPriceLakhs: 1500 + (index * 500), 
                    location: 'လှိုင်မြို့နယ်',
                    status: index % 2 == 0 ? 'Available' : 'Sold Out',
                    east: 40,
                    west: 40,
                    south: 60,
                    north: 60,
                    isSynced: index != 2, 
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
          onPressed: () {
            // အပေါင်း (+) ခလုတ်နှိပ်ပါက Form စာမျက်နှာသို့ ကူးပြောင်းစေမည့် Code
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PropertyFormScreen()),
            );
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
