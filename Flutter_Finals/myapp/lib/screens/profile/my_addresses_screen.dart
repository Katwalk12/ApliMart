import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/address_service.dart';

class MyAddressesScreen extends StatefulWidget {
  const MyAddressesScreen({super.key});

  @override
  State<MyAddressesScreen> createState() => _MyAddressesScreenState();
}

class _MyAddressesScreenState extends State<MyAddressesScreen> {
  List<SavedAddress> _addresses = [];
  int _defaultIndex = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final addresses = await AddressService.loadAll();
    final defaultIdx = await AddressService.getDefaultIndex();
    if (mounted) {
      setState(() {
        _addresses = addresses;
        _defaultIndex =
            defaultIdx.clamp(0, addresses.isEmpty ? 0 : addresses.length - 1);
        _loading = false;
      });
    }
  }

  Future<void> _setDefault(int index) async {
    await AddressService.setDefaultIndex(index);
    if (mounted) setState(() => _defaultIndex = index);
  }

  Future<void> _delete(int index) async {
    final updated = List<SavedAddress>.from(_addresses)..removeAt(index);
    await AddressService.saveAll(updated);
    int newDefault = _defaultIndex;
    if (updated.isEmpty) {
      newDefault = 0;
    } else if (_defaultIndex >= updated.length) {
      newDefault = updated.length - 1;
    }
    await AddressService.setDefaultIndex(newDefault);
    if (mounted) setState(() { _addresses = updated; _defaultIndex = newDefault; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [AppColors.navyBlue, AppColors.primaryBlue]),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Addresses',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showSheet(context),
            tooltip: 'Add address',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : _addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_off_outlined,
                          size: 56, color: AppColors.lightBlue),
                      const SizedBox(height: 12),
                      const Text('No saved addresses',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkGrey)),
                      const SizedBox(height: 8),
                      const Text('Add an address to get started',
                          style: TextStyle(
                              color: AppColors.grey, fontSize: 13)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => _showSheet(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Address'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.navyBlue,
                            foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _addresses.length + 1,
                  itemBuilder: (_, i) {
                    if (i == _addresses.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: OutlinedButton.icon(
                          onPressed: () => _showSheet(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Add New Address'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            side: const BorderSide(color: AppColors.lightBlue),
                            foregroundColor: AppColors.navyBlue,
                          ),
                        ),
                      );
                    }
                    final addr = _addresses[i];
                    final isDefault = i == _defaultIndex;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDefault
                              ? AppColors.primaryBlue
                              : AppColors.lightBlue.withValues(alpha: 0.3),
                          width: isDefault ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.veryLightBlue,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(addr.label,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryBlue)),
                              ),
                              const SizedBox(width: 8),
                              if (isDefault)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('Default',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.primaryBlue)),
                                ),
                              const Spacer(),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert,
                                    color: AppColors.grey, size: 20),
                                onSelected: (val) async {
                                  if (val == 'default') {
                                    await _setDefault(i);
                                  } else if (val == 'edit') {
                                    await _showSheet(context, editIndex: i);
                                  } else if (val == 'delete') {
                                    await _delete(i);
                                  }
                                },
                                itemBuilder: (_) => [
                                  if (!isDefault)
                                    const PopupMenuItem(
                                        value: 'default',
                                        child: Text('Set as default')),
                                  const PopupMenuItem(
                                      value: 'edit', child: Text('Edit')),
                                  PopupMenuItem(
                                      value: 'delete',
                                      child: const Text('Delete',
                                          style:
                                              TextStyle(color: Colors.red))),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(addr.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.darkGrey)),
                          if (addr.phone.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(addr.phone,
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.grey)),
                          ],
                          const SizedBox(height: 2),
                          Text(addr.fullAddress,
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.grey)),
                          if (addr.targetLocation.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.place_outlined,
                                    size: 12, color: AppColors.grey),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(addr.targetLocation,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.grey)),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _showSheet(BuildContext context, {int? editIndex}) async {
    final existing = editIndex != null ? _addresses[editIndex] : null;
    final labelCtrl =
        TextEditingController(text: existing?.label ?? '');
    final nameCtrl =
        TextEditingController(text: existing?.name ?? '');
    final phoneCtrl =
        TextEditingController(text: existing?.phone ?? '');
    final streetCtrl =
        TextEditingController(text: existing?.street ?? '');
    final cityCtrl =
        TextEditingController(text: existing?.city ?? '');
    final provinceCtrl =
        TextEditingController(text: existing?.province ?? '');
    final postalCtrl =
        TextEditingController(text: existing?.postal ?? '');
    final targetCtrl =
        TextEditingController(text: existing?.targetLocation ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _AddressSheet(
        editIndex: editIndex,
        labelCtrl: labelCtrl,
        nameCtrl: nameCtrl,
        phoneCtrl: phoneCtrl,
        streetCtrl: streetCtrl,
        cityCtrl: cityCtrl,
        provinceCtrl: provinceCtrl,
        postalCtrl: postalCtrl,
        targetCtrl: targetCtrl,
        initialDefault:
            editIndex == null ? _addresses.isEmpty : editIndex == _defaultIndex,
        onSave: (isDefault) async {
          final addr = SavedAddress(
            label: labelCtrl.text.trim().isEmpty
                ? 'Home'
                : labelCtrl.text.trim(),
            name: nameCtrl.text.trim(),
            phone: phoneCtrl.text.trim(),
            street: streetCtrl.text.trim(),
            city: cityCtrl.text.trim(),
            province: provinceCtrl.text.trim(),
            postal: postalCtrl.text.trim(),
            targetLocation: targetCtrl.text.trim(),
          );
          final updated = List<SavedAddress>.from(_addresses);
          int newDefault = _defaultIndex;
          if (editIndex != null) {
            updated[editIndex] = addr;
            if (isDefault) newDefault = editIndex;
          } else {
            updated.add(addr);
            if (isDefault) newDefault = updated.length - 1;
          }
          await AddressService.saveAll(updated);
          await AddressService.setDefaultIndex(newDefault);
          if (context.mounted) {
            setState(() {
              _addresses = updated;
              _defaultIndex = newDefault;
            });
            Navigator.pop(ctx);
          }
        },
      ),
    );

    for (final c in [
      labelCtrl, nameCtrl, phoneCtrl,
      streetCtrl, cityCtrl, provinceCtrl,
      postalCtrl, targetCtrl,
    ]) {
      c.dispose();
    }
  }
}

