import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert'; 
import 'package:supabase_flutter/supabase_flutter.dart';

import 'widgets/property_mini_card.dart';
import 'screens/property_form_screen.dart';
import 'screens/owner_list_screen.dart';
import 'screens/buyer_form_screen.dart'; 
import 'db/database_helper.dart';

const String supabaseUrl = 'YOUR_SUPABASE_URL';
const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(systemNavigationBarColor: Colors.transparent, statusBarColor: Colors.transparent),
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
      cardTheme: CardThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 2),
      inputDecorationTheme: InputDecorationTheme(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
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
  
  List<Map<String, dynamic>> _properties = [];
  List<Map<String, dynamic>> _buyers = [];
  
  bool _isLoading = true; 
  bool _isLoadingBuyers = true;

  @override
  void initState() {
    super.initState();
    _loadProperties(); 
    _loadBuyers(); 
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllProperties();
    setState(() {
      _properties = data;
      _isLoading = false;
    });
  }

  Future<void> _loadBuyers() async {
    setState(() => _isLoadingBuyers = true);
    final data = await DatabaseHelper.instance.getAllBuyers();
    setState(() {
      _buyers = data;
      _isLoadingBuyers = false;
    });
  }

  // --- ဝယ်လက်စာရင်းကို အမှိုက်ပုံးထဲပို့မည့် Function (Soft Delete) ---
  void _deleteBuyer(Map<String, dynamic> buyer) async {
    // ၁။ မျက်စိရှေ့တွင် ချက်ချင်းပျောက်သွားစေရန် List ထဲမှ ဖယ်ထုတ်လိုက်သည် (UI Update)
    setState(() {
      _buyers.removeWhere((b) => b['id'] == buyer['id']);
    });

    // ၂။ Database ထဲတွင် is_deleted = 1 ဟု ပြောင်းလိုက်သည်
    await DatabaseHelper.instance.moveToRecycleBin('crm_buyers', buyer['id']);

    // ၃။ ၅ စက္ကန့်အတွင်း ပြန်ယူခွင့်ပေးမည့် (Undo) Snackbar ပြသခြင်း
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('ဝယ်လက်စာရင်းကို ဖျက်လိုက်ပါပြီ'),
        duration: const Duration(seconds: 5), // ၅ စက္ကန့် ကြာမည်
        action: SnackBarAction(
          label: 'Undo (ပြန်ယူမည်)',
          textColor: Colors.yellow,
          onPressed: () async {
            // Undo နှိပ်ပါက Database တွင် is_deleted = 0 ဟု ပြန်ပြောင်းပေးမည်
            await DatabaseHelper.instance.restoreFromRecycleBin('crm_buyers', buyer['id']);
            _loadBuyers(); // စာရင်းကို ပြန်လည် ဆွဲတင်မည်
          },
        ),
      ),
    );
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
          setState(() => _currentIndex = 0);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          automaticallyImplyLeading: false, 
          title: const Text('CRM Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
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
                onTap: () {
                  Navigator.pop(context); 
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const OwnerListScreen()));
                }
              ),
              ListTile(leading: const Icon(Icons.cloud_sync), title: const Text('Cloud Sync (Manual)'), onTap: () {}),
              ListTile(leading: const Icon(Icons.delete_outline, color: Colors.red), title: const Text('Recycle Bin'), onTap: () {}),
              ListTile(leading: const Icon(Icons.settings), title: const Text('Settings'), onTap: () {}),
            ],
          ),
        ),
        
        body: _currentIndex == 0 ? _buildHomeTab() : _buildBuyerTab(),

        floatingActionButton: FloatingActionButton(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          onPressed: () async {
            if (_currentIndex == 0) {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const PropertyFormScreen()));
              if (result == true) _loadProperties();
            } else if (_currentIndex == 1) {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const BuyerFormScreen()));
              if (result == true) _loadBuyers();
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
              setState(() => _currentIndex = index);
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

  Widget _buildHomeTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_properties.isEmpty) {
      return const Center(child: Text('အိမ်ခြံမြေစာရင်း မရှိသေးပါ။', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80), 
      itemCount: _properties.length, 
      itemBuilder: (context, index) {
        return PropertyMiniCard(property: _properties[index], isSynced: false);
      },
    );
  }

  Widget _buildBuyerTab() {
    if (_isLoadingBuyers) return const Center(child: CircularProgressIndicator());
    if (_buyers.isEmpty) {
      return const Center(child: Text('ဝယ်လက်စာရင်း မရှိသေးပါ။\nအပေါင်း (+) ကိုနှိပ်၍ ထည့်ပါ။', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: _buyers.length,
      itemBuilder: (context, index) {
        final buyer = _buyers[index];
        List<dynamic> phones = [];
        try { phones = jsonDecode(buyer['phones'] ?? '[]'); } catch (_) {}
        
        final budget = (buyer['budget_lakhs'] ?? 0)
            .toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(buyer['name'] ?? 'အမည်မသိ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red, size: 20),
                      // ဤနေရာတွင် ခုနကရေးထားသော ဖျက်မည့် Function ကို ချိတ်ဆက်လိုက်ပါသည်
                      onPressed: () => _deleteBuyer(buyer),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Text('$budget သိန်း • ${buyer['preferred_location']}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                if (phones.isNotEmpty) 
                  InkWell(
                    onTap: () {},
                    child: Text(phones.join(', '), style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                  ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      minimumSize: const Size(60, 30),
                      side: BorderSide(color: Theme.of(context).colorScheme.primary),
                    ),
                    child: Text('Edit', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
                  ),
                )
              ],
            ),
          )
        );
      }
    );
  }
}
