import 'package:flutter/material.dart';
import 'dart:io';
import '../database/database_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final Set<int> _selectedItems = {};
  bool _isSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        actions: [
          if (_isSelectionMode) ...[
            TextButton(
              onPressed: _selectedItems.isEmpty ? null : _deleteSelected,
              child: Text(
                'Delete (${_selectedItems.length})',
                style: TextStyle(
                  color: _selectedItems.isEmpty ? Colors.grey : Colors.red,
                ),
              ),
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                setState(() {
                  _isSelectionMode = true;
                });
              },
            ),
          ],
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper.instance.getAllScans(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No scan history'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final scan = snapshot.data![index];
              return _buildHistoryItem(context, scan);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, Map<String, dynamic> scan) {
    final isSelected = _selectedItems.contains(scan['id']);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Stack(
          children: [
            FutureBuilder<File>(
              future: _getImageFile(scan['filename']),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return SizedBox(
                    width: 50,
                    height: 50,
                    child: Image.file(
                      snapshot.data!,
                      fit: BoxFit.cover,
                    ),
                  );
                }
                return const SizedBox(
                  width: 50,
                  height: 50,
                  child: Icon(Icons.image),
                );
              },
            ),
            if (_isSelectionMode)
              Positioned.fill(
                child: Container(
                  color: isSelected ? Colors.blue.withOpacity(0.3) : Colors.transparent,
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              ),
          ],
        ),
        title: Text('Scan ${scan['id']}'),
        subtitle: Text('${scan['date']} ${scan['time']}'),
        onTap: () {
          if (_isSelectionMode) {
            setState(() {
              if (isSelected) {
                _selectedItems.remove(scan['id']);
              } else {
                _selectedItems.add(scan['id']);
              }
            });
          } else {
            _showScanDetails(context, scan);
          }
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            setState(() {
              _isSelectionMode = true;
              _selectedItems.add(scan['id']);
            });
          }
        },
      ),
    );
  }

  Future<void> _deleteSelected() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Items'),
        content: Text('Delete ${_selectedItems.length} selected items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Delete files and database entries
      for (final id in _selectedItems) {
        final scan = await DatabaseHelper.instance.getScanById(id);
        if (scan != null) {
          final file = await _getImageFile(scan['filename']);
          if (await file.exists()) {
            await file.delete();
          }
          await DatabaseHelper.instance.deleteScan(id);
        }
      }

      setState(() {
        _selectedItems.clear();
        _isSelectionMode = false;
      });
    }
  }

  Future<File> _getImageFile(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    return File(path.join(directory.path, filename));
  }

  void _showScanDetails(BuildContext context, Map<String, dynamic> scan) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image with shimmer loading
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FutureBuilder<File>(
                        future: _getImageFile(scan['filename']),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                snapshot.data!,
                                fit: BoxFit.cover,
                              ),
                            );
                          }
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Details with better formatting
                    _DetailItem(
                      icon: Icons.calendar_today,
                      label: 'Date',
                      value: scan['date'],
                    ),
                    _DetailItem(
                      icon: Icons.access_time,
                      label: 'Time',
                      value: scan['time'],
                    ),
                    _DetailItem(
                      icon: Icons.location_on,
                      label: 'Location',
                      value: scan['location'],
                    ),
                    _DetailItem(
                      icon: Icons.storage,
                      label: 'File Size',
                      value: '${(scan['file_size'] / 1024).toStringAsFixed(2)} KB',
                    ),
                    const SizedBox(height: 16),
                    // API Response section
                    const Text(
                      'API Response',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: SelectableText(
                        scan['api_return_code'] ?? 'No API response',
                        style: const TextStyle(fontFamily: 'Courier'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }
} 