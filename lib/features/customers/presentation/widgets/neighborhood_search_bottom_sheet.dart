import 'dart:math';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:flutter/material.dart';
import 'package:app/core/utils/string_utils.dart';
import 'package:app/features/customers/domain/models/salta_neighborhoods.dart';

class NeighborhoodSearchBottomSheet extends StatefulWidget {
  final ValueChanged<String> onSelected;

  const NeighborhoodSearchBottomSheet({super.key, required this.onSelected});

  @override
  State<NeighborhoodSearchBottomSheet> createState() =>
      _NeighborhoodSearchBottomSheetState();
}

class _NeighborhoodSearchBottomSheetState
    extends State<NeighborhoodSearchBottomSheet> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;
  String _searchQuery = '';
  int _currentPage = 1;
  static const int _pageSize = 15;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      final totalFiltered = _filteredNeighborhoods().length;
      if (_currentPage * _pageSize < totalFiltered) {
        setState(() {
          _currentPage++;
        });
      }
    }
  }

  List<String> _filteredNeighborhoods() {
    if (_searchQuery.isEmpty) {
      return saltaNeighborhoods;
    }
    return saltaNeighborhoods
        .where((n) => StringUtils.fuzzyMatch(_searchQuery, n))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredNeighborhoods();
    final visibleCount = min(filtered.length, _currentPage * _pageSize);

    return Container(
      decoration: BoxDecoration(
        color: context.marilin.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Seleccionar Barrio',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.marilin.ink,
                ),
              ),
              IconButton(
                tooltip: 'Cerrar',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar barrio...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      tooltip: 'Limpiar búsqueda',
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                          _currentPage = 1;
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.marilin.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.marilin.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: MarilinColors.brandBlue,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
                _currentPage = 1;
              });
            },
          ),
          const SizedBox(height: 12),
          Flexible(
            child: filtered.isEmpty
                ? Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No se encontraron barrios',
                        style: TextStyle(color: context.marilin.textMuted),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    shrinkWrap: true,
                    itemCount: visibleCount,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return ListTile(
                        title: Text(item),
                        onTap: () {
                          widget.onSelected(item);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
