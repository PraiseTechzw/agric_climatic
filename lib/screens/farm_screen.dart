import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/farm_provider.dart';
import '../widgets/farm_card.dart';
import '../widgets/add_farm_dialog.dart';

class FarmScreen extends StatefulWidget {
  const FarmScreen({super.key});

  @override
  State<FarmScreen> createState() => _FarmScreenState();
}

class _FarmScreenState extends State<FarmScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FarmProvider>().loadFarms();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Farms',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              context.read<FarmProvider>().loadFarms();
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primaryContainer,
              ],
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: Consumer<FarmProvider>(
        builder: (context, farmProvider, child) {
          return farmProvider.isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading farms...',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                )
              : farmProvider.farms.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: farmProvider.farms.length,
                      itemBuilder: (context, index) {
                        final farm = farmProvider.farms[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: FarmCard(
                            farm: farm,
                            onTap: () {
                              _showFarmDetails(context, farm);
                            },
                            onEdit: () {
                              _showEditFarmDialog(context, farm);
                            },
                            onDelete: () {
                              _showDeleteConfirmation(context, farm);
                            },
                          ),
                        );
                      },
                    );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddFarmDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.agriculture_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No farms added yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first farm to start tracking weather patterns and get personalized recommendations',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                _showAddFarmDialog(context);
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Your First Farm'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFarmDetails(BuildContext context, dynamic farm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(farm.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location: ${farm.location}'),
            Text('Crop: ${farm.crop}'),
            Text('Area: ${farm.area} acres'),
            Text('Status: ${farm.status}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddFarmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddFarmDialog(),
    );
  }

  void _showEditFarmDialog(BuildContext context, dynamic farm) {
    showDialog(
      context: context,
      builder: (context) => AddFarmDialog(farm: farm),
    );
  }

  void _showDeleteConfirmation(BuildContext context, dynamic farm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Farm'),
        content: Text('Are you sure you want to delete ${farm.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<FarmProvider>().deleteFarm(farm.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
