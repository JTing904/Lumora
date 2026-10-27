import 'package:flutter/material.dart';

import '../../services/metadata/localized_meta.dart';

/// A title in the viewer's language.
///
/// Catalogues and saved sessions carry the English name the scrapers search
/// with. For an IMDb id, the Chinese name comes from TMDb (cached by
/// [LocalizedMeta], so a title is asked for once) and replaces [fallback]
/// once it lands. Anything else, or no answer, shows [fallback].
class LocalTitleText extends StatefulWidget {
  const LocalTitleText({
    super.key,
    required this.id,
    required this.fallback,
    required this.series,
    this.maxLines,
    this.overflow,
    this.style,
    this.textAlign,
  });

  final String id;
  final String fallback;
  final bool series;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  State<LocalTitleText> createState() => _LocalTitleTextState();
}

class _LocalTitleTextState extends State<LocalTitleText> {
  String? _local;

  @override
  void initState() {
    super.initState();
    _lookUp();
  }

  @override
  void didUpdateWidget(LocalTitleText old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) {
      _local = null;
      _lookUp();
    }
  }

  Future<void> _lookUp() async {
    final id = widget.id;
    if (!id.startsWith('tt')) return;
    final text = await LocalizedMeta.forImdbId(id, series: widget.series);
    if (!mounted || widget.id != id) return;
    final name = text?.name;
    if (name != null && name.isNotEmpty) setState(() => _local = name);
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _local ?? widget.fallback,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      style: widget.style,
      textAlign: widget.textAlign,
    );
  }
}
