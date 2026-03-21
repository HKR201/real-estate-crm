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
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    setState(() => _isLoading = true);
    
    // 1. Metadata မှ စာရင်း (အဘိဓာန်)
    final metaData = await DatabaseHelper.instance.getMetadata(_selectedCategory);
    
    // 2. လက်ရှိ အသုံးပြုနေသော စာရင်း
    String propColumn = _selectedCategory == 'location' ? 'location_id' : _selectedCategory;
    final usedData = await DatabaseHelper.instance.getDistinctPropertyValues(propColumn);

    // 3. နှစ်ခုပေါင်းပြီး List တည်ဆောက်မည် (ထပ်နေသည်များကို Set ဖြင့် ရှင်းထုတ်မည်)
    Set<String> allNames = {...metaData, ...usedData};
    
    List<Map<String, dynamic>> combinedList = [];
    for (String name in allNames) {
      combinedList.add({
        'name': name,
        'is_used': usedData.contains(name), // လက်ရှိ အိမ်ခြံမြေကတ်တွင် သုံးထားသလား စစ်ဆေးခြင်း
        'in_meta': metaData.contains(name),
      });
    }

    if (mounted) {
      setState(() {
        _items = combinedList;
        _isLoading = false;
      });
    }
  }

  void _confirmDelete(String value, bool isUsed) {
    if (isUsed) {
      // ⚠️ လက်ရှိသုံးနေလျှင် ဖျက်ခွင့်မပေးဘဲ ရှင်းပြမည်
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('ဖျက်၍မရပါ'),
          content: Text('"$value" ကို လက်ရှိ Dashboard ရှိ အိမ်ခြံမြေကတ်တစ်ခုတွင် အသုံးပြုထားပါသည်။\n\nDropdown မှ ပျောက်သွားစေလိုပါက၊ သက်ဆိုင်ရာ အိမ်ခြံမြေကတ်ကို အရင်ဖျက်ရန် (သို့) အခြားအမည်သို့ ပြောင်းပေးရန် လိုအပ်ပါသည်။'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('အိုကေ')),
          ],
        ),
      );
      return;
    }

    // အသုံးမပြုတော့လျှင် ဖျက်ခွင့်ပေးမည်
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('အမျိုးအစား ဖျက်ရန်'),
        content: Text('"$value" ကို စာရင်းမှ အပြီးတိုင် ဖျက်ပစ်ရန် သေချာပါသလား?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ပယ်ဖျက်')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseHelper.instance.deleteMetadata(_selectedCategory, value);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ဖျက်ပြီးပါပြီ')));
              _loadMetadata(); // UI ကို Refresh လုပ်မည်
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
                    ? const Center(child: Text('စာရင်းများ မရှိသေးပါ'))
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final bool isUsed = item['is_used'];
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                            ),
                            child: ListTile(
                              title: Text(item['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              // ⚠️ အသုံးပြုဆဲလား၊ အဟောင်းလားဆိုတာ ခွဲခြားပြပေးမည်
                              subtitle: isUsed 
                                  ? const Text('လက်ရှိ အိမ်ခြံမြေများတွင် သုံးထားသည်', style: TextStyle(color: Colors.orange, fontSize: 12))
                                  : const Text('အသုံးမပြုတော့သော အဟောင်း', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.delete_outline, 
                                  color: isUsed ? Colors.grey.shade400 : Colors.red // သုံးနေရင် မှိန်ထားမည်
                                ),
                                onPressed: () => _confirmDelete(item['name'], isUsed),
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
