import 'package:flutter/material.dart';

class SearchBarWidget extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  // Voice search
  final VoidCallback? onMicTap;
  final bool isListening;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onClear,
    this.onMicTap,
    this.isListening = false,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late FocusNode _focusNode;

  static const Color primaryColor = Color(0xFFE26D45);
  static const Color textColor = Color(0xFF1F1F28);
  static const Color mutedText = Color(0xFF777777);

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant SearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Ensures the clear/mic UI refreshes when text is changed from voice input.
    if (oldWidget.controller.text != widget.controller.text ||
        oldWidget.isListening != widget.isListening) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _clearSearch() {
    widget.controller.clear();
    widget.onClear?.call();

    setState(() {});

    Future.delayed(
      const Duration(milliseconds: 50),
      () {
        if (mounted) {
          _focusNode.requestFocus();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          onChanged: (value) {
            widget.onChanged(value);

            if (!_focusNode.hasFocus) {
              _focusNode.requestFocus();
            }

            setState(() {});
          },
          style: const TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: widget.isListening
                ? 'Listening... speak now'
                : 'Search local places...',
            hintStyle: const TextStyle(
              color: mutedText,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: primaryColor,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasText)
                  IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(
                      Icons.clear_rounded,
                      color: mutedText,
                    ),
                    onPressed: _clearSearch,
                  ),

                // Mic button
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: widget.isListening
                        ? primaryColor.withOpacity(0.12)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    tooltip:
                        widget.isListening ? 'Stop listening' : 'Voice search',
                    onPressed: widget.onMicTap,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: widget.isListening
                          ? const Icon(
                              Icons.mic_rounded,
                              key: ValueKey('mic_on'),
                              color: primaryColor,
                            )
                          : const Icon(
                              Icons.mic_none_rounded,
                              key: ValueKey('mic_off'),
                              color: mutedText,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
