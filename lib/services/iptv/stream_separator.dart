/// Recognises the category headings portal line-ups list as if they were
/// streams.
///
/// Many panels put entries like "##### ESPN PLUS #####" or "===== USA ====="
/// between their channel groups. They have a stream id and a URL, and that
/// URL plays the provider's static "thank you for being our loyal customers"
/// slide, which never stalls, so the player cannot tell it is not the
/// channel. Their names also contain the channel's keywords, so "Watch Live"
/// used to pick one. They are never a channel.
abstract final class StreamSeparator {
  /// The characters headings are drawn with.
  static final RegExp _decoration = RegExp(r'[#=\-*|~_+•●○■□▬═━★☆]');
  static final RegExp _alnum = RegExp(r'[\p{L}\p{N}]', unicode: true);
  static final RegExp _hashWrapped = RegExp(r'^#+.*#+$');
  static final RegExp _ruleStart = RegExp(r'^(?:-{3,}|={3,}|\*{3,}|_{3,})');

  static bool isSeparator(String name) {
    final text = name.trim();
    if (text.isEmpty) return false;
    if (_hashWrapped.hasMatch(text) || _ruleStart.hasMatch(text)) return true;
    // Mostly drawing characters: "▬▬ UK ▬▬", "**** 24/7 ****". A provider
    // tag such as "|UK| Sky Sports" or "ESPN+" has a few, not mostly.
    final decoration = _decoration.allMatches(text).length;
    final letters = _alnum.allMatches(text).length;
    return decoration >= 3 && decoration >= letters;
  }
}
