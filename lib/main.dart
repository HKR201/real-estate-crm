import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; 

import 'widgets/property_mini_card.dart';
import 'screens/property_form_screen.dart';
import 'screens/owner_list_screen.dart';
import 'screens/buyer_form_screen.dart'; 
import 'screens/recycle_bin_screen.dart'; 
import 'db/database_helper.dart';

const String supabaseUrl = 'YOUR_SUPABASE_URL';
const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(systemNavigationBarColor: Colors.transparent, statusBarColor: Colors.transparent));
  runApp(const RealEstateCrmApp());
}

class RealEstateCrmApp extends StatelessWidget {
  const RealEstateCrmApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Real Estate CRM', debugShowCheckedModeBanner: false, themeMode: ThemeMode.system, theme: _buildTheme(Brightness.light), darkTheme: _buildTheme(Brightness.dark), home: const MainDashboard());
  }
  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(useMaterial3: true, brightness: brightness, colorScheme: ColorScheme.fromSeed(seedColor: isDark ? const Color(0xFF4DB6AC) : const Color(0xFF008080), brightness: brightness, surface: isDark ? const Color(0xFF1E2626) : const Color(0xFFFFFFFF)), scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F8F8), cardTheme: CardThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 2), inputDecorationTheme: InputDecorationTheme(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))));
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
  final PageController _pageController = PageController(); 

  List<Map<String, dynamic>> _properties = [];
  List<Map<String, dynamic>> _buyers = [];
  bool _isLoading = true; 
  bool _isLoadingBuyers = true;

  // --- Buyer စာမျက်နှာအတွက် Search Variables ---
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // --- Home စာမျက်နှာအတွက် Categories & Sub-filter Variables ---
  // နောက်ပိုင်း Category အသစ်တိုးချင်လျှင် ဤ Map ထဲတွင် အလွယ်တကူ ထပ်တိုးနိုင်ပါသည်
  final Map<String, String> _filterCategories = {
    'status': 'Status (အခြေအနေ)',
    'location_id': 'မြို့နယ်/တည်နေရာ',
    'property_base_type': 'အမျိုးအစား (မြေ/အိမ်)',
    'land_type': 'မြေအမျိုးအစား'
  };
  String? _selectedFilterCategory;
  String? _selectedFilterValue;
  List<String> _currentSubFilterValues = [];

  @override
  void initState() { super.initState(); _loadProperties(); _loadBuyers(); }

  @override
  void dispose() { 
    _pageController.dispose(); 
    _searchController.dispose();
    super.dispose(); 
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllProperties();
    setState(() { _properties = List<Map<String, dynamic>>.from(data); _isLoading = false; });
  }

  Future<void> _loadBuyers() async {
    setState(() => _isLoadingBuyers = true);
    final data = await DatabaseHelper.instance.getAllBuyers();
    setState(() { _buyers = List<Map<String, dynamic>>.from(data); _isLoadingBuyers = false; });
  }

  void _deleteProperty(Map<String, dynamic> property) async {
    setState(() => _properties.removeWhere((p) => p['id'] == property['id']));
    await DatabaseHelper.instance.moveToRecycleBin('crm_properties', property['id']);
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars(); 
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16), content: const Text('အိမ်ခြံမြေစာရင်းကို ဖျက်လိုက်ပါပြီ'), duration: const Duration(seconds: 4), action: SnackBarAction(label: 'Undo (ပြန်ယူမည်)', textColor: Colors.yellow, onPressed: () async { await DatabaseHelper.instance.restoreFromRecycleBin('crm_properties', property['id']); _loadProperties(); })));
  }

  void _deleteBuyer(Map<String, dynamic> buyer) async {
    setState(() => _buyers.removeWhere((b) => b['id'] == buyer['id']));
    await DatabaseHelper.instance.moveToRecycleBin('crm_buyers', buyer['id']);
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16), content: const Text('ဝယ်လက်စာရင်းကို ဖျက်လိုက်ပါပြီ'), duration: const Duration(seconds: 4), action: SnackBarAction(label: 'Undo (ပြန်ယူမည်)', textColor: Colors.yellow, onPressed: () async { await DatabaseHelper.instance.restoreFromRecycleBin('crm_buyers', buyer['id']); _loadBuyers(); })));
  }

  // Category ရွေးလိုက်သောအခါ Sub-filter များကို ဆွဲထုတ်မည့်စနစ်
  void _onFilterCategoryChanged(String? categoryKey) async {
    setState(() {
      _selectedFilterCategory = categoryKey;
      _selectedFilterValue = null; // Category ပြောင်းလျှင် Value ကို Reset ချမည်
      _currentSubFilterValues = [];
    });

    if (categoryKey == 'status') {
      _currentSubFilterValues = ['Available', 'Pending', 'Sold Out'];
    } else if (categoryKey == 'property_base_type') {
      _currentSubFilterValues = ['မြေကွက်သီးသန့်', 'အိမ်ပါသည်'];
    } else if (categoryKey == 'location_id') {
      _currentSubFilterValues = await DatabaseHelper.instance.getMetadata('location');
    } else if (categoryKey == 'land_type') {
      _currentSubFilterValues = await DatabaseHelper.instance.getMetadata('land_type');
    }
    setState(() {}); // UI ကို Update လုပ်မည်
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, 
      onPopInvoked: (didPop) { 
        if (didPop) return; 
        if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) { Navigator.of(context).pop(); } 
        else if (_isSearching) { setState(() { _isSearching = false; _searchQuery = ''; _searchController.clear(); }); } 
        else if (_currentIndex != 0) { _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut); } 
        else { SystemNavigator.pop(); } 
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          automaticallyImplyLeading: false, 
          title: _isSearching && _currentIndex == 1 // Buyer စာမျက်နှာတွင်သာ Search Bar ပြမည်
              ? TextField(
                  controller: _searchController, autofocus: true,
                  decoration: const InputDecoration(hintText: 'ဝယ်လက်ရှာဖွေရန်...', border: InputBorder.none),
                  onChanged: (val) => setState(() => _searchQuery = val),
                )
              : const Text('CRM Dashboard', style: TextStyle(fontWeight: FontWeight.bold)), 
          actions: [
            // Buyer စာမျက်နှာ (index == 1) ဖြစ်မှသာ မှန်ဘီလူး Search Icon ကို ပြမည်
            if (_currentIndex == 1)
              IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.search), 
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) { _searchQuery = ''; _searchController.clear(); }
                  });
                }
              )
          ]
        ),
        endDrawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(decoration: BoxDecoration(color: Color(0xFF008080)), child: Text('Options', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
              ListTile(leading: const Icon(Icons.people), title: const Text('Owner List'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const OwnerListScreen())); }),
              ListTile(leading: const Icon(Icons.cloud_sync), title: const Text('Cloud Sync (Manual)'), onTap: () {}),
              ListTile(leading: const Icon(Icons.delete_outline, color: Colors.red), title: const Text('Recycle Bin'), onTap: () async { Navigator.pop(context); final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const RecycleBinScreen())); if (result == true) { _loadProperties(); _loadBuyers(); } }),
              ListTile(leading: const Icon(Icons.settings), title: const Text('Settings'), onTap: () {}),
            ],
          ),
        ),
        
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) { 
            setState(() { 
              _currentIndex = index; 
              // Home သို့ရောက်လျှင် Buyer ၏ Search ကို ပိတ်မည်
              if (index == 0) { _isSearching = false; _searchQuery = ''; _searchController.clear(); }
            }); 
          },
          children: [ _buildHomeTab(), _buildBuyerTab() ],
        ),

        floatingActionButton: FloatingActionButton(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Theme.of(context).colorScheme.onPrimary, onPressed: () async { if (_currentIndex == 0) { final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const PropertyFormScreen())); if (result == true) _loadProperties(); } else if (_currentIndex == 1) { final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const BuyerFormScreen())); if (result == true) _loadBuyers(); } }, child: const Icon(Icons.add)),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex == 2 ? 0 : _currentIndex, 
          onDestinationSelected: (index) { 
            if (index == 2) { _scaffoldKey.currentState?.openEndDrawer(); } 
            else { _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut); } 
          },
          destinations: const [NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'), NavigationDestination(icon: Icon(Icons.person_search_outlined), selectedIcon: Icon(Icons.person_search), label: 'Buyer'), NavigationDestination(icon: Icon(Icons.menu), label: 'Option')],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    
    // --- ရွေးချယ်ထားသော Filter ဖြင့် စစ်ထုတ်ခြင်း ---
    List<Map<String, dynamic>> filteredProperties = _properties;
    if (_selectedFilterCategory != null && _selectedFilterValue != null) {
      filteredProperties = _properties.where((p) {
        if (_selectedFilterCategory == 'property_base_type') {
          final hType = p['house_type'];
          final isHouse = hType != null && hType.toString().isNotEmpty;
          final typeStr = isHouse ? 'အိမ်ပါသည်' : 'မြေကွက်သီးသန့်';
          return typeStr == _selectedFilterValue;
        }
        return p[_selectedFilterCategory] == _selectedFilterValue;
      }).toList();
    }

    return Column(
      children: [
        // --- Categories နှင့် Sub-filter UI ---
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).cardColor,
          child: Row(
            children: [
              // Category (Main Filter)
              Expanded(
                flex: 5,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('Filter By', style: TextStyle(fontWeight: FontWeight.bold)),
                    value: _selectedFilterCategory,
                    icon: const Icon(Icons.filter_list, size: 20),
                    items: _filterCategories.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: _onFilterCategoryChanged,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 24, color: Colors.grey.shade300), // ခွဲခြားသည့် မျဉ်းတိုလေး
              const SizedBox(width: 8),
              // Sub-Filter (Value)
              Expanded(
                flex: 5,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('ရွေးချယ်ရန်'),
                    value: _selectedFilterValue,
                    items: _currentSubFilterValues.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: _selectedFilterCategory == null ? null : (val) => setState(() => _selectedFilterValue = val),
                  ),
                ),
              ),
              // Filter ဖြုတ်ရန် (Clear) ခလုတ်
              if (_selectedFilterCategory != null)
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.grey, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() { _selectedFilterCategory = null; _selectedFilterValue = null; _currentSubFilterValues = []; }),
                )
            ],
          ),
        ),
        
        // --- အိမ်ခြံမြေစာရင်းများ ---
        Expanded(
          child: filteredProperties.isEmpty
              ? const Center(child: Text('ရှာဖွေမှုနှင့် ကိုက်ညီသော စာရင်းမရှိပါ', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80), 
                  itemCount: filteredProperties.length, 
                  itemBuilder: (context, index) { 
                    return PropertyMiniCard(property: filteredProperties[index], isSynced: false, onDelete: () => _deleteProperty(filteredProperties[index]), onEditCompleted: () => _loadProperties()); 
                  }
                ),
        ),
      ],
    );
  }

  Widget _buildBuyerTab() {
    if (_isLoadingBuyers) return const Center(child: CircularProgressIndicator());
    
    final filteredBuyers = _searchQuery.isEmpty 
        ? _buyers 
        : _buyers.where((b) => (b['name'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase()) || (b['preferred_location'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    if (filteredBuyers.isEmpty) {
      return Center(child: Text(_searchQuery.isEmpty ? 'ဝယ်လက်စာရင်း မရှိသေးပါ။\nအပေါင်း (+) ကိုနှိပ်၍ ထည့်ပါ။' : 'ရှာဖွေမှုရလဒ် မတွေ့ပါ', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80), itemCount: filteredBuyers.length,
      itemBuilder: (context, index) {
        final buyer = filteredBuyers[index];
        List<dynamic> phones = []; try { phones = jsonDecode(buyer['phones'] ?? '[]'); } catch (_) {}
        final budget = (buyer['budget_lakhs'] ?? 0).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');

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
                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => _deleteBuyer(buyer), constraints: const BoxConstraints(), padding: EdgeInsets.zero)
                  ],
                ),
                const SizedBox(height: 8),
                Text('$budget သိန်း • ${buyer['preferred_location']}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                if (phones.isNotEmpty) 
                  InkWell(
                    onTap: () => launchUrl(Uri.parse('tel:${phones.first}')), 
                    child: Text(phones.join(', '), style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                  ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: () async {
                      final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => BuyerFormScreen(editData: buyer)));
                      if (result == true) _loadBuyers();
                    },
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0), minimumSize: const Size(60, 30), side: BorderSide(color: Theme.of(context).colorScheme.primary)),
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
