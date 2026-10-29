import '../../l10n/l10n.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../widgets/common/animated_ambient_background.dart';
import '../../widgets/common/zplay_logo.dart';
import '../../models/addon/addon.dart';
import '../../services/addon/addon_manager.dart';
import '../../services/addon/debrid_addon_catalog.dart';
import '../../services/debrid/debrid_service.dart';
import '../../services/storage/app_image_cache.dart';
import '../../services/theme/design_tokens.dart';
import '../../widgets/common/focusable_card.dart';
import '../../widgets/settings/settings_app_bar.dart';
import '../../models/stream/stream_model.dart' show displayAddonName;
import '../../widgets/settings/lu_settings_kit.dart';
import '../../l10n/option_labels.dart';
import '../../services/content/content_settings.dart';

class AddonsSettingsPage extends StatefulWidget {
  const AddonsSettingsPage({super.key});

  @override
  State<AddonsSettingsPage> createState() => _AddonsSettingsPageState();
}

class _AddonsSettingsPageState extends State<AddonsSettingsPage> {
  final _manager = AddonManager.instance;

  bool _isAdding = false;

  /// Debrid provider picked in Settings, or 'None' when nothing is set up yet.
  String _selectedDebridService = 'None';

  /// Template id whose Connect or Disconnect call is in flight.
  String? _debridAddonBusyId;

  @override
  void initState() {
    super.initState();
    _loadSelectedDebridService();
    _manager.initialize().then((_) {
      if (mounted) setState(() {});
    });
  }

  // ── Debrid addons ──────────────────────────────────────────────────────────

  Future<void> _loadSelectedDebridService() async {
    final service = await DebridService().getSelectedService();
    if (mounted) setState(() => _selectedDebridService = service);
  }

  /// A trailing slash and `/manifest.json` are both cosmetic here, and the
  /// manager strips them when it stores a base URL.
  String _normalizeAddonUrl(String url) {
    var value = url.trim();
    if (value.endsWith('/manifest.json')) {
      value = value.substring(0, value.length - '/manifest.json'.length);
    }
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }

  /// The installed entry for [template], matched by base URL because the same
  /// manifest id is reported for every Debrid variant of the addon.
  InstalledAddon? _installedFor(DebridAddonTemplate template) {
    final prefix = _normalizeAddonUrl(template.plainUrl);
    for (final addon in _manager.addons) {
      final baseUrl = _normalizeAddonUrl(addon.baseUrl);
      if (baseUrl == prefix || baseUrl.startsWith('$prefix/')) return addon;
    }
    return null;
  }

  bool _isConnected(DebridAddonTemplate template, InstalledAddon? installed) {
    if (installed == null) return false;
    final url = template.baseUrlFor(_selectedDebridService);
    if (url == null) return false;
    return _normalizeAddonUrl(installed.baseUrl) == _normalizeAddonUrl(url);
  }

  Future<void> _connectDebridAddon(
    DebridAddonTemplate template,
    String url,
  ) async {
    final installed = _installedFor(template);
    setState(() => _debridAddonBusyId = template.id);

    try {
      final addon = await _manager.replaceAddonUrl(
        installed?.manifest.id ?? template.id,
        url,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10nCurrent().stgcAddonConnectedTo(
              addon.manifest.name,
              _selectedDebridService,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.tokens.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.tokens.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _debridAddonBusyId = null);
    }
  }

  Future<void> _disconnectDebridAddon(
    DebridAddonTemplate template,
    InstalledAddon installed,
  ) async {
    setState(() => _debridAddonBusyId = template.id);

    try {
      await _manager.replaceAddonUrl(installed.manifest.id, template.plainUrl);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.tokens.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _debridAddonBusyId = null);
    }
  }

