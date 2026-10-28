import '../../l10n/l10n.dart';
import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../../models/audiobook/audiobook_model.dart';
import '../../services/audiobook/custom_audiobook_service.dart';
import '../../services/audiobook/downloaded_epub_detector.dart';
import '../../services/audiobook/epub_cover.dart';
import '../../services/audiobook/epub_splitter.dart';
import '../../services/audiobook/paper2audio_service.dart';
import '../../services/theme/design_tokens.dart';
import '../../ui/lu_button.dart';
import '../../ui/lu_confirm.dart';
import '../../ui/lu_text_field.dart';
import '../../ui/lu_theme.dart';
import '../music/lu_media_kit.dart';
import 'audiobook_player_screen.dart';

/// Worker for running EPUB splitting and word analysis off the UI thread via `compute`.
Future<List<EpubPart>> _splitWorker(String path) {
  return EpubSplitter.splitIfNeeded(File(path));
}

/// The audiobook studio: turn an EPUB into an audiobook, or import audio
/// files of your own.
class GenerateAudiobookScreen extends StatelessWidget {
  const GenerateAudiobookScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      Theme(data: luMediaTheme(), child: const _GenerateAudiobookBody());
}

class _GenerateAudiobookBody extends StatefulWidget {
  const _GenerateAudiobookBody();

  @override
  State<_GenerateAudiobookBody> createState() =>
      _GenerateAudiobookScreenState();
}

