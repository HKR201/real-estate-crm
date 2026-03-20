import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../db/database_helper.dart';
import 'owner_form_screen.dart';

class OwnerListScreen extends StatefulWidget {
  final String? highlightOwnerId;

  const OwnerListScreen({super.key, this.highlightOwnerId});

  @override
  State<OwnerListScreen> createState() => _OwnerListScreenState();
}

class _OwnerListScreenState extends State<OwnerListScreen> {
  List<Map<String, dynamic>> _owners = [];
  List<Map<String, dynamic>> _filteredOwners = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOwners();
  }

  Future<void> _loadOwners() async {
    setState(() => _isLoading = true);
    
    try {
      final rawData = await DatabaseHelper.instance.getAllOwners();
      // ⚠️ အရေးကြီး: Read-only error မတက်စေရန် Modifiable List အဖြစ် ပြောင်းခြင်း
      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(rawData);

      // Highlight လုပ်မည့်သူကို ထိပ်ဆုံးသို့ ဆွဲတင်မည်
      if (widget.highlightOwnerId != null) {
        final index = data.indexWhere((o) => o['id'] == widget.highlightOwnerId);
        if (index != -1) {
          final targetOwner = data.removeAt(index);
          data.insert(0, targetOwner);
        }
      }

      if (mounted) {
        setState(() {
          _owners = data;
          _filteredOwners = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading owners: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterOwners(String query) {
    final q = query.toLowerCase();
    setState(() {
      _filteredOwners = _owners.where((o) => (o['name'] ?? '').toString().toLowerCase().contains(q)).toList();
    });
  }

  void _callPhone(String phone) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ပိုင်ရှင်စာရင်း'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'အမည်ဖြင့် ရှာဖွေရန်',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterOwners('');
                        },
                      )
                    : null,
              ),
              onChanged: _filterOwners,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredOwners.isEmpty
                    ? const Center(child: Text('ပိုင်ရှင် မရှိသေးပါ'))
                    : ListView.builder(
                        itemCount: _filteredOwners.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final owner = _filteredOwners[index];
                          final isHighlighted = owner['id'] == widget.highlightOwnerId;

                          // ⚠️ Minimalist Highlight အရောင်သတ်မှတ်ချက်များ
                          final highlightBgColor = isDark 
                              ? theme.colorScheme.primary.withOpacity(0.15) 
                              : theme.colorScheme.primary.withOpacity(0.05);
                          final borderColor = isHighlighted 
                              ? theme.colorScheme.primary.withOpacity(0.5) 
                              : Colors.grey.withOpacity(0.2);

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            elevation: 0, // Minimalist ဖြစ်စေရန် အရိပ်ဖျောက်ထားသည်
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: borderColor, width: 1.0),
                            ),
                            color: isHighlighted ? highlightBgColor : theme.cardColor,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: isHighlighted 
                                    ? theme.colorScheme.primary.withOpacity(0.8) 
                                    : Colors.grey.shade200,
                                child: Icon(Icons.person, color: isHighlighted ? Colors.white : Colors.grey.shade600),
                              ),
                              title: Text(
                                owner['name'] ?? 'အမည်မသိ',
                                style: TextStyle(fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(owner['phone'] ?? 'ဖုန်းနံပါတ် မရှိပါ'),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (owner['phone'] != null && owner['phone'].toString().isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.phone, color: Colors.green),
                                      onPressed: () => _callPhone(owner['phone']),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => OwnerFormScreen(editData: owner)),
                                      );
                                      if (result == true) _loadOwners();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerFormScreen()));
          if (result == true) _loadOwners();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
