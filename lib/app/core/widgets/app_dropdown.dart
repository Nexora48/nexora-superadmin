import 'package:flutter/material.dart';

/// The one dropdown field used across the app. Same arguments as [DropdownButtonFormField] for the ones the screens use;
/// pass a `key` to rebuild with a new initial value.
///
/// Narrow screens (phones) open a rounded bottom-sheet picker, wide screens a soft floating menu; both tick the chosen entry.
class AppDropdown<T> extends StatefulWidget {
  final T? initialValue;
  final InputDecoration? decoration;
  final List<DropdownMenuItem<T>>? items;
  final ValueChanged<T?>? onChanged;
  final bool isExpanded;
  final bool isDense;
  final Widget? hint;

  const AppDropdown({
    super.key,
    this.initialValue,
    this.decoration,
    required this.items,
    required this.onChanged,
    this.isExpanded = true,
    this.isDense = false,
    this.hint,
  });

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  T? _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  void didUpdateWidget(covariant AppDropdown<T> old) {
    super.didUpdateWidget(old);
    if (widget.initialValue != old.initialValue) _value = widget.initialValue;
  }

  List<DropdownMenuItem<T>> get _items => widget.items ?? const [];

  void _choose(T? v) {
    setState(() => _value = v);
    widget.onChanged?.call(v);
  }

  // ── Phone: a field that opens a bottom sheet ─────────────────────────────
  Future<void> _openSheet(BuildContext context) async {
    final scheme = Theme.of(context).colorScheme;
    final title = widget.decoration?.labelText ?? widget.decoration?.hintText;
    final picked = await showModalBottomSheet<_Picked<T>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: scheme.surface,
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: scheme.onSurface)),
              ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                children: [
                  for (final i in _items)
                    _SheetRow(
                      selected: i.value == _value,
                      enabled: i.enabled,
                      onTap: () => Navigator.of(sheet).pop(_Picked<T>(i.value)),
                      child: i.child,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (picked != null) _choose(picked.value);
  }

  Widget _sheetField(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    T? v = _value;
    final match = _items.where((i) => i.value == v);
    final shown = match.isNotEmpty ? match.first.child : widget.hint;
    final base = widget.decoration ?? const InputDecoration();
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: widget.onChanged == null ? null : () => _openSheet(context),
      child: InputDecorator(
        isEmpty: shown == null,
        isFocused: false,
        decoration: base.copyWith(
          suffixIcon: base.suffixIcon ?? Icon(Icons.keyboard_arrow_down_rounded, color: scheme.onSurfaceVariant),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: scheme.onSurface),
          child: shown ?? const SizedBox.shrink(),
        ),
      ),
    );
  }

  // ── Wide screens: the floating menu, rounded, with a tick ────────────────
  Widget _menuField(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DropdownButtonFormField<T>(
      initialValue: widget.initialValue,
      decoration: widget.decoration,
      isExpanded: widget.isExpanded,
      isDense: widget.isDense,
      hint: widget.hint,
      borderRadius: BorderRadius.circular(16),
      dropdownColor: scheme.surface,
      elevation: 8,
      menuMaxHeight: 320,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: scheme.onSurfaceVariant),
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: scheme.onSurface),
      // the button shows the plain label; only the menu entries carry the tick
      selectedItemBuilder: (_) => [for (final i in _items) Align(alignment: Alignment.centerLeft, child: i.child)],
      items: [
        for (final i in _items)
          DropdownMenuItem<T>(
            value: i.value,
            enabled: i.enabled,
            child: Row(
              children: [
                Expanded(child: i.child),
                if (i.value == _value) Icon(Icons.check_rounded, size: 18, color: scheme.primary),
              ],
            ),
          ),
      ],
      onChanged: widget.onChanged == null ? null : _choose,
    );
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return narrow ? _sheetField(context) : _menuField(context);
  }
}

/// Wraps the picked value so choosing a null entry differs from dismissing the sheet.
class _Picked<T> {
  final T? value;
  const _Picked(this.value);
}

class _SheetRow extends StatelessWidget {
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final Widget child;

  const _SheetRow({required this.selected, required this.enabled, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? scheme.primary.withAlpha(24) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: DefaultTextStyle.merge(
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: enabled ? (selected ? scheme.primary : scheme.onSurface) : scheme.onSurface.withAlpha(110),
                    ),
                    child: child,
                  ),
                ),
                if (selected) Icon(Icons.check_circle_rounded, size: 20, color: scheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
