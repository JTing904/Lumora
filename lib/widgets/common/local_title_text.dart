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
    this.year,
  });

  final String id;
  final String fallback;
  final bool series;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextStyle? style;
  final TextAlign? textAlign;

  /// The release year, for a title with no IMDb id: it is then looked up by
  /// [fallback] and year instead ([LocalizedMeta.forTitle]).
  final String? year;

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
    final String? name;
    if (id.startsWith('tt')) {
      name = (await LocalizedMeta.forImdbId(id, series: widget.series))?.name;
    } else if (widget.year != null) {
      name = await LocalizedMeta.forTitle(
        widget.fallback,
        year: widget.year,
        series: widget.series,
      );
    } else {
      return;
    }
    if (!mounted || widget.id != id) return;
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

/// [fallback] (an English synopsis), or TMDb's Chinese synopsis of the title
/// named [title] when the app is in Chinese and TMDb has one
/// ([LocalizedMeta.textForTitle]).
class LocalOverviewText extends StatefulWidget {
  const LocalOverviewText({
    super.key,
    required this.title,
    required this.fallback,
    required this.series,
    this.year,
    this.maxLines,
    this.overflow,
    this.style,
  });

  final String title;
  final String fallback;
  final bool series;
  final String? year;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextStyle? style;

  @override
  State<LocalOverviewText> createState() => _LocalOverviewTextState();
}

class _LocalOverviewTextState extends State<LocalOverviewText> {
  String? _local;

  @override
  void initState() {
    super.initState();
    _lookUp();
  }

  @override
  void didUpdateWidget(LocalOverviewText old) {
    super.didUpdateWidget(old);
    if (old.title != widget.title || old.year != widget.year) {
      _local = null;
      _lookUp();
    }
  }

  Future<void> _lookUp() async {
    final title = widget.title;
    final text = await LocalizedMeta.textForTitle(
      title,
      year: widget.year,
      series: widget.series,
    ).catchError((Object _) => null);
    if (!mounted || widget.title != title) return;
    final overview = text?.overview;
    if (overview != null && overview.isNotEmpty) {
      setState(() => _local = overview);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _local ?? widget.fallback,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      style: widget.style,
    );
  }
}
