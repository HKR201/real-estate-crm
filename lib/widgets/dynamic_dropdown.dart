import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class DynamicDropdown extends StatefulWidget {
  final String label;
  final String category; // ဥပမာ - 'road_type', 'land_type', 'location'
  final String? selectedValue;
  final ValueChanged<String?> onChanged;

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
  // Dropdown ကိုနှိပ်လျှင် အောက်မှ BottomSheet တက်လာစေရန်
  void _showSelectionSheet(BuildContext context) async {
    // Database ထဲမှ ရှိပြီးသား စာရင်းများကို ဆွဲထုတ်မည်
    List<String> items = await DatabaseHelper.instance.getMetadata(widget.category);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Keyboard တက်လာလျှင် အပေါ်သို့ လိုက်တက်ရန်
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return _DropdownSheet(
          category: widget.category,
          label: widget.label,
          initialItems: items,
          onItemSelected: (value) {
            widget.onChanged(value);
            Navigator.pop(context); // ရွေးပြီးသည်နှင့် ပိတ်မည်
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // အပြင်ပန်းကြည့်လျှင် ရိုးရိုး Text Input ပုံစံရှိနေမည်
    return InkWell(
      onTap: () => _showSelectionSheet(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          widget.selectedValue ?? 'ရွေးချယ်ပါ',
          style: TextStyle(color: widget.selectedValue == null ? Colors.grey : Theme.of(context).colorScheme.onSurface, fontSize: 16),
        ),
      ),
    );
  }
}

// Bottom Sheet အတွင်းရှိ Search နှင့် Add New လုပ်ဆောင်ချက်များ
class _DropdownSheet extends StatefulWidget {
  final String category;
  final String label;
  final List<String> initialItems;
  final ValueChanged<String> onItemSelected;

  const _DropdownSheet({
    required this.category,
    required this.label,
    required this.initialItems,
    required this.onItemSelected,
  });

  @override
  State<_DropdownSheet> createState() => _DropdownSheetState();
}

class _DropdownSheetState extends State<_DropdownSheet> {
  late List<String> items;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    items = widget.initialItems;
  }

  // စာသားအသစ်ကို Database သို့ လှမ်းသိမ်းမည်
  void _addNewItem() async {
    final newValue = _searchController.text.trim();
    if (newValue.isNotEmpty && !items.contains(newValue)) {
      await DatabaseHelper.instance.insertMetadata(widget.category, newValue);
      widget.onItemSelected(newValue); // သိမ်းပြီးသည်နှင့် ရွေးချယ်ပြီးသားဖြစ်သွားမည်
    }
  }

  @override
  Widget build(BuildContext context) {
    // ရိုက်ရှာထားသော စာသားနှင့် ကိုက်ညီသည်များကို စစ်ထုတ်မည်
    final filteredItems = items.where((e) => e.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
    // ရှာလို့မတွေ့မှသာ "အသစ်ထည့်ရန်" ခလုတ် ပေါ်လာစေမည်
    final bool showAddButton = _searchController.text.isNotEmpty && filteredItems.isEmpty;

    return Padding(
      // Keyboard တက်လာပါက ကွယ်မသွားအောင် viewInsets သုံးထားသည်
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 24, left: 16, right: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.label} ရွေးချယ်ရန်', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          TextField(
            controller: _searchController,
            autofocus: true, // ပွင့်လာသည်နှင့် စာတန်းရိုက်ရန် အသင့်ဖြစ်နေမည်
            decoration: const InputDecoration(
              labelText: 'ရှာဖွေရန် (သို့) အသစ်ရိုက်ထည့်ရန်',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() {}),
          ),
          const SizedBox(height: 16),
          
          if (showAddButton)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _addNewItem,
                icon: const Icon(Icons.add),
                label: Text('"${_searchController.text}" ကို အသစ်ထည့်မည်'),
              ),
            ),
            
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(filteredItems[index]),
                  trailing: const Icon(Icons.check_circle_outline, color: Colors.grey, size: 20),
                  onTap: () => widget.onItemSelected(filteredItems[index]),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
