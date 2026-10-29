import '../../services/content/adult_guard.dart';
import '../../widgets/common/local_title_text.dart';
import '../../services/metadata/tmdb_catalog.dart';
import '../../services/continue_watching/continue_watching_service.dart';
import '../../services/metadata/title_kind_service.dart';
import '../../widgets/search/search_result_card.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n.dart';
import '../../models/addon/addon.dart';
import '../../models/movie/movie.dart';
import '../../models/movie/movie_section.dart';
import '../../models/stream/stream_model.dart';
import '../../services/addon/addon_manager.dart';
import '../../services/diagnostics/diagnostics_export.dart';
import '../../services/home/home_page_settings.dart';
import '../../services/metadata/metadata_service.dart';
import '../../services/layout/form_factor.dart';
import '../../services/platform/voice_search.dart';
import '../../services/playback/play_launcher.dart';
import '../../services/settings/locale_settings.dart';
import '../../shell/app_shell_scope.dart';
import '../../ui/lu_button.dart';
import '../../ui/lu_cards.dart';
import '../../ui/lu_focusable.dart';
import '../../ui/lu_theme.dart';
import '../../widgets/search/tv_on_screen_keyboard.dart';
import '../ai/wewatch_quiz_page.dart';
import '../player/player_screen.dart';

/// What a finished search should show.
enum SearchOutcome {
  /// Every source answered and none of them matched the query.
  noResults,

  /// Every source answered and at least one matched.
  complete,

  /// Some sources answered and some threw: the list is real but partial.
  incomplete,

  /// Nothing came back because sources threw. The catalog is not proven empty.
  failed,
}

/// What a finished search should show, given what came back and what threw.
/// Top level and pure so the three-way split is decided in exactly one place
/// and can be exercised without a widget tree, a network, or an addon install.
SearchOutcome classifySearchResult({
  required int resultCount,
  required int failureCount,
}) {
  if (failureCount == 0) {
    return resultCount == 0 ? SearchOutcome.noResults : SearchOutcome.complete;
  }
  return resultCount == 0 ? SearchOutcome.failed : SearchOutcome.incomplete;
}

/// Hand a voice transcript to the field: fill it, then run exactly that query.
///
/// A top-level function rather than a method on the page because the page's
/// search owns three network legs - addons, CloudStream and the title rail - so
/// a test that pressed the microphone would fire all three at the real
/// internet. This is the whole of what a transcript does to the page, and as a
/// plain function it can be proven without a widget tree: the controller is
/// written, the page is told the text changed, and the query is run, in that
/// order, the same order the clipboard paste already uses.
///
/// The transcript is nullable and emptiness returns early, because a `null`
/// result is a cancellation - the user backed out without speaking - and must
/// leave the field exactly as it was rather than clearing it. A recognizer that
/// heard silence also returns no text, and an empty query is not one to run.
@visibleForTesting
void applyVoiceTranscript(
  String? transcript, {
  required TextEditingController controller,
  required void Function(String) onChanged,
  required void Function(String) onSearch,
}) {
  final text = transcript?.trim() ?? '';
  if (text.isEmpty) return;
  controller.text = text;
  onChanged(text);
  onSearch(text);
}

/// Which legs of a search died, and how many sources the run expected to hear
/// back from. The page used to throw all of this away, so a dead addon, an
/// expired CloudStream runtime and being offline all rendered the same screen
/// as a title that does not exist. Search is the only route to a title the
/// user already has in mind, so that silence cost far more than the failure.
class SearchFailureLedger {
  /// Leg names in the order they threw, for the error copy.
  final List<String> sourceErrors = [];

  /// How many sources this run queried, the denominator in "X of Y".
  int searchedSourceCount = 0;

  int get failedSources => sourceErrors.length;

