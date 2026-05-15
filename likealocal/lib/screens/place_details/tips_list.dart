import 'package:flutter/material.dart';
import '../../models/place.dart';
import '../../services/place_service.dart';

class TipsList extends StatefulWidget {
  final Place place;

  const TipsList({super.key, required this.place});

  @override
  State<TipsList> createState() => _TipsListState();
}

class _TipsListState extends State<TipsList> {
  final PlaceService _placeService = PlaceService();
  final TextEditingController _tipController = TextEditingController();
  bool _isAddingTip = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _tipController.dispose();
    super.dispose();
  }

  Future<void> _addTip() async {
    if (_tipController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please write a tip');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _placeService.addTipToPlace(widget.place.id,
          text: _tipController.text.trim());

      _tipController.clear();
      setState(() => _isAddingTip = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tip added successfully!')),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to add tip: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tips',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _isAddingTip = !_isAddingTip),
              icon: Icon(_isAddingTip ? Icons.close : Icons.add),
              label: Text(_isAddingTip ? 'Cancel' : 'Add Tip'),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Add tip form
        if (_isAddingTip) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _tipController,
                    decoration: const InputDecoration(
                      labelText: 'Share your tip',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  if (_errorMessage != null) ...[
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _addTip,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Add Tip'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Tips list
        if (widget.place.tips.isEmpty) ...[
          const Center(
            child: Text('No tips yet. Be the first to share!'),
          ),
        ] else ...[
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.place.tips.length,
            itemBuilder: (context, index) {
              final tip = widget.place.tips[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(tip.text),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