  Future<void> _addAddon() async {
    final url = await _showAddDialog();
    if (url == null || url.trim().isEmpty) return;

    setState(() => _isAdding = true);

    try {
      final addon = await _manager.addAddon(url);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10nCurrent().stgcAddonInstalled(addon.manifest.name)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.tokens.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.tokens.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<String?> _showAddDialog() {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) {
        final tokens = context.tokens;
        return AlertDialog(
          backgroundColor: tokens.surfaceOverlay,
          shape: RoundedRectangleBorder(
            borderRadius: ZplayRadius.lgAll,
            side: tokens.hairlineStrong,
          ),
          title: Text(
            l10nCurrent().stgaAddStremioAddon,
            style: ZplayType.title.toStyle(color: tokens.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10nCurrent().stgaPasteStremioManifestHint,
                style: ZplayType.body.toStyle(color: tokens.textSecondary),
              ),
              const SizedBox(height: ZplaySpacing.s16),
              TextField(
                controller: controller,
                autofocus: true,
                style: ZplayType.bodySmall.toStyle(color: tokens.textPrimary),
                decoration: InputDecoration(
                  hintText: 'https://opensubtitles-v3.strem.io/manifest.json',
                  hintStyle: ZplayType.bodySmall.toStyle(
                    color: tokens.textDisabled,
                  ),
                  filled: true,
                  fillColor: tokens.surface,
                  border: OutlineInputBorder(
                    borderRadius: ZplayRadius.smAll,
                    borderSide: BorderSide(color: tokens.borderDefault),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: ZplayRadius.smAll,
                    borderSide: BorderSide(color: tokens.borderDefault),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: ZplayRadius.smAll,
                    borderSide: BorderSide(color: tokens.accent),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onSubmitted: (value) => Navigator.pop(context, value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10nCurrent().stgaCancel,
                style: ZplayType.label.toStyle(color: tokens.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.accent,
                foregroundColor: tokens.onAccent,
                shape: const RoundedRectangleBorder(
                  borderRadius: ZplayRadius.smAll,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: Text(
                l10nCurrent().stgaInstall,
                style: ZplayType.label.toStyle(),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmRemove(InstalledAddon addon) {
    if (addon.baseUrl.startsWith('builtin:') ||
        addon.manifest.id == 'builtin.zplay' ||
        addon.manifest.id == 'builtin.zplayhttp') {
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        final tokens = context.tokens;
        return AlertDialog(
          backgroundColor: tokens.surfaceOverlay,
          shape: RoundedRectangleBorder(
            borderRadius: ZplayRadius.lgAll,
            side: tokens.hairlineStrong,
          ),
          title: Text(l10nCurrent().stgcRemoveAddonQ(addon.manifest.name)),
          content: Text(
            l10nCurrent().stgaRemoveAddonBody,
            style: ZplayType.body.toStyle(color: tokens.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10nCurrent().stgaCancel,
                style: ZplayType.label.toStyle(color: tokens.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _manager.removeAddon(addon.manifest.id);
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.danger,
                shape: const RoundedRectangleBorder(
                  borderRadius: ZplayRadius.smAll,
                ),
              ),
              child: Text(
                l10nCurrent().stgaRemove,
                style: ZplayType.label.toStyle(color: tokens.textPrimary),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final addons = _manager.addons;

    return LuSettingsTheme(
      child: AnimatedAmbientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: SettingsAppBar(title: l10nCurrent().stgcAddonsExtensions),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: ZplaySpacing.s16,
                  vertical: ZplaySpacing.s20,
                ),
                children: [_buildStremioTab(addons)],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStremioTab(List<InstalledAddon> addons) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description
        Padding(
          padding: const EdgeInsets.only(bottom: ZplaySpacing.s20),
          child: Text(
            l10nCurrent().stgaStremioTabDescription,
            style: ZplayType.body.toStyle(color: tokens.textSecondary),
          ),
        ),

        // Add Addon Button
        _AddAddonButton(isLoading: _isAdding, onTap: _addAddon),
        const SizedBox(height: ZplaySpacing.s24),

        // Debrid addons
        _buildDebridAddonsSection(),
        const SizedBox(height: ZplaySpacing.s24),

        // Section Header
        Row(
          children: [
            Expanded(
              child: Text(
                l10nCurrent().stgaInstalledProvidersAddons,
                style: ZplayType.overline.toStyle(color: tokens.textMuted),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: ZplaySpacing.s8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ZplaySpacing.s8,
                vertical: ZplaySpacing.s2,
              ),
              decoration: BoxDecoration(
                color: tokens.accentSubtle,
                borderRadius: ZplayRadius.xsAll,
              ),
              child: Text(
                l10nCurrent().stgcAddonsTotal(addons.length),
                style: ZplayType.caption.toStyle(color: tokens.accent),
              ),
            ),
          ],
        ),
        const SizedBox(height: ZplaySpacing.s12),

        // Addons List or Empty State
        if (addons.isEmpty)
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Icon(
                  Icons.extension_off_rounded,
                  size: 40,
                  color: tokens.textDisabled,
                ),
                const SizedBox(height: ZplaySpacing.s12),
                Text(
                  l10nCurrent().stgaNoAddonsInstalled,
                  style: ZplayType.title.toStyle(color: tokens.textEmphasis),
                ),
                const SizedBox(height: 6),
                Text(
                  l10nCurrent().stgaNoAddonsHint,
                  textAlign: TextAlign.center,
                  style: ZplayType.bodySmall.toStyle(color: tokens.textMuted),
                ),
              ],
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: addons.length,
            onReorder: (oldIdx, newIdx) async {
              await _manager.reorderAddons(oldIdx, newIdx);
              setState(() {});
            },
            itemBuilder: (context, index) {
              final addon = addons[index];
              return Padding(
                key: ValueKey(addon.manifest.id),
                padding: const EdgeInsets.only(bottom: ZplaySpacing.s12),
                child: _AddonCard(
                  index: index,
                  totalCount: addons.length,
                  addon: addon,
                  onMoveUp: index > 0
                      ? () async {
                          await _manager.moveAddonUp(index);
                          setState(() {});
                        }
                      : null,
                  onMoveDown: index < addons.length - 1
                      ? () async {
                          await _manager.moveAddonDown(index);
                          setState(() {});
                        }
                      : null,
                  onToggle: (enabled) async {
                    await _manager.toggleAddon(addon.manifest.id, enabled);
                    setState(() {});
                  },
                  onRatingChanged: (rating) async {
                    await _manager.setAddonAdultRating(
                      addon.manifest.id,
                      rating,
                    );
                    setState(() {});
                  },
                  onUpdateFeature:
                      ({
                        enableCatalogs,
                        enableSearch,
                        enableSubtitles,
                        enableStreams,
                      }) async {
                        await _manager.updateAddonFeature(
                          addonId: addon.manifest.id,
                          enableCatalogs: enableCatalogs,
                          enableSearch: enableSearch,
                          enableSubtitles: enableSubtitles,
                          enableStreams: enableStreams,
                        );
                        setState(() {});
                      },
                  onRemove: () => _confirmRemove(addon),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildDebridAddonsSection() {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10nCurrent().stgaDebridAddons,
          style: ZplayType.overline.toStyle(color: tokens.textMuted),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: ZplaySpacing.s4),
        Text(
          l10nCurrent().stgaDebridAddonsDescription,
          style: ZplayType.bodySmall.toStyle(color: tokens.textSecondary),
        ),
        const SizedBox(height: ZplaySpacing.s12),

        for (final template in DebridAddonCatalog.templates)
          Padding(
            padding: const EdgeInsets.only(bottom: ZplaySpacing.s12),
            child: _debridAddonCard(template),
          ),

        Text(
          l10nCurrent().stgaDebridAddonsPlaceholderNote('{realdebrid}'),
          style: ZplayType.caption.toStyle(color: tokens.textMuted),
        ),
      ],
    );
  }

  Widget _debridAddonCard(DebridAddonTemplate template) {
    final installed = _installedFor(template);
    final url = template.baseUrlFor(_selectedDebridService);

    return _DebridAddonCard(
      template: template,
      selectedService: _selectedDebridService,
      isServiceReady: url != null,
      isConnected: _isConnected(template, installed),
      isBusy: _debridAddonBusyId == template.id,
      onConnect: url == null ? null : () => _connectDebridAddon(template, url),
      onDisconnect: installed == null
          ? null
          : () => _disconnectDebridAddon(template, installed),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Addon Card
// ─────────────────────────────────────────────────────────────────────────────

class _AddonCard extends StatelessWidget {
  final int index;
  final int totalCount;
  final InstalledAddon addon;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final ValueChanged<bool> onToggle;
  final ValueChanged<AddonAdultRating> onRatingChanged;
  final void Function({
    bool? enableCatalogs,
    bool? enableSearch,
    bool? enableSubtitles,
    bool? enableStreams,
  })
  onUpdateFeature;
  final VoidCallback onRemove;

  const _AddonCard({
    required this.index,
    required this.totalCount,
    required this.addon,
    this.onMoveUp,
    this.onMoveDown,
    required this.onToggle,
    required this.onRatingChanged,
    required this.onUpdateFeature,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final m = addon.manifest;
    final isHttp =
        addon.manifest.id == 'builtin.zplayhttp' ||
        addon.baseUrl == 'builtin:zplayhttp';
    final isBuiltIn = isHttp || addon.baseUrl.startsWith('builtin:');

    final hasCatalogs = m.supportsCatalog || m.catalogs.isNotEmpty;
    final hasSearch =
        m.catalogs.any((c) => c.supportsSearch) || m.supportsCatalog;
    final hasStreams = m.supportsStream;
    final hasSubtitles = m.supportsSubtitles;
    final hasAnyFeature =
        hasCatalogs || hasSearch || hasStreams || hasSubtitles;

    final providerColor = isHttp ? tokens.success : tokens.accent;

    final subtitleText = isHttp
        ? l10nCurrent().stgaBuiltinHttpScrapers
        : (m.supportsSubtitles && m.catalogs.isEmpty
              ? l10nCurrent().stgcAddonSubtitlesProvider(m.version)
              : l10nCurrent().stgcAddonCatalogs(
                  m.version,
                  m.catalogs.length,
                  m.supportsSubtitles
                      ? l10nCurrent().stgcAddonSubtitlesSuffix
                      : '',
                ));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 560;

        Widget dragHandle() => ReorderableDragStartListener(
          index: index,
          child: MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: Container(
              padding: const EdgeInsets.all(5),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: tokens.borderSubtle,
                borderRadius: ZplayRadius.smAll,
              ),
              child: Icon(
                Icons.drag_indicator_rounded,
                color: tokens.textMuted,
                size: 19,
              ),
            ),
          ),
        );

        Widget priorityBadge() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
          margin: const EdgeInsets.only(right: ZplaySpacing.s8),
          decoration: BoxDecoration(
            color: providerColor.withValues(alpha: ZplayOpacity.overlayHover),
            borderRadius: ZplayRadius.xsAll,
            border: Border.all(
              color: providerColor.withValues(alpha: ZplayOpacity.textDisabled),
            ),
          ),
          child: Text(
            '#${index + 1}',
            style: ZplayType.caption.toStyle(color: providerColor),
          ),
        );

        Widget addonIcon() => Container(
          width: 36,
          height: 36,
          padding: const EdgeInsets.all(3.5),
          decoration: BoxDecoration(
            borderRadius: ZplayRadius.smAll,
            color: providerColor.withValues(alpha: ZplayOpacity.overlayHover),
          ),
          child: isBuiltIn
              ? const ZplayLogo(size: 26)
              : (m.logo != null && m.logo!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: ZplayRadius.xsAll,
                        child: CachedNetworkImage(
                          imageUrl: m.logo!,
                          cacheManager: AppImageCache.manager,
                          memCacheWidth: 96,
                          width: 26,
                          height: 26,
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) => Icon(
                            Icons.extension_rounded,
                            color: providerColor,
                            size: 19,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.extension_rounded,
                        color: providerColor,
                        size: 19,
                      )),
        );

        Widget upDownButtons() => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 20),
              color: onMoveUp != null
                  ? tokens.textEmphasis
                  : tokens.textDisabled,
              onPressed: onMoveUp,
              tooltip: l10nCurrent().stgaMoveUpPriority,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
              color: onMoveDown != null
                  ? tokens.textEmphasis
                  : tokens.textDisabled,
              onPressed: onMoveDown,
              tooltip: l10nCurrent().stgaMoveDownPriority,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              visualDensity: VisualDensity.compact,
            ),
          ],
        );

        Widget switchWidget() => Switch.adaptive(
          value: addon.enabled,
          onChanged: onToggle,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );

        Widget builtInTag() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          decoration: BoxDecoration(
            color: providerColor.withValues(alpha: ZplayOpacity.overlayHover),
            borderRadius: ZplayRadius.xsAll,
          ),
          child: Text(
            l10nCurrent().stgaBuiltinHttp,
            style: ZplayType.overline.toStyle(color: providerColor),
          ),
        );

        Widget removeButton() => IconButton(
          icon: const Icon(Icons.delete_outline_rounded, size: 19),
          color: tokens.danger.withValues(alpha: ZplayOpacity.textSecondary),
          onPressed: onRemove,
          tooltip: l10nCurrent().stgaRemoveAddon,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          visualDensity: VisualDensity.compact,
        );

        return Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isMobile) ...[
                // Mobile Top Row: Drag + Priority + Icon + Title/Badge + Switch
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    dragHandle(),
                    priorityBadge(),
                    addonIcon(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            displayAddonName(m.name),
                            style: ZplayType.subtitle.toStyle(
                              color: tokens.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isBuiltIn) ...[
                            const SizedBox(height: 3),
                            builtInTag(),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: ZplaySpacing.s8),
                    switchWidget(),
                  ],
                ),
                // Mobile Subtitle: Full width of the card, never squished
                Padding(
                  padding: const EdgeInsets.only(
                    top: ZplaySpacing.s8,
                    bottom: ZplaySpacing.s2,
                  ),
                  child: Text(
                    subtitleText,
                    style: ZplayType.bodySmall.toStyle(
                      color: tokens.textSecondary,
                    ),
                  ),
                ),
              ] else ...[
                // Desktop Header Row: Everything inline
                Row(
                  children: [
                    dragHandle(),
                    priorityBadge(),
                    addonIcon(),
                    const SizedBox(width: ZplaySpacing.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  displayAddonName(m.name),
                                  style: ZplayType.subtitle.toStyle(
                                    color: tokens.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isBuiltIn) ...[
                                const SizedBox(width: 6),
                                builtInTag(),
                              ],
                            ],
                          ),
                          const SizedBox(height: ZplaySpacing.s2),
                          Text(
                            subtitleText,
                            style: ZplayType.bodySmall.toStyle(
                              color: tokens.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    upDownButtons(),
                    const SizedBox(width: ZplaySpacing.s4),
                    switchWidget(),
                  ],
                ),
              ],

              // Description
              if (m.description != null && m.description!.isNotEmpty) ...[
                const SizedBox(height: ZplaySpacing.s8),
                Text(
                  localizedOptionLabel(m.description!),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: ZplayType.bodySmall.toStyle(
                    color: tokens.textSecondary,
                  ),
                ),
              ],

              // Feature Toggles Section
              if (addon.enabled && hasAnyFeature) ...[
                const SizedBox(height: ZplaySpacing.s12),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ZplaySpacing.s12,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 13,
                            color: tokens.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            l10nCurrent().stgaFunctions,
                            style: ZplayType.overline.toStyle(
                              color: tokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: ZplaySpacing.s8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (hasCatalogs)
                            _FeatureToggleChip(
                              icon: Icons.grid_view_rounded,
                              label: l10nCurrent().stgaCatalogs,
                              count: m.catalogs.isNotEmpty
                                  ? m.catalogs.length
                                  : null,
                              isEnabled: addon.enableCatalogs,
                              onTap: () => onUpdateFeature(
                                enableCatalogs: !addon.enableCatalogs,
                              ),
                            ),
                          if (hasSearch)
                            _FeatureToggleChip(
                              icon: Icons.search_rounded,
                              label: l10nCurrent().stgaSearch,
                              isEnabled: addon.enableSearch,
                              onTap: () => onUpdateFeature(
                                enableSearch: !addon.enableSearch,
                              ),
                            ),
                          if (hasStreams)
                            _FeatureToggleChip(
                              icon: Icons.play_circle_outline_rounded,
                              label: l10nCurrent().stgaSources,
                              isEnabled: addon.enableStreams,
                              onTap: () => onUpdateFeature(
                                enableStreams: !addon.enableStreams,
                              ),
                            ),
                          if (hasSubtitles)
                            _FeatureToggleChip(
                              icon: Icons.subtitles_rounded,
                              label: l10nCurrent().stgaSubtitles,
                              isEnabled: addon.enableSubtitles,
                              onTap: () => onUpdateFeature(
                                enableSubtitles: !addon.enableSubtitles,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // Adult rating (gates this addon behind the global Adult Content
              // switch). Admins only: no one else can turn that switch on, so
              // the rating means nothing to them.
              if (!isBuiltIn && ContentSettings.isAdmin.value) ...[
                const SizedBox(height: ZplaySpacing.s12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final rating in AddonAdultRating.values)
                      _ratingChip(tokens, rating),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  m.isAdult
                      ? 'This addon declares itself 18+ in its manifest, so it is '
                            'treated as 18+ only whatever is selected above'
                      : switch (addon.adultRating) {
                          AddonAdultRating.sfw =>
                            'No adult content from this addon',
                          AddonAdultRating.hybrid =>
                            'Shows with Adult Content off; its catalogs appear under 18+ in Discover',
                          AddonAdultRating.nsfw =>
                            'Hidden unless Adult Content is on',
                        },
                  style: ZplayType.caption.toStyle(color: tokens.textMuted),
                ),
              ],

              const SizedBox(height: ZplaySpacing.s12),

              // Bottom Row: Type badges + (on mobile: Quick Move) + Remove
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: m.types
                          .map(
                            (type) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: ZplaySpacing.s8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: tokens.borderSubtle,
                                borderRadius: ZplayRadius.xsAll,
                              ),
                              child: Text(
                                _typeLabel(type),
                                style: ZplayType.caption.toStyle(
                                  color: tokens.textSecondary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  if (isMobile) ...[
                    const SizedBox(width: ZplaySpacing.s8),
                    upDownButtons(),
                  ],
                  if (!isBuiltIn) ...[const SizedBox(width: 6), removeButton()],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// A manifest content type ("movie", "series"...) as the app names it.
  static String _typeLabel(String type) {
    if (l10nCurrent().localeName != 'zh') return type;
    return switch (type.toLowerCase()) {
      'movie' => '电影',
      'series' => '剧集',
      'anime' => '动漫',
      'tv' || 'channel' => '电视频道',
      'events' => '赛事',
      _ => type,
    };
  }

  /// One selectable adult rating. The selected state is the enabled one; tapping
  /// it again is a no-op, so the rating can never end up unset.
  Widget _ratingChip(ZplayTokens tokens, AddonAdultRating rating) {
    final selected = addon.adultRating == rating;
    final (label, icon, color) = switch (rating) {
      AddonAdultRating.sfw => (
        'SFW only',
        Icons.shield_outlined,
        tokens.success,
      ),
      AddonAdultRating.hybrid => (
        'Hybrid',
        Icons.balance_rounded,
        tokens.warning,
      ),
      AddonAdultRating.nsfw => (
        '18+ only',
        Icons.eighteen_up_rating_rounded,
        tokens.danger,
      ),
    };

    return _FeatureToggleChip(
      icon: icon,
      label: label,
      isEnabled: selected,
      showStateIcon: selected,
      onTap: () {
        if (selected) return;
        onRatingChanged(rating);
      },
    );
  }
}

class _FeatureToggleChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? count;
  final bool isEnabled;
  final bool showStateIcon;
  final VoidCallback onTap;

  const _FeatureToggleChip({
    required this.icon,
    required this.label,
    this.count,
    required this.isEnabled,
    this.showStateIcon = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    // A default parameter value has to be a compile-time constant, so the
    // palette accent cannot be one; it is resolved here instead.
    final accent = tokens.accent;

    return FocusableCard(
      onTap: onTap,
      builder: (_, state) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isEnabled
                ? (state.highlighted
                      ? accent.withValues(alpha: ZplayOpacity.textDisabled)
                      : accent.withValues(alpha: ZplayOpacity.overlayHover))
                : (state.highlighted
                      ? tokens.borderDefault
                      : tokens.borderSubtle),
            borderRadius: ZplayRadius.smAll,
            border: Border.all(
              color: isEnabled
                  ? accent.withValues(alpha: ZplayOpacity.textSecondary)
                  : tokens.borderDefault,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isEnabled ? accent : tokens.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                count != null
                    ? l10nCurrent().stgcLabelCount(label, '$count')
                    : label,
                style: ZplayType.bodySmall.toStyle(
                  color: isEnabled ? tokens.textPrimary : tokens.textSecondary,
                ),
              ),
              if (showStateIcon) ...[
                const SizedBox(width: 6),
                Icon(
                  isEnabled
                      ? Icons.check_circle_rounded
                      : Icons.cancel_outlined,
                  size: 13,
                  color: isEnabled ? tokens.success : tokens.textDisabled,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Addon Button
// ─────────────────────────────────────────────────────────────────────────────

class _AddAddonButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _AddAddonButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return FocusableCard(
      onTap: onTap,
      enabled: !isLoading,
      builder: (_, state) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: ZplaySpacing.s20),
        decoration: BoxDecoration(
          borderRadius: ZplayRadius.mdAll,
          border: Border.all(
            color: tokens.accent.withValues(alpha: ZplayOpacity.textDisabled),
          ),
          color: tokens.accent.withValues(alpha: ZplayOpacity.borderFaint),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: tokens.accent,
                ),
              )
            else
              Icon(Icons.add_rounded, color: tokens.accent, size: 22),
            const SizedBox(width: 10),
            Text(
              isLoading
                  ? l10nCurrent().stgaInstalling
                  : l10nCurrent().stgaAddAddon,
              style: ZplayType.subtitle.toStyle(color: tokens.accent),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Debrid Addon Card
// ─────────────────────────────────────────────────────────────────────────────

class _DebridAddonCard extends StatelessWidget {
  final DebridAddonTemplate template;
  final String selectedService;
  final bool isServiceReady;
  final bool isConnected;
  final bool isBusy;
  final VoidCallback? onConnect;
  final VoidCallback? onDisconnect;

  const _DebridAddonCard({
    required this.template,
    required this.selectedService,
    required this.isServiceReady,
    required this.isConnected,
    required this.isBusy,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    Widget connectButton() => FocusableCard(
      onTap: onConnect,
      enabled: isServiceReady && !isBusy,
      builder: (_, state) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: !isServiceReady
              ? tokens.borderSubtle
              : (state.highlighted
                    ? tokens.accent.withValues(alpha: ZplayOpacity.overlayHover)
                    : tokens.accent.withValues(
                        alpha: ZplayOpacity.borderFaint,
                      )),
          borderRadius: ZplayRadius.smAll,
          border: Border.all(
            color: isServiceReady
                ? tokens.accent.withValues(alpha: ZplayOpacity.textDisabled)
                : tokens.borderDefault,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isBusy)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: tokens.accent,
                ),
              )
            else
              Icon(
                Icons.link_rounded,
                size: 15,
                color: isServiceReady ? tokens.accent : tokens.textDisabled,
              ),
            const SizedBox(width: 6),
            Text(
              isBusy ? l10nCurrent().stgaConnecting : l10nCurrent().stgaConnect,
              style: ZplayType.bodySmall.toStyle(
                color: isServiceReady ? tokens.accent : tokens.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );

    Widget disconnectButton() => FocusableCard(
      onTap: onDisconnect,
      enabled: !isBusy,
      builder: (_, state) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: state.highlighted
              ? tokens.danger.withValues(alpha: ZplayOpacity.overlayHover)
              : tokens.surface,
          borderRadius: ZplayRadius.smAll,
          border: Border.all(
            color: tokens.danger.withValues(alpha: ZplayOpacity.textDisabled),
          ),
        ),
        child: Text(
          l10nCurrent().stgaDisconnect,
          style: ZplayType.bodySmall.toStyle(color: tokens.danger),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: ZplayRadius.smAll,
                  color: tokens.accent.withValues(
                    alpha: ZplayOpacity.overlayHover,
                  ),
                ),
                child: Icon(Icons.hub_rounded, color: tokens.accent, size: 19),
              ),
              const SizedBox(width: ZplaySpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            template.name,
                            style: ZplayType.subtitle.toStyle(
                              color: tokens.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isConnected) ...[
                          const SizedBox(width: ZplaySpacing.s8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: tokens.accentSubtle,
                              borderRadius: ZplayRadius.xsAll,
                            ),
                            child: Text(
                              l10nCurrent().stgaConnected,
                              style: ZplayType.caption.toStyle(
                                color: tokens.accent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      localizedOptionLabel(template.description),
                      style: ZplayType.bodySmall.toStyle(
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ZplaySpacing.s12),
          Row(
            children: [
              Expanded(
                child: Text(
                  isServiceReady
                      ? l10nCurrent().stgcUsesYourServiceKey(selectedService)
                      : l10nCurrent().stgaNoDebridProviderYet,
                  style: ZplayType.caption.toStyle(
                    color: isServiceReady
                        ? tokens.textMuted
                        : tokens.textDisabled,
                  ),
                ),
              ),
              const SizedBox(width: ZplaySpacing.s8),
              if (isConnected) disconnectButton() else connectButton(),
            ],
          ),
          if (!isServiceReady) ...[
            const SizedBox(height: ZplaySpacing.s4),
            Text(
              l10nCurrent().stgaSetupDebridFirst,
              style: ZplayType.caption.toStyle(color: tokens.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Segmented Tab Button
// ─────────────────────────────────────────────────────────────────────────────
