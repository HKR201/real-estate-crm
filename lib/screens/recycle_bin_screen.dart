import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<Map<String, dynamic>> _deletedProperties = [];
  List<Map<String, dynamic>> _deletedOwners = [];
  List<Map<String, dynamic>> _deletedBuyers = [];
  
  bool _isLoading = true;
  bool _hasRestoredAnything = false; // တစ်ခုခုကို Restore လုပ်ခဲ့လျှင် Home ကို Refresh လုပ်ရန် အချက်ပြမည်

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDeletedItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDeletedItems() async {
    setState(() => _isLoading = true);
    final props = await DatabaseHelper.instance.getDeletedProperties();
    final owners = await DatabaseHelper.instance.getDeletedOwners();
    final buyers = await DatabaseHelper.instance.getDeletedBuyers();
    setState(() {
      _deletedProperties = List.from(props);
      _deletedOwners = List.from(owners);
      _deletedBuyers = List.from(buyers);
      _isLoading = false;
    });
  }

  // --- မူလနေရာသို့ ပြန်လည်ပို့ဆောင်မည် (Restore) ---
  void _restoreItem(String tableName, String id) async {
    await DatabaseHelper.instance.restoreFromRecycleBin(tableName, id);
    _hasRestoredAnything = true; 
    _loadDeletedItems(); // စာရင်းကို ပြန်လည်လန်းဆန်းစေမည်
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('မူလနေရာသို့ ပြန်လည်ပို့ဆောင်ပြီးပါပြီ'), backgroundColor: Colors.green));
  }

  // --- အပြီးတိုင် ဖျက်ပစ်မည် (Delete Forever) ---
  void _permanentlyDeleteItem(String tableName, String id) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('အပြီးဖျက်မည်'),
        content: const Text('ဤလုပ်ဆောင်ချက်သည် ပြန်လည်ရယူ၍ မရနိုင်ပါ။ သေချာပါသလား?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('မလုပ်ပါ')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseHelper.instance.permanentlyDelete(tableName, id);
              _loadDeletedItems();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('အပြီးတိုင် ဖျက်လိုက်ပါပြီ'), backgroundColor: Colors.red));
            },
            child: const Text('ဖျက်မည်', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Back ထွက်လျှင် Restore လုပ်ခဲ့တာရှိမရှိ သိအောင် PopScope သုံးထားသည်
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.pop(context, _hasRestoredAnything);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('အမှိုက်ပုံး (Recycle Bin)', style: TextStyle(fontWeight: FontWeight.bold)),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context, _hasRestoredAnything)),
          bottom: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(text: 'အိမ်ခြံမြေ'),
              Tab(text: 'ပိုင်ရှင်'),
              Tab(text: 'ဝယ်လက်'),
            ],
          ),
        ),
        body: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildList(_deletedProperties, 'crm_properties', Icons.home),
                  _buildList(_deletedOwners, 'crm_owners', Icons.person),
                  _buildList(_deletedBuyers, 'crm_buyers', Icons.person_search),
                ],
              ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, String tableName, IconData icon) {
    if (items.isEmpty) {
      return const Center(child: Text('အမှိုက်ပုံးထဲတွင် ဘာမှမရှိပါ', style: TextStyle(color: Colors.grey, fontSize: 16)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final title = item['title'] ?? item['name'] ?? 'အမည်မသိ'; // Property ဆိုလျှင် title, Owner/Buyer ဆိုလျှင် name
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: Colors.grey.shade200, child: Icon(icon, color: Colors.grey)),
            title: Text(title, style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)), // ဖျက်ထားကြောင်းသိသာစေရန် မျဉ်းခြစ်ထားသည်
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ပြန်လည်ရယူမည့် ခလုတ် (Restore)
                IconButton(
                  icon: const Icon(Icons.restore, color: Colors.green),
                  tooltip: 'မူလနေရာသို့ ပြန်ပို့မည်',
                  onPressed: () => _restoreItem(tableName, item['id']),
                ),
                // အပြီးတိုင် ဖျက်မည့် ခလုတ် (Delete Forever)
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  tooltip: 'အပြီးတိုင် ဖျက်မည်',
                  onPressed: () => _permanentlyDeleteItem(tableName, item['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
