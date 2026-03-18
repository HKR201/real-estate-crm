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
import 'utils/time_helper.dart'; 

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

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final Map<String, String> _filterCategories = {
    'asking_price_lakhs': 'ခေါ်ဈေးနှုန်း',
    'location_id': 'မြို့နယ်/တည်နေရာ',
    'road_type': 'လမ်းအမျိုးအစား',
    'house_type': 'အိမ်အမျိုးအစား', // <--- ပြန်ထည့်ပေးထားပါသည်
    'land_type': 'မြေအမျိုးအစား',
    'status': 'Status'
  };
  String? _selectedFilterCategory;
  String? _selectedFilterValue;
  List<String> _currentSubFilterValues = [];
  final TextEditingController _priceFilterController = TextEditingController();

  @override
  void initState() { super.initState(); _loadProperties(); _loadBuyers(); }

  @override
  void dispose() { _pageController.dispose(); _searchController.dispose(); _priceFilterController.dispose(); super.dispose(); }

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
    Future.delayed(const Duration(seconds: 3), () => scaffoldMessenger.hideCurrentSnackBar());
  }

  void _deleteProperty(Map<String, dynamic> property) async {
    setState(() => _properties.removeWhere((p) => p['id'] == property['id']));
    await DatabaseHelper.instance.moveToRecycleBin('crm_properties', property['id']);
    if (!mounted) return;
    _showAutoCloseSnackBar('အိမ်ခြံမြေစာရင်းကို ဖျက်လိုက်ပါပြီ', () async { await DatabaseHelper.instance.restoreFromRecycleBin('crm_properties', property['id']); _loadProperties(); });
  }

  void _deleteBuyer(Map<String, dynamic> buyer) async {
    setState(() => _buyers.removeWhere((b) => b['id'] == buyer['id']));
    await DatabaseHelper.instance.moveToRecycleBin('crm_buyers', buyer['id']);
    if (!mounted) return;
    _showAutoCloseSnackBar('ဝယ်လက်စာရင်းကို ဖျက်လိုက်ပါပြီ', () async { await DatabaseHelper.instance.restoreFromRecycleBin('crm_buyers', buyer['id']); _loadBuyers(); });
  }

  void _onFilterCategoryChanged(String? categoryKey) async {
    setState(() { _selectedFilterCategory = categoryKey; _selectedFilterValue = null; _currentSubFilterValues = []; _priceFilterController.clear(); });
    if (categoryKey == 'status') { _currentSubFilterValues = ['Available', 'Pending', 'Sold Out']; } 
    else if (categoryKey == 'location_id') { _currentSubFilterValues = await DatabaseHelper.instance.getMetadata('location'); } 
    else if (categoryKey == 'road_type') { _currentSubFilterValues = await DatabaseHelper.instance.getMetadata('road_type'); }
    else if (categoryKey == 'house_type') { _currentSubFilterValues = await DatabaseHelper.instance.getMetadata('house_type'); }
    else if (categoryKey == 'land_type') { _currentSubFilterValues = await DatabaseHelper.instance.getMetadata('land_type'); }
    setState(() {}); 
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
          title: _isSearching && _currentIndex == 1 
              ? TextField(controller: _searchController, autofocus: true, decoration: const InputDecoration(hintText: 'အမည်, နေရာ, ဈေးနှုန်း ရှာရန်...', border: InputBorder.none), onChanged: (val) => setState(() => _searchQuery = val))
              : const Text('CRM Dashboard', style: TextStyle(fontWeight: FontWeight.bold)), 
          actions: [ if (_currentIndex == 1) IconButton(icon: Icon(_isSearching ? Icons.close : Icons.search), onPressed: () { setState(() { _isSearching = !_isSearching; if (!_isSearching) { _searchQuery = ''; _searchController.clear(); } }); }) ]
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
        body: PageView(controller: _pageController, onPageChanged: (index) { setState(() { _currentIndex = index; if (index == 0) { _isSearching = false; _searchQuery = ''; _searchController.clear(); } }); }, children: [ _buildHomeTab(), _buildBuyerTab() ]),
        floatingActionButton: FloatingActionButton(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Theme.of(context).colorScheme.onPrimary, onPressed: () async { if (_currentIndex == 0) { final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const PropertyFormScreen())); if (result == true) _loadProperties(); } else if (_currentIndex == 1) { final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const BuyerFormScreen())); if (result == true) _loadBuyers(); } }, child: const Icon(Icons.add)),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex == 2 ? 0 : _currentIndex, 
          onDestinationSelected: (index) { if (index == 2) { _scaffoldKey.currentState?.openEndDrawer(); } else { _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut); } },
          destinations: const [NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'), NavigationDestination(icon: Icon(Icons.person_search_outlined), selectedIcon: Icon(Icons.person_search), label: 'Buyer'), NavigationDestination(icon: Icon(Icons.menu), label: 'Option')],
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
        Expanded(flex: 5, child: DropdownButtonHideUnderline(child: DropdownButton<String>(isExpanded: true, hint: const Text('Filter By', style: TextStyle(fontWeight: FontWeight.bold)), value: _selectedFilterCategory, icon: const Icon(Icons.filter_list, size: 20), items: _filterCategories.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis))).toList(), onChanged: _onFilterCategoryChanged))),
        const SizedBox(width: 8), Container(width: 1, height: 24, color: Colors.grey.shade300), const SizedBox(width: 8),
        Expanded(flex: 5, child: _selectedFilterCategory == 'asking_price_lakhs' ? TextField(controller: _priceFilterController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'အများဆုံး (သိန်း)', border: InputBorder.none, isDense: true), onChanged: (_) => setState(() {})) : DropdownButtonHideUnderline(child: DropdownButton<String>(isExpanded: true, hint: const Text('ရွေးချယ်ရန်'), value: _selectedFilterValue, items: _currentSubFilterValues.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis))).toList(), onChanged: _selectedFilterCategory == null ? null : (val) => setState(() => _selectedFilterValue = val)))),
        if (_selectedFilterCategory != null) IconButton(icon: const Icon(Icons.cancel, color: Colors.grey, size: 20), onPressed: () => setState(() { _selectedFilterCategory = null; _selectedFilterValue = null; _currentSubFilterValues = []; _priceFilterController.clear(); }))
      ])),
      Expanded(child: filteredProperties.isEmpty ? const Center(child: Text('စာရင်းမရှိပါ')) : ListView.builder(padding: const EdgeInsets.only(top: 8, bottom: 80), itemCount: filteredProperties.length, itemBuilder: (context, index) => PropertyMiniCard(property: filteredProperties[index], isSynced: false, onDelete: () => _deleteProperty(filteredProperties[index]), onEditCompleted: () => _loadProperties())))
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
    return ListView.builder(padding: const EdgeInsets.only(top: 8, bottom: 80), itemCount: filteredBuyers.length, itemBuilder: (context, index) {
      final buyer = filteredBuyers[index];
      List<dynamic> phones = []; try { phones = jsonDecode(buyer['phones'] ?? '[]'); } catch (_) {}
      final budget = (buyer['budget_lakhs'] ?? 0).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
      return Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(buyer['name'] ?? 'အမည်မသိ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), Text(TimeHelper.getRelativeTime(buyer['updated_at']), style: const TextStyle(fontSize: 11, color: Colors.grey)), IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => _deleteBuyer(buyer))]),
        Text('$budget သိန်း • ${buyer['preferred_location']}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
        if (phones.isNotEmpty) InkWell(onTap: () => launchUrl(Uri.parse('tel:${phones.first}')), child: Text(phones.join(', '), style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline))),
        Align(alignment: Alignment.centerRight, child: OutlinedButton(onPressed: () async { final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => BuyerFormScreen(editData: buyer))); if (result == true) _loadBuyers(); }, child: const Text('Edit')))
      ])));
    });
  }
}