class _GenerateAudiobookScreenState extends State<_GenerateAudiobookBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Paper2AudioService _paperService = Paper2AudioService.instance;
  final CustomAudiobookService _customService = CustomAudiobookService.instance;

  String _selectedVoiceId = 'af_heart';
  bool _isUploading = false;
  Timer? _pollingTimer;

  List<DetectedEpubBook> _detectedEpubs = [];
  bool _isLoadingEpubs = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _bootstrap();
  }

  /// A swipe moves the [TabController] without going through the segmented
  /// control, so the control has to be rebuilt from the controller's own index.
  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _bootstrap() async {
    await _paperService.getJobs();
    await _customService.ensureLoaded();
    await _loadDownloadedEpubs();
    if (!mounted) return;
    setState(() {});
    _schedulePolling();
  }

  Future<void> _loadDownloadedEpubs() async {
    setState(() => _isLoadingEpubs = true);
    final epubs = await DownloadedEpubDetector.scanDownloadedEpubs();
    if (mounted) {
      setState(() {
        _detectedEpubs = epubs;
        _isLoadingEpubs = false;
      });
    }
  }

  void _schedulePolling() {
    _pollingTimer?.cancel();
    () async {
      await _paperService.refreshAll();
      if (!mounted) return;
      final hasPending = _paperService.jobs.value.any(
        (j) => !j.isDone && !j.isFailed,
      );
      if (hasPending) {
        _pollingTimer = Timer(const Duration(seconds: 8), _schedulePolling);
      }
    }();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Generation Handlers
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _pickAndUploadEpub() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub'],
      withData: false,
    );
    if (result == null || result.files.single.path == null) return;
    await _processAndGenerateFromEpub(File(result.files.single.path!));
  }

  Future<void> _processAndGenerateFromEpub(File file) async {
    setState(() => _isUploading = true);
    try {
      // Analyze and split if oversized (>250k words) on background thread
      final parts = await compute(_splitWorker, file.path);

      // Extract cover image from the original EPUB
      final originalBytes = await file.readAsBytes();
      final rawName = p.basenameWithoutExtension(file.path);
      final safeName = rawName.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
      final coverPath = await EpubCover.extractAndSave(
        epubBytes: originalBytes,
        saveAsName: '${safeName}_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (parts.length > 1) {
        if (!mounted) return;
        final totalWords = parts.fold<int>(0, (a, p) => a + p.wordCount);
        final confirm = await showLuMediaDialog<bool>(
          context: context,
          title: l10nCurrent().abkEpubExceeds250kWords,
          icon: Icons.call_split_rounded,
          body: (ctx, _) => Text(
            l10nCurrent().abkSplitMessage(
              _formatWords(totalWords),
              '${parts.length}',
              parts
                  .map(
                    (p) => l10nCurrent().abkSplitPartLine(
                      p.suggestedName,
                      _formatWords(p.wordCount),
                    ),
                  )
                  .join('\n'),
            ),
            style: LuText.bodySoft,
          ),
          actions: (ctx) => [
            LuButton(
              label: l10nCurrent().abkCancel,
              kind: LuButtonKind.secondary,
              compact: true,
              autofocus: true,
              onPressed: () => Navigator.pop(ctx, false),
            ),
            LuButton(
              label: l10nCurrent().abkSplitGenerate,
              icon: Icons.call_split_rounded,
              compact: true,
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        );

        if (confirm != true) {
          if (mounted) setState(() => _isUploading = false);
          return;
        }
      }

      for (final part in parts) {
        await _paperService.uploadBytes(
          bytes: part.bytes,
          fileName: part.suggestedName,
          voiceId: _selectedVoiceId,
          coverPath: coverPath,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            parts.length == 1
                ? l10nCurrent().abkUploadCompleteGenerationStarted
                : l10nCurrent().abk2UploadedPartsGenerationStarted(
                    parts.length,
                  ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _schedulePolling();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10nCurrent().abk2GenerationFailed(e))),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  String _formatWords(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n >= 100000 ? 0 : 1)}k';
    }
    return n.toString();
  }

  void _playGeneratedAudiobook(GeneratedAudiobookJob job) {
    if (!job.isDone) return;
    final title = job.fileName.replaceAll(
      RegExp(r'\.epub$', caseSensitive: false),
      '',
    );
    final streamOrLocalPath = job.localAudioPath ?? job.downloadUrl!;

    final book = Audiobook(
      uuid: 'p2a_${job.runId}',
      audioBookId: 'p2a_${job.runId}',
      dynamicSlugId: job.runId,
      title: title,
      author: l10nCurrent().abkAiGeneratedKokoro,
      coverImage: job.coverPath ?? '',
      source: 'Paper2Audio AI',
      pageUrl: streamOrLocalPath,
    );

    final chapters = [AudiobookChapter(title: title, url: streamOrLocalPath)];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AudiobookPlayerScreen(audiobook: book, chapters: chapters),
      ),
    );
  }

  Future<void> _copyStreamUrl(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10nCurrent().abk2StreamUrlCopied),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteGeneratedJob(GeneratedAudiobookJob job) async {
    final ok = await showLuConfirm(
      context,
      title: l10nCurrent().abk2RemoveGenerationJob,
      message: l10nCurrent().abk2RemoveFromGenerationList(job.fileName),
      confirmLabel: l10nCurrent().abkRemove,
    );
    if (ok == true) {
      await _paperService.removeJob(job.runId);
      if (mounted) setState(() {});
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Custom Upload Handlers
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _openCustomAudiobookUploadDialog() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'mp3',
        'm4b',
        'm4a',
        'aac',
        'flac',
        'opus',
        'wav',
        'ogg',
      ],
      allowMultiple: true,
      withData: false,
    );

    if (result == null || result.files.isEmpty) return;

    final pickedFiles = result.files
        .where((f) => f.path != null)
        .map((f) => File(f.path!))
        .toList();

    if (pickedFiles.isEmpty || !mounted) return;

    final titleController = TextEditingController(
      text: p
          .basenameWithoutExtension(pickedFiles.first.path)
          .replaceAll(RegExp(r'[._]'), ' ')
          .trim(),
    );
    final authorController = TextEditingController(
      text: l10nCurrent().abkUnknownAuthor,
    );
    File? pickedCoverFile;

    await showLuMediaDialog<void>(
      context: context,
      title: l10nCurrent().abkAddPersonalAudiobook,
      icon: Icons.upload_file_rounded,
      // The controllers go with the dialog's body: its fields still read them
      // while the route animates out, after the dialog's future completes.
      body: (ctx, setDlgState) => _DisposeOnUnmount(
        onDispose: () {
          titleController.dispose();
          authorController.dispose();
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10nCurrent().abk2SelectedAudioFiles(pickedFiles.length),
              style: LuText.label,
            ),
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 90),
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: LuColors.field,
                borderRadius: LuRadius.field,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final f in pickedFiles)
                    Text('• ${p.basename(f.path)}', style: LuText.caption),
                ],
              ),
            ),
            const SizedBox(height: LuSpace.l),
            LuTextField(
              label: l10nCurrent().abkAudiobookTitle,
              controller: titleController,
            ),
            const SizedBox(height: LuSpace.m),
            LuTextField(
              label: l10nCurrent().abkAuthorNarrator,
              controller: authorController,
            ),
            const SizedBox(height: LuSpace.l),
            Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  child: SizedBox.square(
                    dimension: 48,
                    child: LuMediaArt(
                      filePath: pickedCoverFile?.path,
                      cacheWidth: 144,
                      icon: Icons.image_rounded,
                    ),
                  ),
                ),
                const SizedBox(width: LuSpace.m),
                LuButton(
                  label: pickedCoverFile == null
                      ? l10nCurrent().abkSelectCoverArt
                      : l10nCurrent().abkChangeCover,
                  icon: Icons.photo_library_outlined,
                  kind: LuButtonKind.text,
                  onPressed: () async {
                    final imgResult = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                      withData: false,
                    );
                    if (imgResult != null &&
                        imgResult.files.single.path != null) {
                      setDlgState(() {
                        pickedCoverFile = File(imgResult.files.single.path!);
                      });
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: (ctx) => [
        LuButton(
          label: l10nCurrent().abkCancel,
          kind: LuButtonKind.secondary,
          compact: true,
          onPressed: () => Navigator.pop(ctx),
        ),
        LuButton(
          label: l10nCurrent().abkImportToLibrary,
          icon: Icons.library_add_rounded,
          compact: true,
          onPressed: () async {
            // Read before the pop: the controllers are disposed with the
            // dialog.
            final title = titleController.text;
            final author = authorController.text;
            Navigator.pop(ctx);
            await _customService.importAudiobook(
              audioFiles: pickedFiles,
              title: title,
              author: author,
              coverImageFile: pickedCoverFile,
            );
            if (mounted) setState(() {});
          },
        ),
      ],
    );
  }

  void _playUploadedAudiobook(UserUploadedAudiobook book) {
    final audiobook = book.toAudiobookModel();
    final chapters = book.toChapters();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AudiobookPlayerScreen(audiobook: audiobook, chapters: chapters),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // UI Builder
  // ───────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuColors.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: LuMediaGlow()),
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildGeneratorTab(), _buildUploadedTab()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// The route's own chrome: back, the studio's name, and the two tabs as
  /// pills.
  Widget _buildHeader() {
    final l10n = l10nOf(context);
    final pad = luMediaPad(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        pad,
        MediaQuery.paddingOf(context).top + 14,
        pad,
        12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LuMediaIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: l10n.abkBackTip,
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(width: LuSpace.m),
              const Icon(
                Icons.auto_stories_rounded,
                color: LuColors.gold,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.abkAudiobookStudioGenerator,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuText.heading,
                ),
              ),
            ],
          ),
          const SizedBox(height: LuSpace.m),
          LuPillTabs<int>(
            semanticsLabel: l10n.abkAudiobookStudioTabs,
            selected: _tabController.index,
            onSelected: (i) => _tabController.animateTo(i),
            options: [
              LuPillOption(value: 0, label: l10n.abk2AiEpubGeneratorTts),
              LuPillOption(value: 1, label: l10n.abk2MyUploadedAudiobooks),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Tab 1: AI Generator
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildGeneratorTab() {
    final tokens = context.tokens;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: ValueListenableBuilder<List<GeneratedAudiobookJob>>(
          valueListenable: _paperService.jobs,
          builder: (context, jobs, _) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              physics: const BouncingScrollPhysics(),
              children: [
                // ── Voice Selector Card ──
                _buildVoiceSelectorCard(),

                const SizedBox(height: 20),

                // ── Section: Downloaded EPUBs from Books Section ──
                _buildDetectedEpubsSection(),

                const SizedBox(height: 20),

                // ── Upload External EPUB File Banner ──
                _buildUploadExternalCard(),

                const SizedBox(height: 28),

                // ── Section: Active & Completed Generation Jobs ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        l10nCurrent().abk2GenerationQueueCompleted(jobs.length),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LuText.heading.copyWith(fontSize: 18),
                      ),
                    ),
                    LuMediaIconButton(
                      icon: Icons.refresh_rounded,
                      tooltip: l10nCurrent().abkRefreshStatus,
                      quiet: true,
                      onTap: () => _paperService.refreshAll(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (jobs.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tokens.surface,
                      borderRadius: LuRadius.card,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.headphones_rounded,
                          size: 40,
                          color: tokens.textDisabled,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10nCurrent().abkNoGeneratedAudiobooksYet,
                          style: ZplayType.body
                              .copyWith(weight: FontWeight.w600)
                              .toStyle(color: tokens.textEmphasis),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10nCurrent().abkPickAnEpubAboveToSynthesize,
                          style: ZplayType.bodySmall.toStyle(
                            color: tokens.textMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...jobs.map((job) => _buildJobCard(job)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildVoiceSelectorCard() {
    final tokens = context.tokens;
    final selectedVoice = kPaper2AudioVoices.firstWhere(
      (v) => v.id == _selectedVoiceId,
      orElse: () => kPaper2AudioVoices.first,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: LuRadius.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tokens.accent.withValues(alpha: 0.2),
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
                child: Icon(
                  Icons.record_voice_over_rounded,
                  color: tokens.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10nCurrent().abkAiNarratorVoiceKokoroEngine,
                      style: ZplayType.body
                          .copyWith(size: 14.5, weight: FontWeight.w700)
                          .toStyle(color: tokens.textPrimary),
                    ),
                    Text(
                      selectedVoice.description,
                      style: ZplayType.caption
                          .copyWith(size: 11.5)
                          .toStyle(color: tokens.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              // A form field keeps a fill even without its hairline — the same
              // faint wash the dialogs' text fields use.
              color: tokens.textPrimary.withValues(
                alpha: ZplayOpacity.borderFaint,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedVoiceId,
                isExpanded: true,
                dropdownColor: tokens.surfaceOverlay,
                icon: Icon(
                  Icons.arrow_drop_down_rounded,
                  color: tokens.textEmphasis,
                ),
                items: kPaper2AudioVoices.map((voice) {
                  return DropdownMenuItem<String>(
                    value: voice.id,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          voice.label,
                          style: ZplayType.label
                              .copyWith(weight: FontWeight.w600)
                              .toStyle(color: tokens.textPrimary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: tokens.borderDefault,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(6),
                            ),
                          ),
                          child: Text(
                            voice.group,
                            style: ZplayType.overline
                                .copyWith(weight: FontWeight.w700)
                                .toStyle(color: tokens.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedVoiceId = val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectedEpubsSection() {
    final tokens = context.tokens;

    if (_isLoadingEpubs) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_detectedEpubs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                l10nCurrent().abk2DownloadedBooksFromLibrary(
                  _detectedEpubs.length,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LuText.heading.copyWith(fontSize: 18),
              ),
            ),
            LuButton(
              label: l10nCurrent().abkRescanBooks,
              icon: Icons.refresh_rounded,
              kind: LuButtonKind.text,
              onPressed: _loadDownloadedEpubs,
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            physics: const BouncingScrollPhysics(),
            itemCount: _detectedEpubs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, idx) {
              final epub = _detectedEpubs[idx];
              return Container(
                width: 280,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tokens.surface,
                  borderRadius: LuRadius.card,
                ),
                child: Row(
                  children: [
                    // Cover image
                    Container(
                      width: 65,
                      height: 145,
                      decoration: BoxDecoration(
                        color: tokens.borderStrong,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: epub.coverPath != null
                          ? Image.file(File(epub.coverPath!), fit: BoxFit.cover)
                          : Icon(
                              Icons.book_rounded,
                              color: tokens.textDisabled,
                              size: 30,
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            epub.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: ZplayType.label
                                .copyWith(weight: FontWeight.w700)
                                .toStyle(color: tokens.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10nCurrent().abk2FileSizeMb(
                              (epub.fileSizeBytes / (1024 * 1024))
                                  .toStringAsFixed(1),
                            ),
                            style: ZplayType.caption.toStyle(
                              color: tokens.textMuted,
                            ),
                          ),
                          const Spacer(),
                          LuButton(
                            label: l10nCurrent().abkGenerate,
                            icon: Icons.record_voice_over_rounded,
                            compact: true,
                            busy: _isUploading,
                            onPressed: () => _processAndGenerateFromEpub(
                              File(epub.filePath),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// A wide studio action: a gold glyph, two lines and a chevron.
  Widget _studioBanner({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool busy = false,
  }) {
    return LuMediaTile(
      onTap: onTap,
      semanticLabel: title,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0x29F2B544),
              borderRadius: LuRadius.field,
            ),
            child: busy
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Icon(icon, color: LuColors.gold, size: 26),
          ),
          const SizedBox(width: LuSpace.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: LuText.body.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: LuText.caption),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: LuColors.textMuted,
            size: 26,
          ),
        ],
      ),
    );
  }

  Widget _buildUploadExternalCard() {
    return _studioBanner(
      icon: Icons.upload_file_rounded,
      title: _isUploading
          ? l10nCurrent().abkAnalyzingUploadingBook
          : l10nCurrent().abkSelectExternalEpubFile,
      subtitle: l10nCurrent().abkPickAnyEpubFileFromYour,
      busy: _isUploading,
      onTap: _isUploading ? null : _pickAndUploadEpub,
    );
  }

  Widget _buildJobCard(GeneratedAudiobookJob job) {
    final tokens = context.tokens;
    final isDone = job.isDone;
    final isFailed = job.isFailed;
    final cleanTitle = job.fileName.replaceAll(
      RegExp(r'\.epub$', caseSensitive: false),
      '',
    );

    Color statusColor;
    String statusLabel;
    if (isDone) {
      statusColor = tokens.success;
      statusLabel = l10nCurrent().abkCompleted;
    } else if (isFailed) {
      statusColor = tokens.danger;
      statusLabel = l10nCurrent().abkFailed;
    } else {
      statusColor = tokens.warning;
      statusLabel = l10nCurrent().abk2SynthesizingPercent(
        (job.progress * 100).round(),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: LuRadius.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Cover
              Container(
                width: 48,
                height: 64,
                decoration: BoxDecoration(
                  color: tokens.borderStrong,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
                clipBehavior: Clip.antiAlias,
                child:
                    job.coverPath != null && File(job.coverPath!).existsSync()
                    ? Image.file(File(job.coverPath!), fit: BoxFit.cover)
                    : Icon(
                        Icons.headphones_rounded,
                        color: tokens.textDisabled,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cleanTitle,
                      style: ZplayType.body
                          .copyWith(weight: FontWeight.w700)
                          .toStyle(color: tokens.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(6),
                            ),
                          ),
                          child: Text(
                            statusLabel,
                            style: ZplayType.caption
                                .copyWith(size: 10.5, weight: FontWeight.w700)
                                .toStyle(color: statusColor),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10nCurrent().abk2JobVoiceLabel(job.voiceId),
                          style: ZplayType.caption.toStyle(
                            color: tokens.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Delete Button
              LuMediaIconButton(
                icon: Icons.delete_outline_rounded,
                tooltip: l10nCurrent().abkDeleteJobTip,
                quiet: true,
                iconColor: LuColors.textMuted,
                onTap: () => _deleteGeneratedJob(job),
              ),
            ],
          ),

          if (!isDone && !isFailed) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(6)),
              child: LinearProgressIndicator(
                value: job.progress > 0 ? job.progress : null,
                backgroundColor: tokens.borderStrong,
                color: tokens.accent,
                minHeight: 5,
              ),
            ),
          ],

          if (isDone) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LuButton(
                    compact: true,
                    label: l10nCurrent().abkPlayInApp,
                    icon: Icons.play_arrow_rounded,
                    expand: true,
                    onPressed: () => _playGeneratedAudiobook(job),
                  ),
                ),
                const SizedBox(width: 8),
                if (job.downloadUrl != null)
                  LuButton(
                    compact: true,
                    label: l10nCurrent().abkCopyStreamUrl,
                    icon: Icons.link_rounded,
                    kind: LuButtonKind.secondary,
                    onPressed: () => _copyStreamUrl(job.downloadUrl!),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Tab 2: My Uploaded Audiobooks
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildUploadedTab() {
    final tokens = context.tokens;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: ValueListenableBuilder<List<UserUploadedAudiobook>>(
          valueListenable: _customService.audiobooks,
          builder: (context, books, _) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              physics: const BouncingScrollPhysics(),
              children: [
                // Upload Personal Audiobook Banner
                _studioBanner(
                  icon: Icons.library_add_rounded,
                  title: l10nCurrent().abkUploadPersonalAudiobookFiles,
                  subtitle: l10nCurrent().abkImportYourOwnMp3M4bM4a,
                  onTap: _openCustomAudiobookUploadDialog,
                ),

                const SizedBox(height: 24),

                Text(
                  l10nCurrent().abk2ImportedAudiobooksCount(books.length),
                  style: ZplayType.overline
                      .copyWith(
                        size: 12,
                        weight: FontWeight.w700,
                        letterSpacing: 1.1,
                      )
                      .toStyle(color: tokens.textMuted),
                ),
                const SizedBox(height: 10),

                if (books.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tokens.surface,
                      borderRadius: LuRadius.card,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.library_music_rounded,
                          size: 40,
                          color: tokens.textDisabled,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10nCurrent().abkNoPersonalAudiobooksAddedYet,
                          style: ZplayType.body
                              .copyWith(weight: FontWeight.w600)
                              .toStyle(color: tokens.textEmphasis),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10nCurrent().abkTapTheBannerAboveToImport,
                          style: ZplayType.bodySmall.toStyle(
                            color: tokens.textMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...books.map((b) => _buildUploadedBookCard(b)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildUploadedBookCard(UserUploadedAudiobook book) {
    final tokens = context.tokens;
    final sizeMb = (book.totalBytes / (1024 * 1024)).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: LuRadius.card,
      ),
      child: Row(
        children: [
          // Cover
          Container(
            width: 48,
            height: 64,
            decoration: BoxDecoration(
              color: tokens.borderStrong,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            clipBehavior: Clip.antiAlias,
            child: book.coverPath != null && File(book.coverPath!).existsSync()
                ? Image.file(File(book.coverPath!), fit: BoxFit.cover)
                : Icon(
                    Icons.music_note_rounded,
                    color: tokens.textDisabled,
                    size: 24,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: ZplayType.body
                      .copyWith(weight: FontWeight.w700)
                      .toStyle(color: tokens.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  l10nCurrent().abk2AuthorPartsSize(
                    book.author,
                    book.audioFilePaths.length,
                    sizeMb,
                  ),
                  style: ZplayType.bodySmall.toStyle(
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          LuButton(
            compact: true,
            label: l10nCurrent().abkPlay,
            icon: Icons.play_arrow_rounded,
            onPressed: () => _playUploadedAudiobook(book),
          ),
          const SizedBox(width: 6),
          LuMediaIconButton(
            icon: Icons.delete_outline_rounded,
            tooltip: l10nCurrent().abkDelete,
            quiet: true,
            iconColor: LuColors.textMuted,
            onTap: () async {
              final ok = await showLuConfirm(
                context,
                title: l10nCurrent().abk2DeleteAudiobook,
                message: l10nCurrent().abk2DeleteFromLibrary(book.title),
                confirmLabel: l10nCurrent().abkDelete,
              );
              if (ok) {
                await _customService.deleteAudiobook(book.id);
                if (mounted) setState(() {});
              }
            },
          ),
        ],
      ),
    );
  }
}

/// Runs [onDispose] when it leaves the tree, after the widgets below it have
/// let go of whatever it disposes.
class _DisposeOnUnmount extends StatefulWidget {
  const _DisposeOnUnmount({required this.onDispose, required this.child});

  final VoidCallback onDispose;
  final Widget child;

  @override
  State<_DisposeOnUnmount> createState() => _DisposeOnUnmountState();
}

class _DisposeOnUnmountState extends State<_DisposeOnUnmount> {
  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
