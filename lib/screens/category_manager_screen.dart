import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class CategoryManagerScreen extends StatefulWidget {
  const CategoryManagerScreen({super.key});

  @override
  State<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends State<CategoryManagerScreen> {
  final Map<String, String> _categoryTypes = {
    'location': 'မြို့နယ်/တည်နေရာ',
    'road_type': 'လမ်းအမျိုးအစား',
    'land_type': 'မြေအမျိုးအစား',
    'house_type': 'အိမ်အမျိုးအစား',
  };

  String _selectedCategory = 'location';
  List<String> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getMetadata(_selectedCategory);
    if (mounted) {
      setState(() {
        _items = data;
        _isLoading = false;
      });
    }
  }

  void _confirmDelete(String value) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('အမျိုးအစား ဖျက်ရန်'),
        content: Text('"$value" ကို စာရင်းမှ ဖျက်ပစ်ရန် သေချာပါသလား?\n\n(မှတ်ချက်: ဤစာသားကို အသုံးပြုထားသော အိမ်ခြံမြေများ ရှိနေပါက စာရင်းတွင် ဆက်လက် ပေါ်နေနိုင်ပါသည်။)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ပယ်ဖျက်')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseHelper.instance.deleteMetadata(_selectedCategory, value);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ဖျက်ပြီးပါပြီ')));
              _loadMetadata();
            },
            child: const Text('ဖျက်မည်'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('အမျိုးအစားများ စီမံရန်', style: TextStyle(fontSize: 18)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.cardColor,
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'စီမံမည့် အမျိုးအစား ရွေးချယ်ပါ',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _categoryTypes.entries.map((e) => DropdownMenuItem(
                value: e.key,
                child: Text(e.value, style: const TextStyle(fontWeight: FontWeight.bold)),
              )).toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _selectedCategory = v);
                  _loadMetadata();
                }
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(child: Text('အမျိုးအစား အဟောင်းများ မရှိသေးပါ'))
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                            ),
                            child: ListTile(
                              title: Text(item, style: const TextStyle(fontSize: 16)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _confirmDelete(item),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
