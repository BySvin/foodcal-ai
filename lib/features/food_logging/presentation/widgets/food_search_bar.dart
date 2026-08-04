import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_durations.dart';

/// Debounced search field — fires [onQueryChanged] `AppDurations.searchDebounce`
/// after the user stops typing, not on every keystroke.
class FoodSearchBar extends StatefulWidget {
  const FoodSearchBar({super.key, required this.onQueryChanged, this.autofocus = false});

  final ValueChanged<String> onQueryChanged;
  final bool autofocus;

  @override
  State<FoodSearchBar> createState() => _FoodSearchBarState();
}

class _FoodSearchBarState extends State<FoodSearchBar> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(AppDurations.searchDebounce, () => widget.onQueryChanged(value.trim()));
    setState(() {}); // refresh the clear-button visibility
  }

  void _clear() {
    _controller.clear();
    _debounce?.cancel();
    widget.onQueryChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      onChanged: _onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search foods',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(icon: const Icon(Icons.close), onPressed: _clear),
      ),
    );
  }
}
