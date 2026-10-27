import 'video.dart';

/// The episodes of real seasons in order; season 0 is specials.
List<Video> episodeOrder(Iterable<Video> videos) =>
    videos.where((v) => (v.season ?? 0) > 0 && v.episode != null).toList()
      ..sort((a, b) {
        final s = a.season!.compareTo(b.season!);
        return s != 0 ? s : a.episode!.compareTo(b.episode!);
      });

/// The episode [step] places from season [season] episode [episode] in
/// [order] (`1` the next, `-1` the previous), across seasons. Null at either
/// end, or when the episode is not in the list.
Video? episodeNeighbour(
  List<Video> order,
  int? season,
  int? episode,
  int step,
) {
  final i = order.indexWhere((v) => v.season == season && v.episode == episode);
  if (i < 0) return null;
  final j = i + step;
  return j >= 0 && j < order.length ? order[j] : null;
}
