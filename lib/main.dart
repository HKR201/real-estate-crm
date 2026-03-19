import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'dart:convert'; 
import 'dart:io'; // Internet check အတွက်
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:shared_preferences/shared_preferences.dart';

import 'widgets/property_mini_card.dart';
import 'screens/property_form_screen.dart';
import 'screens/owner_list_screen.dart';
import 'screens/buyer_form_screen.dart'; 
import 'screens/recycle_bin_screen.dart'; 
import 'screens/settings_screen.dart'; 
import 'db/database_helper.dart';
import 'utils/time_helper.dart'; 
import 'services/sync_service.dart'; 

const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  
  final prefs = await SharedPreferences.getInstance();
  final themeStr = prefs.getString('themeMode') ?? 'system';
  if (themeStr == 'light') themeNotifier.value = ThemeMode.light;
  else if (themeStr == 'dark') themeNotifier.value = ThemeMode.dark;
  else themeNotifier.value = ThemeMode.system;

  // 2. Android 15 Modernization (Edge-to-Edge and transparent bars)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const RealEstateCrmApp());
}

class RealEstateCrmApp extends StatelessWidget {
  const RealEstateCrmApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'Real Estate CRM',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode, 
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          home: const MainDashboard(),
        );
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(seedColor: isDark ? const Color(0xFF4DB6AC) : const Color(0xFF008080), brightness: brightness),
      scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F8F8),
      cardTheme: CardThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 2),
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
  final PageController _pageController = PageController(); 
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _priceFilterController = TextEditingController();

  List<Map<String, dynamic>> _properties = [];
  List<Map<String, dynamic>> _buyers = [];
  bool _isLoading = true; 
  bool _isLoadingBuyers = true;
  bool _isSearching = false;
  String _searchQuery = '';

  final Map<String, String> _filterCategories = {
    'asking_price_lakhs': 'ခေါ်ဈေးနှုန်း',
    'location_id': 'မြို့နယ်/တည်နေရာ',
    'road_type': 'လမ်းအမျိုးအစား',
    'house_type': 'အိမ်အမျိုးအစား',
    'land_type': 'မြေအမျိုးအစား',
    'status': 'Status'
  };
  String? _selectedFilterCategory;
  String? _selectedFilterValue;
  List<String> _currentSubFilterValues = [];

  @override
  void initState() { 
    super.initState(); 
    _loadProperties(); 
    _loadBuyers(); 
    _triggerAutoSync(); 
  }

  // 1. Memory Management (Critical)
  @override
  void dispose() {
    _searchController.dispose();
    _priceFilterController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // 3. Sync Logic Efficiency (Internet Check + 5-minute Cooldown)
  Future<void> _triggerAutoSync() async {
    try {
      final result = await InternetAddress.lookup('supabase.co');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final lastSyncStr = prefs.getString('last_auto_sync');
        DateTime? lastSync = lastSyncStr != null ? DateTime.tryParse(lastSyncStr) : null;
        
        // ၅ မိနစ်ကျော်မှသာ Sync ထပ်လုပ်မည်
        if (lastSync == null || DateTime.now().difference(lastSync).inMinutes >= 5) {
          await SyncService.autoSyncBackground();
          await prefs.setString('last_auto_sync', DateTime.now().toIso8601String());
          if (mounted) { _loadProperties(); _loadBuyers(); }
        }
      }
    } catch (e) {
      debugPrint("No Internet or Sync Failed: ${e.toString()}");
    }
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllProperties();
    if (mounted) setState(() { _properties = List<Map<String, dynamic>>.from(data); _isLoading = false; });
  }

  Future<void> _loadBuyers() async {
    setState(() => _isLoadingBuyers = true);
    final data = await DatabaseHelper.instance.getAllBuyers();
    if (mounted) setState(() { _buyers = List<Map<String, dynamic>>.from(data); _isLoadingBuyers = false; });
  }

  void _showAutoCloseSnackBar(String message, VoidCallback? onUndo) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.clearSnackBars();
    scaffoldMessenger.showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
      content: Text(message),
      duration: const Duration(seconds: 3),
      action: onUndo != null ? SnackBarAction(label: 'Undo', textColor: Colors.yellow, onPressed: onUndo) : null,
    ));
    Future.delayed(const Duration(seconds: 3), () { if (mounted) scaffoldMessenger.hideCurrentSnackBar(); });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: PopScope(
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
            title: _isSearching && _currentIndex == 1 
                ? TextField(controller: _searchController, autofocus: true, decoration: const InputDecoration(hintText: 'ရှာဖွေရန်...', border: InputBorder.none), onChanged: (val) => setState(() => _searchQuery = val))
                : const Text('CRM Dashboard', style: TextStyle(fontWeight: FontWeight.bold)), 
            actions: [ if (_currentIndex == 1) IconButton(icon: Icon(_isSearching ? Icons.close : Icons.search), onPressed: () { setState(() { _isSearching = !_isSearching; if (!_isSearching) { _searchQuery = ''; _searchController.clear(); } }); }) ]
          ),
          endDrawer: Drawer(
            child: SafeArea(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const DrawerHeader(
                    decoration: BoxDecoration(color: Color(0xFF008080)), 
                    child: Text('CRM Options', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))
                  ),
                  ListTile(leading: const Icon(Icons.people), title: const Text('Owner List'), onTap: () async { Navigator.pop(context); await Navigator.push(context, MaterialPageRoute(builder: (context) => const OwnerListScreen())); _triggerAutoSync(); }),
                  ListTile(leading: const Icon(Icons.delete_outline, color: Colors.red), title: const Text('Recycle Bin'), onTap: () async { Navigator.pop(context); await Navigator.push(context, MaterialPageRoute(builder: (context) => const RecycleBinScreen())); _loadProperties(); _loadBuyers(); }),
                  const Divider(),
                  ListTile(leading: const Icon(Icons.settings), title: const Text('Settings'), onTap: () async { Navigator.pop(context); await Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())); _loadProperties(); _loadBuyers(); }),
                ],
              ),
            ),
          ),
          body: PageView(
            controller: _pageController, 
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) { setState(() { _currentIndex = index; if (index == 0) { _isSearching = false; _searchQuery = ''; _searchController.clear(); } }); }, 
            children: [ _buildHomeTab(), _buildBuyerTab() ]
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Theme.of(context).colorScheme.onPrimary, 
            onPressed: () async { 
              if (_currentIndex == 0) { 
                final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const PropertyFormScreen())); 
                if (result == true) { _loadProperties(); _triggerAutoSync(); } 
              } else if (_currentIndex == 1) { 
                final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const BuyerFormScreen())); 
                if (result == true) { _loadBuyers(); _triggerAutoSync(); } 
              } 
            }, 
            child: const Icon(Icons.add)
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex == 2 ? 0 : _currentIndex, 
            onDestinationSelected: (index) { if (index == 2) { _scaffoldKey.currentState?.openEndDrawer(); } else { _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut); } },
            destinations: const [NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'), NavigationDestination(icon: Icon(Icons.person_search_outlined), selectedIcon: Icon(Icons.person_search), label: 'Buyer'), NavigationDestination(icon: Icon(Icons.menu), label: 'Option')],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    List<Map<String, dynamic>> filteredProperties = _properties;
    if (_selectedFilterCategory != null) {
      filteredProperties = _properties.where((p) {
        if (_selectedFilterCategory == 'asking_price_lakhs') {
          int maxPrice = int.tryParse(_priceFilterController.text) ?? 0;
          if (maxPrice == 0) return true;
          return (p['asking_price_lakhs'] ?? 0) <= maxPrice;
        }
        if (_selectedFilterValue != null) return p[_selectedFilterCategory] == _selectedFilterValue;
        return true;
      }).toList();
    }
    return Column(children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), color: Theme.of(context).cardColor, child: Row(children: [
        Expanded(flex: 5, child: DropdownButtonHideUnderline(child: DropdownButton<String>(
          isExpanded: true, 
          hint: const Text('Filter By', style: TextStyle(fontWeight: FontWeight.bold)), 
          value: _selectedFilterCategory, 
          icon: const Icon(Icons.filter_list, size: 20), 
          items: _filterCategories.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis))).toList(), 
          onChanged: (v) async {
            setState(() { _selectedFilterCategory = v; _selectedFilterValue = null; _currentSubFilterValues = []; _priceFilterController.clear(); });
            if (v == 'status') { _currentSubFilterValues = ['Available', 'Pending', 'Sold Out']; } 
            else if (v != null && v != 'asking_price_lakhs') { _currentSubFilterValues = await DatabaseHelper.instance.getDistinctPropertyValues(v); }
            setState(() {});
          }
        ))),
        const SizedBox(width: 8), Container(width: 1, height: 24, color: Colors.grey.shade300), const SizedBox(width: 8),
        Expanded(flex: 5, child: _selectedFilterCategory == 'asking_price_lakhs' ? TextField(controller: _priceFilterController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'အများဆုံး (သိန်း)', border: InputBorder.none, isDense: true), onChanged: (_) => setState(() {})) : DropdownButtonHideUnderline(child: DropdownButton<String>(isExpanded: true, hint: const Text('ရွေးချယ်ရန်'), value: _selectedFilterValue, items: _currentSubFilterValues.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis))).toList(), onChanged: (val) => setState(() => _selectedFilterValue = val)))),
        if (_selectedFilterCategory != null) IconButton(icon: const Icon(Icons.cancel, color: Colors.grey, size: 20), onPressed: () => setState(() { _selectedFilterCategory = null; _selectedFilterValue = null; _currentSubFilterValues = []; _priceFilterController.clear(); }))
      ])),
      Expanded(child: filteredProperties.isEmpty ? const Center(child: Text('စာရင်းမရှိပါ')) : ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80), 
        physics: const BouncingScrollPhysics(),
        itemCount: filteredProperties.length, 
        itemBuilder: (context, index) => PropertyMiniCard(
          property: filteredProperties[index], 
          isSynced: filteredProperties[index]['is_synced'] == 1, 
          onDelete: () async {
            final id = filteredProperties[index]['id'];
            setState(() => _properties.removeWhere((p) => p['id'] == id));
            await DatabaseHelper.instance.moveToRecycleBin('crm_properties', id);
            _showAutoCloseSnackBar('ဖျက်ပြီးပါပြီ', () async { await DatabaseHelper.instance.restoreFromRecycleBin('crm_properties', id); _loadProperties(); });
          }, 
          onEditCompleted: () { _loadProperties(); _triggerAutoSync(); } 
        )
      ))
    ]);
  }

  Widget _buildBuyerTab() {
    if (_isLoadingBuyers) return const Center(child: CircularProgressIndicator());
    final parsedBudget = int.tryParse(_searchQuery);
    final filteredBuyers = _searchQuery.isEmpty ? _buyers : _buyers.where((b) {
      final matchText = (b['name'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase()) || (b['preferred_location'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase());
      if (parsedBudget != null) return matchText || ((b['budget_lakhs'] ?? 0) <= parsedBudget);
      return matchText;
    }).toList();
    if (filteredBuyers.isEmpty) return const Center(child: Text('ဝယ်လက်မတွေ့ပါ'));
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80), 
      physics: const BouncingScrollPhysics(),
      itemCount: filteredBuyers.length, 
      itemBuilder: (context, index) {
        final buyer = filteredBuyers[index];
        List<dynamic> phones = []; try { phones = jsonDecode(buyer['phones'] ?? '[]'); } catch (_) {}
        return Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(buyer['name'] ?? 'အမည်မသိ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), Text(TimeHelper.getRelativeTime(buyer['updated_at']), style: const TextStyle(fontSize: 11, color: Colors.grey)), IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () {
            setState(() => _buyers.removeWhere((b) => b['id'] == buyer['id']));
            DatabaseHelper.instance.moveToRecycleBin('crm_buyers', buyer['id']);
            _showAutoCloseSnackBar('ဖျက်ပြီးပါပြီ', () async { await DatabaseHelper.instance.restoreFromRecycleBin('crm_buyers', buyer['id']); _loadBuyers(); });
          })]),
          Text('${buyer['budget_lakhs']} သိန်း • ${buyer['preferred_location']}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
          if (phones.isNotEmpty) InkWell(onTap: () => launchUrl(Uri.parse('tel:${phones.first}')), child: Text(phones.join(', '), style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline))),
          Align(alignment: Alignment.centerRight, child: OutlinedButton(onPressed: () async { final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => BuyerFormScreen(editData: buyer))); if (result == true) { _loadBuyers(); _triggerAutoSync(); } }, child: const Text('Edit')))
        ])));
      }
    );
  }
}