  /// Clearing the field abandons the query, so its failures must not survive
  /// into the next search and be blamed on the next title.
  void reset() {
    sourceErrors.clear();
    searchedSourceCount = 0;
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  /// The microphone's own focus node, for the copy of it that is a control in
  /// its own right.
  ///
  /// Named here rather than left to the [FocusableCard]'s private one because
  /// [_leaveField] has to be able to hand the ring to it: BACK out of the field
  /// lands on the control nearest it, which is this one.
  final FocusNode _micFocusNode = FocusNode(debugLabel: 'Search microphone');

  // The field's box card's own node, and the node this page publishes to the
  // shell's bar while Search is the slot on screen (`_publishChromeEntry`).
  final FocusNode _fieldNode = FocusNode(debugLabel: 'Search field box');

  /// The app's own keyboard, on a television only, and whether it is up.
  ///
  /// The platform's cannot be used: a focused `TextField` installs
  /// `DirectionalFocusAction.forTextField()`, which consumes every arrow press
  /// so the caret can move, and the IME it raised never sees them. Measured on
  /// the Google TV emulator - Gboard appears, and `DPAD_RIGHT`/`DPAD_CENTER` do
  /// nothing at all. `TvOnScreenKeyboard` edits the same controller instead, so
  /// the field, its text and [_onSearchChanged] are unchanged.
  final GlobalKey<TvOnScreenKeyboardState> _tvKeyboardKey =
      GlobalKey<TvOnScreenKeyboardState>();
  bool _tvKeyboardOpen = false;

  /// The shell this page is mounted inside, or null when it is mounted alone -
  /// which is what the widget tests that pump the page on its own, and a route
  /// pushed above the shell, both are. [AppShellScope.of] answers null rather
  /// than throwing for exactly this case.
  AppShellController? _shell;

  /// Gives up BACK while the keyboard is up, or null when it is not.
  ///
  /// See `AppShellController.claimBack`: the keyboard cannot keep the press to
  /// itself from a key handler, because Android's back reaches the shell on the
  /// `popRoute` path regardless. This is how the press is actually routed here.
  VoidCallback? _releaseBackClaim;

  /// What the shell's row handle held when this page took it, so the handle can
  /// be *given back* rather than emptied on the way out. See
  /// [_publishChromeEntry].
  FocusNode? _handedOver;

  Timer? _debounce;
  bool _isLoading = false;
  List<MovieSection> _results = [];

  /// TMDb's answer for each result id: animated or not, and its local name.
  /// A key with a null value was asked and not answered.
  final Map<String, TitleKindFacts?> _kindFacts = {};

  /// Which kind of result the tabs above the list show.
  _ResultFilter _filter = _ResultFilter.all;

  /// Every rail's titles as one list, each title once.
  ///
  /// The legs answer separately (Cinemeta, community addons, CloudStream, the
  /// keyless title lookup) and mostly answer with the same titles, so drawn as
  /// rails the page repeated each film once per source. Cinemeta's rail is
  /// first in [_results], so its row is the one that is kept.
  List<Movie> get _mergedResults {
    if (AdultGuard.adultQuery(_lastQuery)) return const [];
    final seen = <String>{};
    final merged = <Movie>[];
    for (final section in _results) {
      for (final movie in section.movies) {
        final key = movie.id.startsWith('tt')
            ? movie.id
            : '${movie.name.trim().toLowerCase()}|${movie.year ?? ''}|${movie.type}';
        if (seen.add(key)) merged.add(movie);
      }
    }
    // Adult titles are held back unless an admin asked for them.
    return AdultGuard.filter(
      merged,
      extraNames: (m) => [
        _kindFacts[m.id]?.localTitle,
        _kindFacts[m.id]?.originalTitle,
      ],
      flagged: (m) => _kindFacts[m.id]?.adult ?? false,
    );
  }

  SearchKind _kindOf(Movie movie) =>
      SearchKind.of(movie, _kindFacts[movie.id]?.isAnimation);

  /// Asks TMDb what each new result is, a few at a time, and redraws as the
  /// answers land. Results TMDb cannot place keep the addon's movie/series.
  Future<void> _classify(List<Movie> movies, String query) async {
    final language = l10nOf(context).localeName == 'zh' ? 'zh-CN' : 'en-US';
    final pending = movies
        .where((m) => m.id.startsWith('tt') && !_kindFacts.containsKey(m.id))
        .take(40)
        .toList();
    for (final m in pending) {
      _kindFacts[m.id] = null;
    }
    for (var i = 0; i < pending.length; i += 6) {
      final batch = pending.skip(i).take(6).toList();
      final answers = await Future.wait(
        batch.map(
          (m) => TitleKindService.forImdbId(
            m.id,
            type: m.type,
            language: language,
          ),
        ),
      );
      if (!mounted || _lastQuery != query) return;
      setState(() {
        for (var j = 0; j < batch.length; j++) {
          _kindFacts[batch[j].id] = answers[j];
        }
      });
    }
  }

  String _lastQuery = '';

  /// Synthetic catalog id for the keyless title rail. There is no addon
  /// catalog behind it, so its slider hides See All.
  static const String _titleRailCatalogId = 'imdb_titles';

  /// Each leg is one source the user believes is answering. The addon leg
  /// fans out internally, so a dead addon surfaces as one failure here.
  static const int _addonSearchSourceCount = 1;
  static const int _titleSearchSourceCount = 1;

  final SearchFailureLedger _ledger = SearchFailureLedger();

  bool _isMagnetMode = false;
  String _magnetQuery = '';

  /// The legs a run can hit, and so the denominator the user is shown. A leg
  /// with nothing to search (no CloudStream extension enabled) is not a source
  /// anyone expects an answer from, so it stays out of the count.
  static int _searchedSourceTotalFor({required String query}) {
    if (query.isEmpty) return 0;
    return _titleSearchSourceCount + _addonSearchSourceCount;
  }

  SearchOutcome get _outcome => classifySearchResult(
    resultCount: _results.length,
    failureCount: _ledger.failedSources,
  );

  void _recordSourceFailure(String source, Object error) {
    debugPrint('[SearchPage] $source search error: $error');
    // A leg that fails late must not resurrect a query the user has moved on
    // from, and setState after dispose throws.
    if (!mounted) return;
    setState(() {
      _ledger.sourceErrors.add(source);
    });
  }

  /// The service callbacks fire from code that knows nothing about the current
  /// query, so a failure arriving after the user has moved on would be blamed
  /// on the new title. Each leg gets a recorder pinned to its own query.
  void Function(String source, Object error) _sourceErrorRecorderFor(
    String query,
  ) {
    return (source, error) {
      if (!mounted || _lastQuery != query) return;
      _recordSourceFailure(source, error);
    };
  }

  List<String> _searchHistory = [];
  List<MovieSection> _suggestedSections = [];
  bool _isLoadingSuggestions = true;

  /// Whether the platform reported a recognizer, which is the only thing that
  /// puts a microphone beside the field. False until the answer arrives, so the
  /// field paints and accepts input before any channel round trip.
  bool _voiceAvailable = false;

  /// How far the body has scrolled, as 0..1 for the search band's tint.
  ///
  /// The band carries the field and nothing else, so at the top of the page it
  /// is transparent and the canvas shows through. Results scroll *under* it, so
  /// past a nudge it has to paint or a rail heading would draw across the field
  /// unreadably - the same failure Home's glass bar tints its way out of, and
  /// deliberately the same distance (`AppShell._navBlendThreshold`), so the
  /// shell's own bar and this one settle together.
  ///
  /// A value, not an animation, and it rebuilds the band's decoration only: the
  /// field inside is built once and handed to the [ValueListenableBuilder] as
  /// its `child`, so typing is never rebuilt by scrolling and nothing moves.
  static const double _bandBlendThreshold = 32.0;
  final ValueNotifier<double> _bandTint = ValueNotifier<double>(0);

  /// The body's own scroll feeds the band, because the band is inside the
  /// `appBar` slot and cannot listen to it from there.
  bool _onBodyScroll(ScrollNotification notification) {
    // Vertical only. The rails inside the results are horizontal scrollables
    // whose offset says nothing about how far the page has travelled under the
    // band - a rail nudged one poster to the right would otherwise drag the
    // band's tint to full as if the page had scrolled a whole screen.
    if (notification.metrics.axis != Axis.vertical) return false;
    final t = (notification.metrics.pixels / _bandBlendThreshold).clamp(
      0.0,
      1.0,
    );
    if ((_bandTint.value - t).abs() > 0.01) _bandTint.value = t;
    // Nobody else's business: the field is the only consumer.
    return false;
  }

  @override
  void initState() {
    super.initState();
    // The field's own node answers BACK and `escape`; see [_onFieldKeyEvent] for
    // why the handler has to live here rather than on a widget above the field.
    _focusNode.onKeyEvent = _onFieldKeyEvent;
    // **And on a television it is not a traversal candidate at all.** A focused
    // `EditableText` answers every arrow key itself - that is the trap this page
    // is named for - so a field the remote can walk *into* is a field it cannot
    // walk out of. What a television lands on is the control [_fieldBox] wraps
    // the field's box in, and the centre button on that control raises the
    // app's own keyboard ([_openTvKeyboard]) instead of focusing the field.
    _focusNode.skipTraversal = FormFactorService.hasRemoteInput;
    FocusManager.instance.addListener(_onFocusChanged);
    HardwareKeyboard.instance.addHandler(_onFieldKeyUp);
    _loadSearchHistory();
    _loadSuggestions();
    // The rows' headings ("热门 · 电影") are worded when they load, so a
    // language switch reloads them; the page stays mounted in the shell.
    LocaleSettings.locale.addListener(_loadSuggestions);
    // After the first frame, never before: the field must paint and take input
    // immediately, and a channel round trip on the frame that opens the page
    // would put the microphone's existence between the user and the keyboard.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _resolveVoiceAvailability(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Read here rather than in `initState`, where an inherited lookup is not yet
    // legal. The shell keeps one controller for its whole life; a rebuild that
    // replaces the scope hands over a new instance, and the listener is swapped
    // only when it actually differs.
    final shell = AppShellScope.of(context);
    if (identical(shell, _shell)) return;
    _shell?.current.removeListener(_onSlotChanged);
    _shell = shell;
    shell?.current.addListener(_onSlotChanged);
    _publishChromeEntry();
  }

  /// The page's own row, as the shell's bar sees it.
  ///
  /// The field's box, on a television, while Search is the slot being shown - and
  /// nothing else. A telephone or a desk window has its field focused by a
  /// pointer, where the bar has no business reaching; and a slot nobody is
  /// looking at has no row on screen, so it publishes nothing.
  FocusNode? get _chromeEntry =>
      FormFactorService.hasRemoteInput &&
          _shell?.current.value == ShellSlot.search &&
          _fieldNode.context != null &&
          _fieldNode.canRequestFocus
      ? _fieldNode
      : null;

  /// Hands the field's box to the shell's bar, and takes the handle back again.
  ///
  /// `AppShellController.pageTopChrome` is one field shared by every slot page
  /// with a row of its own, so two rules apply. It is only published while Search
  /// is the slot being shown ([_chromeEntry]), and when this page withdraws it
  /// hands back what it took ([_handedOver]) instead of clearing it: an emptied
  /// handle would take Home's calendar down with it until Home happened to
  /// rebuild.
  void _publishChromeEntry() {
    final shell = _shell;
    if (shell == null) return;
    final entry = _chromeEntry;
    if (entry == null) {
      _handBackChromeEntry();
      return;
    }
    if (identical(shell.pageTopChrome, entry)) return;
    _handedOver = shell.pageTopChrome;
    shell.pageTopChrome = entry;
  }

  /// Gives the handle back to whatever held it before this page took it.
  ///
  /// Only if the handle is still ours to give back: another slot page may have
  /// published over it in the meantime, and that claim is not this page's to
  /// revoke. Deliberately not routed through [_chromeEntry] - the caller may be
  /// `dispose`, where the box's node is on its way out and the answer is only
  /// ever "give it back".
  void _handBackChromeEntry() {
    final shell = _shell;
    final previous = _handedOver;
    _handedOver = null;
    if (shell == null || previous == null) return;
    if (identical(shell.pageTopChrome, _fieldNode)) {
      shell.pageTopChrome = previous;
    }
  }

  /// The slot changed, so whether this page owns the bar's row handle may have.
  ///
  /// Read **after the frame and not during it**, because a slot change is
  /// notified before the shell repaints (`_AppShellState._select` says so
  /// explicitly): at this instant the page is still a hidden slot, its box is
  /// still inside an `ExcludeFocus`, and the answer would be "nothing to
  /// publish" - which is how this first went wrong on a device.
  void _onSlotChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _publishChromeEntry();
    });
  }

  /// Re-states this page's claim on the bar's row handle whenever focus moves.
  ///
  /// `pageTopChrome` is one field and `HomePage` writes it on every one of its
  /// own rebuilds, without asking which slot is on screen - so a claim made once
  /// at a slot change is a claim Home can take straight back, which is exactly
  /// what a device did. A remote reaches a bar row by moving focus, so re-stating
  /// the claim on every focus change means it is this page's again by the time
  /// the next key (the DOWN the bar hands over) is pressed. The early return in
  /// [_publishChromeEntry] makes the common case one identity check.
  void _onFocusChanged() {
    final shell = _shell;
    if (shell == null) return;
    if (shell.current.value != ShellSlot.search) return;
    _publishChromeEntry();
  }

  /// Eats the key-*up* half of a BACK this page's field already answered.
  ///
  /// The field's own handler cannot see it: answering a BACK moves the caret out
  /// of the field ([_leaveField]), so by the time the key comes back up the
  /// field's node is no longer in the focus path. An unhandled up is
  /// re-dispatched to Android, where BACK is the shell's (`shell_back_guard.dart`)
  /// - which is how the press that stepped out of the field also left Search.
  ///
  /// Only the up, and only while this page's slot is the one on screen: a BACK
  /// pressed anywhere else keeps exactly the meaning it had, and the down half is
  /// left to the field so that an ordinary BACK still reaches the shell once the
  /// field has let go.
  bool _onFieldKeyUp(KeyEvent event) {
    if (event is! KeyUpEvent) return false;
    if (!FormFactorService.hasRemoteInput) return false;
    if (event.logicalKey != LogicalKeyboardKey.escape &&
        event.logicalKey != LogicalKeyboardKey.goBack) {
      return false;
    }
    if (_shell?.current.value != ShellSlot.search) return false;
    // **And it is the press, when the caret is still in the field.** The platform
    // keyboard takes the key-down for itself while it is showing, so the up is
    // the only half of the press this page ever hears - and a press that closes
    // the keyboard and then leaves the caret where it was would still be the trap.
    //
    // `_focusNode`, not `_fieldNode`: `hasFocus` answers true for the node *or
    // any descendant*, and the box card contains the field. The box is also
    // where the ring sits after the app's own keyboard closes, and a BACK that
    // closed a keyboard must not go on to move the ring somewhere else.
    if (_focusNode.hasFocus) _leaveField();
    return true;
  }

  /// Ask the platform once whether it has a recognizer, and let the answer
  /// decide whether a microphone exists at all.
  ///
  /// A control that exists and fails is worse than no control: on a television
  /// the user cannot tell a missing recognizer from a broken app, so there is
  /// nothing to show them.
  Future<void> _resolveVoiceAvailability() async {
    final available = await VoiceSearch.available();
    if (!mounted) return;
    setState(() => _voiceAvailable = available);
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('search_history') ?? [];
    if (mounted) {
      setState(() {
        _searchHistory = history;
      });
    }
  }

  Future<void> _saveSearchHistory(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('search_history') ?? [];
    history.remove(query);
    history.insert(0, query);
    if (history.length > 10) history.removeLast();
    await prefs.setStringList('search_history', history);
    if (mounted) {
      setState(() {
        _searchHistory = history;
      });
    }
  }

  Future<void> _removeSearchHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('search_history') ?? [];
    history.remove(query);
    await prefs.setStringList('search_history', history);
    if (mounted) {
      setState(() {
        _searchHistory = history;
      });
    }
  }

  Future<void> _clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
    if (mounted) {
      setState(() {
        _searchHistory = [];
      });
    }
  }

  Future<void> _loadSuggestions() async {
    try {
      final sections = await AddonManager.instance.fetchAllHomeSections();
      if (mounted) {
        setState(() {
          _suggestedSections = sections
              .map(AdultGuard.filterSection)
              .where((s) => s.movies.isNotEmpty)
              .take(4)
              .toList();
          _isLoadingSuggestions = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingSuggestions = false;
        });
      }
    }
  }

  static bool _isMagnetLink(String text) {
    final trimmed = text.trim();
    if (trimmed.toLowerCase().startsWith('magnet:')) return true;
    if (RegExp(r'^[0-9a-fA-F]{40}$').hasMatch(trimmed)) return true;
    if (RegExp(r'^[a-zA-Z2-7]{32}$').hasMatch(trimmed)) return true;
    return false;
  }

  static bool _isStreamLink(String text) {
    final trimmed = text.trim();
    final lower = trimmed.toLowerCase();
    if (!lower.startsWith('http://') && !lower.startsWith('https://')) {
      return false;
    }
    return true;
  }

  void _playDirectStream(String url) {
    final trimmed = url.trim();
    final uri = Uri.tryParse(trimmed);
    final directStream = l10nOf(context).searchDirectStream;
    String title = directStream;
    if (uri != null && uri.pathSegments.isNotEmpty) {
      final last = uri.pathSegments.last;
      if (last.isNotEmpty) {
        title = Uri.decodeComponent(last);
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          source: StreamSource(
            name: directStream,
            title: title,
            url: trimmed,
            addonName: directStream,
          ),
          title: title,
        ),
      ),
    );
  }

  @override
  void dispose() {
    LocaleSettings.locale.removeListener(_loadSuggestions);
    HardwareKeyboard.instance.removeHandler(_onFieldKeyUp);
    FocusManager.instance.removeListener(_onFocusChanged);
    _shell?.current.removeListener(_onSlotChanged);
    // Before the box's node goes anywhere: the shell's bar reads this handle at
    // key time, and a node this page is dismantling is not one it may hand the
    // remote to.
    _handBackChromeEntry();
    // A claim that outlived this page would eat the press that leaves the app.
    _releaseBackClaim?.call();
    _releaseBackClaim = null;
    _shell = null;
    _fieldNode.dispose();
    _micFocusNode.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    _bandTint.dispose();
    super.dispose();
  }

  /// The field's length at the previous change, to tell a paste from typing.
  int _previousLength = 0;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _previousLength = 0;
      setState(() {
        _results.clear();
        _isLoading = false;
        _lastQuery = '';
        _isMagnetMode = false;
        _magnetQuery = '';
        // Clearing the field abandons the query, so its failures must not
        // survive to be shown against the next one.
        _ledger.reset();
      });
      return;
    }

    // A link opens at once only when it arrived whole - pasted, or dropped
    // in by the paste button. Typed a letter at a time it would open at
    // "https://d"; then it waits for Enter, which [_performSearch] handles.
    final arrivedWhole = trimmed.length - _previousLength >= 8;
    _previousLength = trimmed.length;
    if (_isStreamLink(trimmed)) {
      if (arrivedWhole) _playDirectStream(trimmed);
      return;
    }

    if (_isMagnetLink(trimmed)) {
      setState(() {
        _isMagnetMode = true;
        _magnetQuery = trimmed;
        _isLoading = false;
        _results.clear();
        // Abandons the text search, so its late sections are dropped.
        _lastQuery = '';
      });
      return;
    } else if (_isMagnetMode) {
      setState(() {
        _isMagnetMode = false;
        _magnetQuery = '';
      });
    }

    _debounce = Timer(const Duration(milliseconds: 600), () {
      if (trimmed != _lastQuery) {
        // Typing searches, but only a search the viewer meant - Enter, a
        // result opened, a hot or recent search tapped - is remembered:
        // "hen", "hent", "henta" are not searches anybody made.
        _performSearch(trimmed, remember: false);
      }
    });
  }

  void _performSearch(String query, {bool remember = true}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    // Enter on what typing already searched: keep the results, remember it.
    if (remember && trimmed == _lastQuery && _results.isNotEmpty) {
      _saveSearchHistory(trimmed);
      return;
    }

    if (_isStreamLink(trimmed)) {
      _playDirectStream(trimmed);
      return;
    }

    if (_isMagnetLink(trimmed)) {
      setState(() {
        _isMagnetMode = true;
        _magnetQuery = trimmed;
        _isLoading = false;
        _results.clear();
        // Abandons the text search, so its late sections are dropped.
        _lastQuery = '';
      });
      return;
    }

    if (remember) _saveSearchHistory(trimmed);

    setState(() {
      _isLoading = true;
      _lastQuery = trimmed;
      _isMagnetMode = false;
      _results = [];
      _filter = _ResultFilter.all;
      // Failures belong to the query that produced them; carrying them into
      // the next search would blame the new query for the old outage.
      _ledger.reset();
      _ledger.searchedSourceCount = _searchedSourceTotalFor(query: trimmed);
    });

    final currentQuery = trimmed;
    final l10n = l10nOf(context);
    // A leg that fails after the viewer moved on blames this query, not the
    // one now on screen.
    final recordFailure = _sourceErrorRecorderFor(currentQuery);

    void addSection(MovieSection section, {bool first = false}) {
      if (!mounted || _lastQuery != currentQuery) return;
      if (section.movies.isEmpty) return;

      // Prevent duplicate sections
      final exists = _results.any(
        (s) =>
            s.title == section.title &&
            s.subtitle == section.subtitle &&
            s.addonBaseUrl == section.addonBaseUrl,
      );
      if (exists) return;

      setState(() {
        if (first) {
          _results.insert(0, section);
        } else if ((section.addonBaseUrl.contains('cinemeta') ||
            section.subtitle.toLowerCase().contains('cinemeta'))) {
          // Prioritize Cinemeta at the top
          _results.insert(0, section);
        } else {
          _results.add(section);
        }
      });
      _classify(section.movies, currentQuery);
    }

    try {
      // 1. Search Stremio Addons with dynamic streaming
      final addonSearch = AddonManager.instance
          .searchAll(
            currentQuery,
            onSectionResult: (section) {
              addSection(section);
            },
            onSourceError: _sourceErrorRecorderFor(currentQuery),
          )
          .catchError((e) {
            recordFailure('Addons', e);
            return <MovieSection>[];
          });

      // 3. Keyless title lookup. An install whose only installed addon is
      // Cinemeta has no search catalog left, so without this the page would
      // report no results for every query.
      final titleSearch =
          MetadataService.suggestionSearch(
                query: currentQuery,
                onSourceError: _sourceErrorRecorderFor(currentQuery),
              )
              .then((movies) {
                addSection(
                  MovieSection(
                    title: l10n.searchTitlesSection,
                    subtitle: l10n.searchImdbSuggestions,
                    contentType: 'movie',
                    addonBaseUrl: 'https://v3-cinemeta.strem.io',
                    catalog: AddonCatalog(
                      type: 'movie',
                      id: _titleRailCatalogId,
                      name: 'Titles',
                    ),
                    movies: movies,
                  ),
                );
              })
              .catchError((e) {
                recordFailure(l10n.searchSourceTitleLookup, e);
              });

      // 4. TMDb in Chinese, for a query typed in Chinese: the addons know
      // titles by their English names, so 庆余年 found next to nothing there.
      // Its rail goes first, and its IMDb ids let the merge drop the same
      // titles from the other rails.
      final tmdbSearch = _hasCjk(currentQuery)
          ? TmdbCatalog.row(
                  TmdbQuery('/search/multi', {
                    'query': currentQuery,
                    'include_adult': 'false',
                  }),
                )
                .then((movies) {
                  addSection(
                    MovieSection(
                      title: l10n.searchTitlesSection,
                      subtitle: 'TMDb',
                      contentType: 'movie',
                      addonBaseUrl: 'https://v3-cinemeta.strem.io',
                      catalog: AddonCatalog(type: 'movie', id: 'tmdb_search'),
                      movies: movies,
                    ),
                    first: true,
                  );
                })
                .catchError((e) {
                  recordFailure('TMDb', e);
                })
          : Future<void>.value();

      await Future.wait([addonSearch, titleSearch, tmdbSearch]);
    } catch (e) {
      // A leg that throws synchronously, or a Future.wait rejection that
      // outran the handlers above, is still a source that did not answer.
      recordFailure('Search', e);
    }

    if (mounted && _lastQuery == currentQuery) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Whether [text] holds Chinese, Japanese or Korean characters.
  static bool _hasCjk(String text) => RegExp('[぀-ヿ㐀-鿿가-힯]').hasMatch(text);

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      _searchController.text = text;
      _onSearchChanged(text);
      if (!_isMagnetLink(text) && !_isStreamLink(text)) {
        _performSearch(text);
      }
    }
  }

  /// Hand the query to the platform's recognizer and put its answer in the
  /// field.
  ///
  /// The three outcomes are all different. A transcript runs the search like the
  /// clipboard paste does. A `null` is the user backing out without speaking,
  /// and touches nothing. A refusal is either `denied` - show the user something,
  /// because the microphone is fine and the permission is not - or `unavailable`
  /// - the recognizer went away, so stop offering the control rather than let the
  /// user press it into another failure.
  Future<void> _startVoiceSearch() async {
    final String? transcript;
    try {
      transcript = await VoiceSearch.listen();
    } on PlatformException catch (e) {
      if (!mounted) return;
      switch (e.code) {
        case 'denied':
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10nOf(context).searchVoiceDenied),
              behavior: SnackBarBehavior.floating,
              backgroundColor: LuColors.danger,
            ),
          );
        case 'unavailable':
          setState(() => _voiceAvailable = false);
        default:
          // `busy`, or a code this build does not know: the platform refused
          // one attempt, not the feature, so nothing is said and the control
          // stays where it is.
          break;
      }
      return;
    } catch (e) {
      debugPrint('[SearchPage] voice search failed: $e');
      return;
    }

    applyVoiceTranscript(
      transcript,
      controller: _searchController,
      onChanged: _onSearchChanged,
      // Mirrors the clipboard path: `_onSearchChanged` opens a link itself when
      // the transcript happens to be one, so the search must not open it twice.
      onSearch: (text) {
        if (!_isMagnetLink(text) && !_isStreamLink(text)) {
          _performSearch(text);
        }
      },
    );
  }

  /// The field's box, wrapped in the control a television can actually land on -
  /// and the node the shell's bar hands DOWN into.
  ///
  /// **Why the box needs a control of its own.** A focused `EditableText` answers
  /// every arrow key itself (`DirectionalFocusAction.forTextField()`), so a field
  /// the remote can walk *into* is a field it cannot walk out of: the arrows that
  /// should leave it move a caret through empty text instead. So on a television
  /// [_focusNode] is not a traversal candidate at all (`skipTraversal`, set in
  /// `initState`) and this card is: an ordinary [FocusableCard] wearing the house
  /// [CardFocusRing], whose centre button hands the field focus and, with it, the
  /// platform keyboard - which is how a remote starts typing.
  ///
  /// **And why the shell's bar needs it.** DOWN out of the bar is answered by the
  /// shell's own hand-over (`_TopChromeHandover` -> `_handOverDownToPage`) and by
  /// nothing else: measured in `test/tv_dpad_regression_test.dart`, where the
  /// remote stands on the bar's own Search row, an arrow key moves no focus at all
  /// - the only move that happens is the one the hand-over makes. That is why Home
  /// publishes its calendar glyph (`AppShellController.pageTopChrome`) and why
  /// this page publishes its box: without it, DOWN out of the bar leaves the
  /// remote where it was and no arrow ever reaches the band.
  ///
  /// **The focus boundary around the card is the shell's doing, not this page's.**
  /// `SkipPageShellFocus` marks every node inside a page whose *focus* parent is
  /// not, and which has a focus descendant inside the page, as untraversable
  /// **and unfocusable** (`SkipPageShellFocus._findPageNodes`) - right for the one
  /// node that covers a whole page, wrong for a card that wraps another control.
  /// Measured, not guessed: without the boundary the card came out with
  /// `canRequestFocus == false`, so nothing could land on it. It costs nothing -
  /// no key handling, no focus of its own, no traversal slot, no layout.
  ///
  /// A pointer device keeps the field exactly as it was, autofocus and all, and
  /// gets no card: a mouse focuses a text field by pointing at it.
  Widget _fieldBox({required bool isTelevision, required Widget child}) {
    if (!isTelevision) return child;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      child: LuFocusable(
        focusNode: _fieldNode,
        // The centre button on the box is "start typing". On a television that
        // is the app's own keyboard, never the platform's: a focused field
        // raises an IME the remote cannot drive at all (see
        // [TvOnScreenKeyboard]), so the field itself is never focused here.
        onTap: _openTvKeyboard,
        lift: 1,
        builder: (context, _) => child,
      ),
    );
  }

  /// Raises the app's keyboard and keeps the platform's away.
  ///
  /// The platform call is not redundant with the field never taking focus: a
  /// physical keyboard, a voice remote's text path or a stray `TextInput.show`
  /// from the framework can leave the IME up, and an IME drawn over the app's
  /// keyboard is the exact overlap that made the field look usable and be
  /// unusable.
  void _openTvKeyboard() {
    if (_tvKeyboardOpen) return;
    setState(() => _tvKeyboardOpen = true);
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    // BACK now belongs to the keyboard until it closes. Registered here rather
    // than in the widget because the page owns what "closed" restores: the ring
    // goes back to the field's box, not to wherever the shell would put it.
    _releaseBackClaim = _shell?.claimBack(_closeTvKeyboard);
  }

  /// Closes the keyboard and puts the remote back on the field's box.
  ///
  /// [moveToResults] is DOWN off the action row: the ring steps out of the
  /// band and into whatever is below it, which is the same walk
  /// [_leaveField] makes for BACK.
  void _closeTvKeyboard({bool moveToResults = false}) {
    if (!_tvKeyboardOpen) return;
    // Released before the frame that removes the keyboard: from here on the
    // next back press is the shell's again, and a claim left registered would
    // eat the press that returns to the bar.
    _releaseBackClaim?.call();
    _releaseBackClaim = null;
    setState(() => _tvKeyboardOpen = false);
    // After the frame that removes it: a node whose control has gone cannot be
    // asked for focus, and the box under it is only the neighbour once the
    // keyboard's own nodes are out of the traversal graph.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_fieldNode.context == null || !_fieldNode.canRequestFocus) return;
      _fieldNode.requestFocus();
      if (moveToResults) {
        _fieldNode.focusInDirection(TraversalDirection.down);
      }
    });
  }

  /// The microphone, in both of the places it lives.
  ///
  /// One definition, two homes. On a pointer device it is the field's trailing
  /// suffix icon, which is where a mouse looks for it and where nothing beside it
  /// re-flows. On a television it is a control of the band's own row
  /// ([standalone]), because a suffix lives inside the field's subtree and a
  /// focused `EditableText` answers every arrow key itself - a remote cannot land
  /// in a suffix at all, which is the defect this change exists for.
  ///
  /// Either way it is a [FocusableCard] wearing [CardFocusRing] - the house
  /// treatment for anything a remote can land on, since a bare `IconButton` is
  /// pointer-only and would be the one focusable in the app without a ring - and
  /// either way it runs [_startVoiceSearch].
  ///
  /// **The band's copy needs the same focus boundary as the field's box**, and
  /// for the same reason: `SkipPageShellFocus` defuses a node that sits at the
  /// top of a page and has a focus descendant, and the microphone is one. Left
  /// alone it is made unfocusable a frame after anything focuses it - measured on
  /// the device: BACK moved the ring onto the microphone and the ring then jumped
  /// to the bar on its own, because the node it had landed on stopped accepting
  /// focus.
  Widget _buildMicrophone({bool standalone = false}) {
    final Widget icon = Padding(
      padding: const EdgeInsets.all(8),
      child: Semantics(
        button: true,
        label: l10nOf(context).searchVoice,
        child: const Icon(
          Icons.mic_rounded,
          size: 20,
          color: LuColors.textSoft,
        ),
      ),
    );
    final Widget card = LuFocusable(
      // Named for the band's copy only: [_leaveField] hands BACK's ring to it,
      // and a node nobody can name cannot be handed anything.
      focusNode: standalone ? _micFocusNode : null,
      onTap: _startVoiceSearch,
      lift: 1,
      // The band's copy stands beside the field, so it is held to the field's
      // height and to the 48 dp width floor a television control is held to;
      // the suffix copy is sized by its own padding.
      builder: (context, _) => standalone
          ? SizedBox(width: 56, height: 56, child: Center(child: icon))
          : icon,
    );
    if (!standalone) return card;
    return Focus(canRequestFocus: false, skipTraversal: true, child: card);
  }

  /// Answers BACK and `escape` while the field holds focus: the way out of the
  /// one-way trap.
  ///
  /// **Why it hangs off the field's own node.** Key handling walks the focus
  /// chain from the primary node *upwards*, calling each node's `onKeyEvent`
  /// (`FocusManager._handleKeyMessage`), so the field's own node is the only
  /// place that runs before `Shortcuts` can turn a press into an `Intent`. That
  /// matters for exactly one of these two keys. The remote's BACK arrives as
  /// `goBack`, which nothing claims; a keyboard's escape arrives as `escape`,
  /// which `WidgetsApp` binds to [DismissIntent] - and a focused `EditableText`
  /// installs `DismissIntent: CallbackAction(_hideToolbarIfVisible)` in its own
  /// `Actions` map (`editable_text.dart`). `Actions.maybeFind` walks up from the
  /// primary focus, so that entry is found before anything this page could
  /// mount, it is enabled whether or not a toolbar is showing, and
  /// `Action.consumesKey` answers true: the press is eaten by a field with
  /// nothing to dismiss, and no ancestor `Actions` or `Focus` handler ever sees
  /// it. A handler on the field's own node is not above that mechanism - it is
  /// *before* it.
  ///
  /// **It stands down for everything else.** Only these two keys are looked at,
  /// and only on a remote-driven device: characters, the arrows, Tab and the
  /// centre button are all returned [KeyEventResult.ignored], untouched, so
  /// nothing here competes with the platform IME. The handler is also only ever
  /// called while the field is in the focus path, which is the condition
  /// `home_page.dart`'s page-level handler tests for with `is EditableText` -
  /// here it is true by construction instead of checked.
  KeyEventResult _onFieldKeyEvent(FocusNode node, KeyEvent event) {
    if (!FormFactorService.hasRemoteInput) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.escape &&
        event.logicalKey != LogicalKeyboardKey.goBack) {
      return KeyEventResult.ignored;
    }
    // **Both halves of the press**, and the key-up is not a formality. The
    // platform keyboard on a television takes the key-*down* for itself while it
    // is showing - measured on the emulator: with the IME up no key event reaches
    // Flutter at all and the keyboard simply closes - so the up is the first
    // thing this page hears about the press. And an unhandled up is re-dispatched
    // to Android, where a BACK the shell sees is a BACK that leaves Search rather
    // than stepping out of the field.
    _leaveField();
    return KeyEventResult.handled;
  }

  /// Closes the platform keyboard and moves the remote off the field.
  ///
  /// Both halves are needed, and neither implies the other. The keyboard belongs
  /// to the platform, so hiding it is a platform call - `TextInput.hide` is the
  /// one text-input method documented as valid at any time
  /// (`SystemChannels.textInput`) - while the trap is a focus trap, so the field
  /// also has to stop being the focused thing, or the user is back inside it the
  /// moment the keyboard returns.
  void _leaveField() {
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    // The band's own row first: the microphone is the control beside the field,
    // and landing there keeps the remote on the page's own row. Asked for rather
    // than assumed: a node that cannot take focus would swallow the request and
    // leave the ring where it was, which reads as "BACK did nothing".
    if (_micFocusNode.context != null && _micFocusNode.canRequestFocus) {
      _micFocusNode.requestFocus();
      return;
    }
    // No recognizer, so the band has nothing to hand the ring to: it goes to the
    // first control *below* the band - the results, the recent searches or the
    // suggested rails, whichever this page is showing - by asking the traversal
    // policy the same question an arrow key asks.
    if (!_focusNode.focusInDirection(TraversalDirection.down)) {
      // Nothing below either - a page with no results, no history and no
      // suggestions yet. The ring then goes back the way the remote came in
      // (the shell's bar row) rather than nowhere at all: an escape that leaves
      // no marker anywhere is indistinguishable from a key that did nothing.
      _focusNode.unfocus(
        disposition: UnfocusDisposition.previouslyFocusedChild,
      );
    }
  }

  /// The page's side gutter: the shell bar's, so the field lines up under the
  /// brand.
  double _side(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) return 16;
    return FormFactorService.of(context) == FormFactor.television ? 32 : 48;
  }

  /// The band's height under the shell's own inset: the 56 dp field and its
  /// breathing room.
  static const double _bandHeight = 76;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isTelevision = FormFactorService.of(context) == FormFactor.television;
    final side = _side(context);

    // The bar's row handle is re-stated after every frame: a node whose
    // control has gone has no context, and publishing it would hand the shell
    // a node it cannot ask for a rect.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _publishChromeEntry();
    });

    // The field, as designed: one long rounded bar, gold-edged while typing.
    // It is a plain [PreferredSize] band rather than an `AppBar`, whose
    // toolbar is excluded from directional traversal - a field there is one a
    // remote can see and never reach.
    final field = ListenableBuilder(
      listenable: Listenable.merge([_focusNode, _fieldNode]),
      builder: (context, child) => AnimatedContainer(
        duration: LuMotion.focus,
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF17171B),
          borderRadius: LuRadius.pill,
          border: Border.all(
            color: _focusNode.hasFocus || _fieldNode.hasFocus
                ? LuColors.gold
                : LuColors.line,
          ),
        ),
        child: child,
      ),
      child: Center(
        child: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          // Never on a television: a focused text field keeps every arrow
          // key for its caret, so a field that takes focus on arrival is a
          // trap the remote cannot leave. The remote types through the card
          // [_fieldBox] puts around this box instead.
          autofocus: !isTelevision,
          // No IME suggestion strip on a television: it re-flows the app's
          // own key grid under the D-pad.
          enableSuggestions: !isTelevision,
          autocorrect: !isTelevision,
          style: LuText.body.copyWith(fontSize: 18),
          cursorColor: LuColors.gold,
          textInputAction: TextInputAction.search,
          onChanged: _onSearchChanged,
          onSubmitted: _performSearch,
          decoration: InputDecoration(
            isCollapsed: true,
            filled: false,
            // "or paste links" is advice for a keyboard; a remote has no
            // clipboard.
            hintText: DeviceProfile.isTelevision
                ? l10nOf(context).searchHintTv
                : l10nOf(context).searchHint,
            hintStyle: LuText.body.copyWith(
              fontSize: 17,
              color: LuColors.textFaint,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 20, right: 12),
              child: Icon(
                Icons.search_rounded,
                size: 22,
                color: LuColors.textMuted,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minHeight: 56),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            suffixIconConstraints: const BoxConstraints(minHeight: 56),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // On a pointer device the microphone lives in the field; on
                  // a television it is the band's own control (below), since
                  // a remote can never land inside the field's subtree.
                  if (_voiceAvailable && !isTelevision) _buildMicrophone(),
                  if (_searchController.text.isNotEmpty)
                    _SuffixButton(
                      icon: Icons.close_rounded,
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).deleteButtonTooltip,
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  else ...[
                    ValueListenableBuilder<bool>(
                      valueListenable: HomePageSettings.enableAiQuiz,
                      builder: (context, aiQuizEnabled, _) => aiQuizEnabled
                          ? _SuffixButton(
                              icon: Icons.auto_awesome_rounded,
                              tooltip: l10nOf(context).searchAiQuiz,
                              color: LuColors.gold,
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const WeWatchQuizPage(),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    _SuffixButton(
                      icon: Icons.content_paste_rounded,
                      tooltip: l10nOf(context).searchPaste,
                      onPressed: _pasteFromClipboard,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Theme(
      data: luTheme(),
      child: Scaffold(
        backgroundColor: LuColors.bg,
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(_bandHeight),
          // Clear at rest, the ground fading in once results scroll under it.
          child: ValueListenableBuilder<double>(
            valueListenable: _bandTint,
            builder: (context, tint, child) => DecoratedBox(
              decoration: BoxDecoration(
                color: LuColors.bg.withValues(alpha: 0.94 * tint),
              ),
              child: child,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(side, topPadding + 8, side, 12),
              child: Row(
                children: [
                  // Search is a shell slot and usually has nothing to pop to;
                  // a pushed SearchPage still gets its back.
                  if (Navigator.of(context).canPop()) ...[
                    _SuffixButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 960),
                        child: _fieldBox(
                          isTelevision: isTelevision,
                          child: field,
                        ),
                      ),
                    ),
                  ),
                  if (isTelevision && _voiceAvailable) ...[
                    const SizedBox(width: 8),
                    _buildMicrophone(standalone: true),
                  ],
                ],
              ),
            ),
          ),
        ),
        body: NotificationListener<ScrollNotification>(
          onNotification: _onBodyScroll,
          child: Stack(
            children: [
              if (_isMagnetMode && _magnetQuery.isNotEmpty)
                Center(
                  child: Text(l10nOf(context).detailsSourceNoLongerSupported),
                )
              else if (_isLoading && _results.isEmpty)
                const Center(
                  child: CircularProgressIndicator(color: LuColors.gold),
                )
              else if (!_isLoading && _lastQuery.isNotEmpty && _results.isEmpty)
                _buildSearchEmptyState(_outcome)
              else if (_results.isNotEmpty)
                Column(
                  children: [
                    if (_outcome == SearchOutcome.incomplete)
                      _buildFailureLedger(topPadding),
                    Expanded(child: _buildResults(topPadding)),
                  ],
                )
              else
                _buildDiscoveryEmptyState(topPadding),

              if (_isLoading && _results.isNotEmpty)
                Positioned(
                  top: topPadding + _bandHeight,
                  left: 0,
                  right: 0,
                  child: const SizedBox(
                    height: 2,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      color: LuColors.gold,
                    ),
                  ),
                ),

              // The remote's keyboard, under the field it edits. Hung off the
              // body: inside the fixed-height band it would be clipped.
              if (isTelevision && _tvKeyboardOpen)
                Positioned(
                  top: topPadding + _bandHeight + 8,
                  left: side,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 540),
                    child: TvOnScreenKeyboard(
                      key: _tvKeyboardKey,
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      onSubmitted: _performSearch,
                      onClose: _closeTvKeyboard,
                      // UP off the top row is the same hand-off as BACK.
                      onMoveUp: _closeTvKeyboard,
                      onMoveDown: () => _closeTvKeyboard(moveToResults: true),
                      // Inside the shell BACK is claimed there; without one
                      // the key event is the only notice.
                      ownsBackKey: _shell == null,
                      onVoice: _voiceAvailable ? _startVoiceSearch : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Puts the redacted diagnostic report on the clipboard from the all-sources
  /// failed screen.
  ///
  /// This is the surface where "no source answered" is indistinguishable from a
  /// broken addon list, an expired provider runtime or a network change, and
  /// the report is what tells those apart. It is local-only; nothing is sent.
  Future<void> _copyDiagnosticReport() async {
    try {
      final text = await DiagnosticsExport.instance.copyText();
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(l10nOf(context).diagnosticsCopiedToClipboard)),
      );
    } catch (error) {
      debugPrint('[SearchPage] could not copy diagnostics: $error');
    }
  }

  /// The results: kind tabs, then one card per title in as many columns as
  /// the width takes, with the popular searches beside them on a wide screen.
  Widget _buildResults(double topPadding) {
    final l10n = l10nOf(context);
    final all = _mergedResults;
    final kinds = {for (final m in all) m.id: _kindOf(m)};
    bool matches(Movie m, _ResultFilter f) {
      final k = kinds[m.id]!;
      return switch (f) {
        _ResultFilter.all => true,
        _ResultFilter.anime => k.isAnimation,
        _ResultFilter.series => !k.isAnimation && k.isSeries,
        _ResultFilter.movies => !k.isAnimation && !k.isSeries,
      };
    }

    final shown = all.where((m) => matches(m, _filter)).toList();
    final counts = {
      for (final f in _ResultFilter.values)
        f: all.where((m) => matches(m, f)).length,
    };
    final sessions = {
      for (final item in ContinueWatchingService.activeItems.value)
        if (!item.isCompleted) item.id: item,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = width < 600;
        final side = _side(context);
        final hot = _hotSearches();
        final showHot = width >= 1100 && hot.isNotEmpty;
        final listWidth = width - side * 2 - (showHot ? 320 + 40 : 0);
        final columns = compact ? 1 : (listWidth / 440).floor().clamp(1, 3);
        final cardHeight = SearchResultCard.heightFor(compact: compact);

        final rows = <Widget>[];
        for (var i = 0; i < shown.length; i += columns) {
          final cells = <Widget>[];
          for (var c = 0; c < columns; c++) {
            if (c > 0) cells.add(const SizedBox(width: 20));
            final index = i + c;
            cells.add(
              Expanded(
                child: index < shown.length
                    ? SearchResultCard(
                        key: ValueKey(shown[index].id),
                        movie: shown[index],
                        kind: kinds[shown[index].id]!,
                        localTitle: _kindFacts[shown[index].id]?.localTitle,
                        posterUrl: _kindFacts[shown[index].id]?.posterUrl,
                        resume: sessions[shown[index].id],
                        compact: compact,
                        // Opening a result is what makes a typed search one
                        // worth remembering.
                        onOpen: () => _saveSearchHistory(_lastQuery),
                      )
                    : const SizedBox.shrink(),
              ),
            );
          }
          rows.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: SizedBox(
                height: cardHeight,
                child: Row(children: cells),
              ),
            ),
          );
        }

        final list = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  for (final f in _ResultFilter.values) ...[
                    _buildFilterChip(f, counts[f]!),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),
            if (shown.isEmpty && !_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(l10n.searchFilterEmpty, style: LuText.bodySoft),
              ),
            ...rows,
            if (_isLoading) _buildSearchingMore(),
          ],
        );

        return SingleChildScrollView(
          clipBehavior: Clip.none,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            side,
            topPadding + _bandHeight + 12,
            side,
            40 + MediaQuery.paddingOf(context).bottom,
          ),
          child: showHot
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: list),
                    const SizedBox(width: 40),
                    SizedBox(
                      width: 320,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: _buildHotSearches(hot),
                      ),
                    ),
                  ],
                )
              : list,
        );
      },
    );
  }

  Widget _buildFilterChip(_ResultFilter filter, int count) {
    final l10n = l10nOf(context);
    final label = switch (filter) {
      _ResultFilter.all => l10n.searchFilterAll(count),
      _ResultFilter.anime => l10n.searchFilterAnime(count),
      _ResultFilter.series => l10n.searchFilterSeries(count),
      _ResultFilter.movies => l10n.searchFilterMovies(count),
    };
    return _Pill(
      label: label,
      selected: _filter == filter,
      onTap: () => setState(() => _filter = filter),
    );
  }

  /// What people are watching, from the suggested rails: the names only,
  /// each one a search.
  List<Movie> _hotSearches() {
    final picked = <Movie>[];
    for (final section in _suggestedSections) {
      for (final movie in section.movies) {
        if (!picked.any((m) => m.name == movie.name)) picked.add(movie);
        if (picked.length == 8) return picked;
      }
    }
    return picked;
  }

  /// 热门搜索: shown in Chinese where TMDb has the name, searched by the
  /// English one, which every source knows.
  Widget _buildHotSearches(List<Movie> hot) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LuColors.surface,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: LuColors.lineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10nOf(context).searchHot, style: LuText.heading),
          const SizedBox(height: 8),
          for (var i = 0; i < hot.length; i++)
            LuFocusable(
              lift: 1,
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              onTap: () {
                _searchController.text = hot[i].name;
                _performSearch(hot[i].name);
              },
              builder: (context, hi) => SizedBox(
                height: 40,
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontFamily: LuFonts.display,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: i < 3 ? LuColors.gold : LuColors.textFaint,
                        ),
                      ),
                    ),
                    Expanded(
                      child: LocalTitleText(
                        id: hot[i].id,
                        fallback: hot[i].name,
                        series: hot[i].type == 'series' || hot[i].type == 'tv',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LuText.body.copyWith(
                          fontSize: 15,
                          color: hi ? LuColors.goldLight : LuColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchingMore() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: LuColors.gold,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              l10nOf(context).searchingMoreSources,
              style: LuText.caption.copyWith(color: LuColors.textSoft),
            ),
          ],
        ),
      ),
    );
  }

  /// The finished-but-empty result area. A dead source and a real miss are
  /// different answers, so they get different screens: only the genuine miss
  /// may claim the title does not exist.
  Widget _buildSearchEmptyState(SearchOutcome outcome) {
    final l10n = l10nOf(context);

    switch (outcome) {
      case SearchOutcome.failed:
        final total = _ledger.searchedSourceCount;
        final errors = _ledger.sourceErrors;
        final failed = errors.length > total ? total : errors.length;
        final detail = errors.isEmpty ? '' : ': ${errors.join(', ')}';
        return _EmptyState(
          icon: Icons.cloud_off_rounded,
          title: l10n.searchFailureTitle,
          body:
              '${l10n.searchFailureBody(failed, total)}$detail. '
              '${l10n.searchFailureAdvice}',
          actions: [
            LuButton(
              label: l10n.actionRetry,
              icon: Icons.refresh_rounded,
              onPressed: () => _performSearch(_lastQuery),
            ),
            LuButton(
              label: l10n.actionCopyDiagnostic,
              kind: LuButtonKind.secondary,
              onPressed: _copyDiagnosticReport,
            ),
          ],
        );
      case SearchOutcome.noResults:
        return _EmptyState(
          icon: Icons.search_off_rounded,
          title: l10n.searchNoResults(_lastQuery),
        );
      case SearchOutcome.complete:
      case SearchOutcome.incomplete:
        // Unreachable: both need at least one result, and this widget is only
        // reached when _results is empty.
        return const SizedBox.shrink();
    }
  }

  /// The Failure Ledger: names the sources that died while the rest of the
  /// search carried on, above the results rather than instead of them.
  Widget _buildFailureLedger(double topPadding) {
    final l10n = l10nOf(context);
    final failed = _ledger.sourceErrors;
    final side = _side(context);

    return Padding(
      padding: EdgeInsets.only(
        top: topPadding + _bandHeight + 4,
        left: side,
        right: side,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
        decoration: BoxDecoration(
          color: LuColors.danger.withValues(alpha: 0.10),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          border: Border.all(color: LuColors.danger.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 16,
              color: LuColors.danger,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.searchPartialFailure(failed.join(l10n.listSeparator)),
                style: LuText.caption.copyWith(color: LuColors.danger),
              ),
            ),
            const SizedBox(width: 12),
            LuButton(
              label: l10n.actionRetry,
              kind: LuButtonKind.secondary,
              compact: true,
              onPressed: () => _performSearch(_lastQuery),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoveryEmptyState(double topPadding) {
    final l10n = l10nOf(context);
    final side = _side(context);
    final phone = MediaQuery.sizeOf(context).width < 600;
    final posterW = phone ? 116.0 : 150.0;

    return ListView(
      clipBehavior: Clip.none,
      padding: EdgeInsets.only(
        top: topPadding + _bandHeight + 16,
        bottom: 40 + MediaQuery.paddingOf(context).bottom,
      ),
      physics: const BouncingScrollPhysics(),
      children: [
        // 最近搜索
        if (_searchHistory.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: side),
            child: Row(
              children: [
                Expanded(child: Text(l10n.searchRecent, style: LuText.heading)),
                LuButton(
                  label: l10n.searchClearAll,
                  kind: LuButtonKind.text,
                  compact: true,
                  onPressed: _clearSearchHistory,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: side),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final q in _searchHistory) _buildHistoryChip(q)],
            ),
          ),
          const SizedBox(height: 32),
        ],

        // 热门 rails, posters with their names: someone on the search page is
        // looking for a title.
        if (_suggestedSections.isNotEmpty)
          for (final sec in _suggestedSections)
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: LuRail(
                title: sec.title,
                padding: side,
                height: LuPosterCard.heightFor(posterW),
                itemCount: sec.movies.length,
                itemBuilder: (context, i) {
                  final m = sec.movies[i];
                  return LuPosterCard(
                    width: posterW,
                    title: m.name,
                    titleId: m.id,
                    series: m.type == 'series',
                    poster: m.poster,
                    subtitle: m.year,
                    rating: m.imdbRating,
                    onTap: () => PlayLauncher.openDetails(context, m),
                  );
                },
              ),
            )
        else if (_isLoadingSuggestions)
          const Padding(
            padding: EdgeInsets.only(top: 32),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: LuColors.gold,
              ),
            ),
          ),

        // Nothing at all to show: say so rather than a black screen, which on
        // a television reads as broken.
        if (_searchHistory.isEmpty &&
            _suggestedSections.isEmpty &&
            !_isLoadingSuggestions)
          Padding(
            padding: const EdgeInsets.only(top: 48),
            child: _EmptyState(
              icon: Icons.search_rounded,
              title: l10n.searchNothingToSuggest,
              body: l10n.searchNothingToSuggestBody,
            ),
          ),
      ],
    );
  }

  /// One recent search. The remote runs it; the × beside the label is a
  /// pointer affordance, and 清除全部 above is the remote's way to empty it.
  Widget _buildHistoryChip(String query) {
    return LuFocusable(
      onTap: () {
        _searchController.text = query;
        _performSearch(query);
      },
      builder: (context, hi) => AnimatedContainer(
        duration: LuMotion.focus,
        padding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
        decoration: BoxDecoration(
          color: hi ? const Color(0x24FFFFFF) : const Color(0x14FFFFFF),
          borderRadius: LuRadius.pill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              query,
              style: LuText.body.copyWith(fontSize: 15, color: LuColors.text),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _removeSearchHistory(query),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: LuColors.textFaint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The kind tabs above the results.
enum _ResultFilter { all, anime, series, movies }

/// A tab-like pill: white when selected, outlined otherwise.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      child: LuFocusable(
        onTap: onTap,
        builder: (context, hi) => AnimatedContainer(
          duration: LuMotion.focus,
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? LuColors.text
                : (hi ? const Color(0x1FFFFFFF) : Colors.transparent),
            borderRadius: LuRadius.pill,
            border: selected ? null : Border.all(color: LuColors.line),
          ),
          child: Text(
            label,
            style: LuText.body.copyWith(
              fontSize: 15,
              color: selected ? LuColors.bg : LuColors.textSoft,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

/// A round glyph button inside the field: clear, paste, AI 选片, back.
class _SuffixButton extends StatelessWidget {
  const _SuffixButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color = LuColors.textSoft,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: LuFocusable(
        onTap: onPressed,
        semanticLabel: tooltip,
        builder: (context, hi) => AnimatedContainer(
          duration: LuMotion.focus,
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hi ? const Color(0x24FFFFFF) : const Color(0x14FFFFFF),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

/// A quiet centred message, with actions when there is something to do.
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    this.body,
    this.actions = const [],
  });

  final IconData icon;
  final String title;
  final String? body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 52, color: LuColors.textFaint),
              const SizedBox(height: 16),
              Text(title, textAlign: TextAlign.center, style: LuText.heading),
              if (body case final b?) ...[
                const SizedBox(height: 8),
                Text(
                  b,
                  textAlign: TextAlign.center,
                  style: LuText.bodySoft.copyWith(fontSize: 15),
                ),
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 22),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: actions,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
