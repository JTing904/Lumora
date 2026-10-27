import 'package:flutter/material.dart';

import 'lu_theme.dart';

/// A labelled field: the label above, a 52-tall box with a gold edge when
/// focused, an optional hint below.
class LuTextField extends StatefulWidget {
  const LuTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.helper,
    this.obscure = false,
    this.keyboardType,
    this.autofillHints = const [],
    this.textInputAction,
    this.onSubmitted,
    this.autofocus = false,
    this.code = false,
    this.trailing,
    this.focusNode,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;

  /// A line of help under the box.
  final String? helper;
  final bool obscure;
  final TextInputType? keyboardType;
  final Iterable<String> autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  /// A code to type (an invite code): capitals, Outfit, spaced out.
  final bool code;
  final Widget? trailing;
  final FocusNode? focusNode;

  @override
  State<LuTextField> createState() => _LuTextFieldState();
}

class _LuTextFieldState extends State<LuTextField> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  void _onFocus() => setState(() => _focused = _focus.hasFocus);

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.code
        ? const TextStyle(
            fontFamily: LuFonts.display,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
            color: LuColors.text,
          )
        : LuText.body;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.label, style: LuText.label),
        const SizedBox(height: LuSpace.s),
        AnimatedContainer(
          duration: LuMotion.focus,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: LuColors.field,
            borderRadius: LuRadius.field,
            border: Border.all(
              color: _focused ? LuColors.gold : LuColors.line,
              width: _focused ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  obscureText: widget.obscure,
                  keyboardType: widget.keyboardType,
                  autofillHints: widget.autofillHints,
                  textInputAction: widget.textInputAction,
                  onSubmitted: widget.onSubmitted,
                  autofocus: widget.autofocus,
                  autocorrect: false,
                  enableSuggestions: !widget.obscure && !widget.code,
                  textCapitalization: widget.code
                      ? TextCapitalization.characters
                      : TextCapitalization.none,
                  style: style,
                  cursorColor: LuColors.gold,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: widget.hint,
                    hintStyle: style.copyWith(color: const Color(0xFF77736B)),
                  ),
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ),
        if (widget.helper != null) ...[
          const SizedBox(height: 6),
          Text(widget.helper!, style: LuText.caption),
        ],
      ],
    );
  }
}
