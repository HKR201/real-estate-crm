import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // <--- Cloud ချိတ်ဆက်ရန်
import '../db/database_helper.dart';

class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});
  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
  List<Map<String, dynamic>> _deletedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeletedItems();
  }

  Future<void> _loadDeletedItems() async {
    setState(() => _isLoading = true);
    final db = await DatabaseHelper.instance.database;
    
    final props = await db.query('crm_properties', where: 'is_deleted = ?', whereArgs: [1]);
    final buyers = await db.query('crm_buyers', where: 'is_deleted = ?', whereArgs: [1]);
    final owners = await db.query('crm_owners', where: 'is_deleted = ?', whereArgs: [1]);
    
    List<Map<String, dynamic>> all = [];
    all.addAll(props.map((e) => {...e, 'table_type': 'crm_properties'}));
    all.addAll(buyers.map((e) => {...e, 'table_type': 'crm_buyers'}));
    all.addAll(owners.map((e) => {...e, 'table_type': 'crm_owners'}));
    
    setState(() {
      _deletedItems = all;
      _isLoading = false;
    });
  }

  Future<void> _restoreItem(Map<String, dynamic> item) async {
    await DatabaseHelper.instance.restoreFromRecycleBin(item['table_type'], item['id']);
    _loadDeletedItems();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ပြန်လည် ရယူပြီးပါပြီ')));
  }

  Future<void> _permanentDelete(Map<String, dynamic> item) async {
    // ၁။ ဖုန်းထဲမှ အပြီးတိုင် ဖျက်မည်
    final db = await DatabaseHelper.instance.database;
    await db.delete(item['table_type'], where: 'id = ?', whereArgs: [item['id']]);
    
    // ၂။ Cloud (Supabase) ထဲမှပါ အပြီးတိုင် လှမ်းဖျက်မည်
    try {
      await Supabase.instance.client.from(item['table_type']).delete().eq('id', item['id']);
    } catch (e) {
      debugPrint("Cloud Delete Error: $e");
    }

    _loadDeletedItems();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('အပြီးတိုင် ဖျက်လိုက်ပါပြီ')));
  }

  void _confirmPermanentDelete(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('အပြီးတိုင် ဖျက်ရန် သေချာပါသလား?'),
        content: const Text('ဤလုပ်ဆောင်ချက်သည် ဖုန်းထဲမှရော Cloud ပေါ်မှပါ အပြီးတိုင် ဖျက်ပစ်မည်ဖြစ်ပြီး ပြန်ယူ၍ မရနိုင်ပါ။'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('မဖျက်ပါ')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              _permanentDelete(item);
            },
            child: const Text('ဖျက်မည်'),
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recycle Bin')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _deletedItems.isEmpty 
          ? const Center(child: Text('အမှိုက်ပုံးထဲတွင် ဘာမှမရှိပါ'))
          : ListView.builder(
              itemCount: _deletedItems.length,
              itemBuilder: (context, index) {
                final item = _deletedItems[index];
                final title = item['title'] ?? item['name'] ?? 'အမည်မသိ';
                
                String typeLabel = '';
                if (item['table_type'] == 'crm_properties') typeLabel = 'အိမ်ခြံမြေ';
                else if (item['table_type'] == 'crm_buyers') typeLabel = 'ဝယ်လက်';
                else if (item['table_type'] == 'crm_owners') typeLabel = 'ပိုင်ရှင်';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.grey),
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(typeLabel),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.restore, color: Colors.green), 
                          tooltip: 'ပြန်ယူမည်',
                          onPressed: () => _restoreItem(item)
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_forever, color: Colors.red), 
                          tooltip: 'အပြီးဖျက်မည်',
                          onPressed: () => _confirmPermanentDelete(item)
                        ),
                      ],
                    ),
                  ),
                );
              }
            )
    );
  }
}