class _AddressSheet extends StatefulWidget {
  final int? editIndex;
  final TextEditingController labelCtrl, nameCtrl, phoneCtrl;
  final TextEditingController streetCtrl, cityCtrl, provinceCtrl;
  final TextEditingController postalCtrl, targetCtrl;
  final bool initialDefault;
  final Future<void> Function(bool isDefault) onSave;

  const _AddressSheet({
    required this.editIndex,
    required this.labelCtrl,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.streetCtrl,
    required this.cityCtrl,
    required this.provinceCtrl,
    required this.postalCtrl,
    required this.targetCtrl,
    required this.initialDefault,
    required this.onSave,
  });

  @override
  State<_AddressSheet> createState() => _AddressSheetState();
}

class _AddressSheetState extends State<_AddressSheet> {
  late bool _isDefault;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _isDefault = widget.initialDefault;
  }

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    TextInputType keyboard = TextInputType.text,
    bool floatLabel = false,
  }) =>
      TextField(
        controller: ctrl,
        keyboardType: keyboard,
        decoration: InputDecoration(
          hintText: floatLabel ? null : hint,
          labelText: floatLabel ? hint : null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.primaryBlue),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.editIndex != null ? 'Edit Address' : 'Add Address',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navyBlue),
            ),
            const SizedBox(height: 16),
            _field(widget.labelCtrl, 'Label (Home, Work...)',
                floatLabel: true),
            const SizedBox(height: 10),
            _field(widget.nameCtrl, 'Recipient name'),
            const SizedBox(height: 10),
            _field(widget.phoneCtrl, 'Phone number',
                keyboard: TextInputType.phone),
            const SizedBox(height: 10),
            _field(widget.streetCtrl, 'Street address'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _field(widget.cityCtrl, 'City')),
                const SizedBox(width: 10),
                Expanded(
                    child: _field(widget.provinceCtrl, 'Province')),
              ],
            ),
            const SizedBox(height: 10),
            _field(widget.postalCtrl, 'Postal code',
                keyboard: TextInputType.number),
            const SizedBox(height: 10),
            _field(widget.targetCtrl,
                'Landmark / Target location'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Set as default',
                    style: TextStyle(
                        fontSize: 14, color: Colors.black87)),
                Switch(
                  value: _isDefault,
                  onChanged: (v) =>
                      setState(() => _isDefault = v),
                  activeThumbColor: AppColors.primaryBlue,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving
                    ? null
                    : () async {
                        setState(() => _saving = true);
                        await widget.onSave(_isDefault);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(
                        widget.editIndex != null
                            ? 'Save Changes'
                            : 'Add Address',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
