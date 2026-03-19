import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class DynamicDropdown extends StatefulWidget {
  final String label;
  final String category;
  final String? selectedValue;
  final Function(String?) onChanged;

  const DynamicDropdown({
    super.key,
    required this.label,
    required this.category,
    this.selectedValue,
    required this.onChanged,
  });

  @override
  State<DynamicDropdown> createState() => _DynamicDropdownState();
}

class _DynamicDropdownState extends State<DynamicDropdown> {
  List<String> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    
    // ၁။ ကိုယ်တိုင် မှတ်ထားသော (Metadata) စာရင်းများကို ဆွဲယူမည်
    List<String> metaItems = await DatabaseHelper.instance.getMetadata(widget.category);
    
    // ၂။ Cloud မှ ပြန်လည်ပါလာသော အိမ်ခြံမြေများထဲမှ နာမည်များကိုပါ အလိုလို ဆွဲထုတ်မည်
    String columnName = '';
    if (widget.category == 'location') columnName = 'location_id';
    else if (widget.category == 'house_type') columnName = 'house_type';
    else if (widget.category == 'road_type') columnName = 'road_type';
    else if (widget.category == 'land_type') columnName = 'land_type';

    List<String> distinctItems = [];
    if (columnName.isNotEmpty) {
      distinctItems = await DatabaseHelper.instance.getDistinctPropertyValues(columnName);
    }

    // ၃။ စာရင်းနှစ်ခုကို ပေါင်းပြီး ထပ်နေတာတွေ (Duplicate) ကို အလိုလို ဖယ်ရှားမည်
    Set<String> combined = {...metaItems, ...distinctItems};
    
    // ၄။ ရွေးချယ်ထားသော တန်ဖိုးက စာရင်းထဲမရှိရင် (ဥပမာ - Database Error ကြောင့်) ထည့်ပေးမည်
    if (widget.selectedValue != null && widget.selectedValue!.isNotEmpty) {
      combined.add(widget.selectedValue!);
    }

    List<String> finalList = combined.toList().where((e) => e.isNotEmpty).toList();
    finalList.sort(); // အက္ခရာစဉ်အတိုင်း ပြန်စီမည်

    setState(() {
      _items = finalList;
      _isLoading = false;
    });
  }

  void _addNewItem() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.label} အသစ်ထည့်ရန်'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'စာရိုက်ထည့်ပါ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ပယ်ဖျက်မည်')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white),
            onPressed: () async {
              String newVal = controller.text.trim();
              if (newVal.isNotEmpty) {
                // အသစ်ကို Database တွင် မှတ်မည်
                await DatabaseHelper.instance.insertMetadata(widget.category, newVal);
                Navigator.pop(context, newVal);
              }
            },
            child: const Text('ထည့်မည်'),
          ),
        ],
      ),
    ).then((newVal) {
      if (newVal != null) {
        _loadItems().then((_) {
          widget.onChanged(newVal as String);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 55,
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)),
        child: const Center(child: LinearProgressIndicator()),
      );
    }

    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: widget.label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      isExpanded: true,
      value: (_items.contains(widget.selectedValue)) ? widget.selectedValue : null,
      items: [
        ..._items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))),
        // Prefix အစား အောက်ဆုံးတွင် "အသစ်ထည့်မည်" ခလုတ်ကိုသာ ပြမည်
        const DropdownMenuItem(
          value: '__ADD_NEW__',
          child: Row(
            children: [
              Icon(Icons.add_circle_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text('အသစ်ထည့်မည် (+)', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ],
          ),
        )
      ],
      onChanged: (val) {
        if (val == '__ADD_NEW__') {
          _addNewItem();
        } else {
          widget.onChanged(val);
        }
      },
    );
  }
}
