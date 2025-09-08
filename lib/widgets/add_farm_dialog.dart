import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/farm_provider.dart';
import '../models/farm.dart';

class AddFarmDialog extends StatefulWidget {
  final Farm? farm;

  const AddFarmDialog({super.key, this.farm});

  @override
  State<AddFarmDialog> createState() => _AddFarmDialogState();
}

class _AddFarmDialogState extends State<AddFarmDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _cropController = TextEditingController();
  final _areaController = TextEditingController();
  String _status = 'active';

  @override
  void initState() {
    super.initState();
    if (widget.farm != null) {
      _nameController.text = widget.farm!.name;
      _locationController.text = widget.farm!.location;
      _cropController.text = widget.farm!.crop;
      _areaController.text = widget.farm!.area.toString();
      _status = widget.farm!.status;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _cropController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.farm == null ? 'Add Farm' : 'Edit Farm'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Farm Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter farm name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cropController,
                decoration: const InputDecoration(
                  labelText: 'Crop',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter crop';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _areaController,
                decoration: const InputDecoration(
                  labelText: 'Area (acres)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter area';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                  DropdownMenuItem(
                      value: 'maintenance', child: Text('Maintenance')),
                ],
                onChanged: (value) {
                  setState(() {
                    _status = value!;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveFarm,
          child: Text(widget.farm == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }

  void _saveFarm() {
    if (_formKey.currentState!.validate()) {
      final farm = Farm(
        id: widget.farm?.id ?? '',
        name: _nameController.text,
        location: _locationController.text,
        crop: _cropController.text,
        area: double.parse(_areaController.text),
        status: _status,
        createdAt: widget.farm?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.farm == null) {
        context.read<FarmProvider>().addFarm(farm);
      } else {
        context.read<FarmProvider>().updateFarm(farm);
      }

      Navigator.pop(context);
    }
  }
}
