import '../../l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/theme/design_tokens.dart';
import '../../widgets/common/animated_ambient_background.dart';
import '../../widgets/player/player_glass.dart';
import '../../widgets/settings/settings_app_bar.dart';

class AboutSettingsPage extends StatelessWidget {
  const AboutSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return AnimatedAmbientBackground(child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: SettingsAppBar(title: l10nCurrent().aboutTitle),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: ZplaySpacing.s16,
              vertical: ZplaySpacing.s24,
            ),
            children: [
              // App Brand Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: tokens.accent,
                        borderRadius: ZplayRadius.lgAll,
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: tokens.onAccent,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Lumora',
                      style: ZplayType.display.toStyle(color: tokens.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (context, snapshot) {
                        final version = snapshot.hasData ? snapshot.data!.version : '1.1.6';
                        return Text(
                          l10nCurrent().stgcAboutVersion(version),
                          style: ZplayType.label.toStyle(
                            color: tokens.textSecondary,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Description
              Padding(
                padding: const EdgeInsets.all(ZplaySpacing.s20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10nCurrent().aboutTagline,
                      style: ZplayType.subtitle.toStyle(
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10nCurrent().aboutBody,
                      style: ZplayType.body
                          .toStyle(color: tokens.textSecondary)
                          .copyWith(height: 1.45),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Architecture & Core Technologies
              Text(
                l10nCurrent().aboutTech,
                style: ZplayType.overline.toStyle(color: tokens.textMuted),
              ),
              const SizedBox(height: 12),

              _buildTechTile(
                context: context,
                title: l10nCurrent().aboutTechEngine,
                subtitle: l10nCurrent().stgbAboutPoweredBy,
              ),
              const SizedBox(height: 10),
              _buildTechTile(
                context: context,
                title: l10nCurrent().aboutTechSources,
                subtitle: l10nCurrent().aboutTechSourcesBody,
              ),
              const SizedBox(height: 10),
              _buildTechTile(
                context: context,
                title: l10nCurrent().aboutTechGlass,
                subtitle: l10nCurrent().aboutTechGlassBody,
              ),
              const SizedBox(height: 10),
              _buildTechTile(
                context: context,
                title: l10nCurrent().aboutTechSync,
                subtitle: l10nCurrent().aboutTechSyncBody,
              ),

              const SizedBox(height: 24),

              // Credits & Licence
              Text(
                l10nCurrent().aboutCredits,
                style: ZplayType.overline.toStyle(color: tokens.textMuted),
              ),
              const SizedBox(height: 12),

              _buildLinkTile(
                context: context,
                icon: Icons.code_rounded,
                title: 'ZPlay',
                subtitle: l10nCurrent().aboutZplayCredit,
                url: 'https://github.com/tzero86/ZPlay',
              ),
              const SizedBox(height: 10),
              _buildLinkTile(
                context: context,
                icon: Icons.history_edu_rounded,
                title: l10nCurrent().aboutPlaytorrio,
                subtitle: l10nCurrent().aboutPlaytorrioCredit,
                url: 'https://github.com/ayman708-UX/PlayTorrioV3',
              ),
              const SizedBox(height: 10),
              _buildTmdbAttributionTile(context),
              const SizedBox(height: 10),
              _buildLicenseTile(context),

              const SizedBox(height: 16),
              Text(
                l10nCurrent().aboutFontLicense,
                style: ZplayType.bodySmall.toStyle(color: tokens.textDisabled),
              ),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildTechTile({
    required BuildContext context,
    required String title,
    required String subtitle,
  }) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: tokens.accent,
              borderRadius: ZplayRadius.xsAll,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ZplayType.subtitle.toStyle(
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: ZplayType.bodySmall.toStyle(
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A tappable credit row that opens [url] in the system browser.
  Widget _buildLinkTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String url,
  }) {
    final tokens = context.tokens;
    return _CreditTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Icon(
        Icons.open_in_new_rounded,
        size: 16,
        color: tokens.textMuted,
      ),
      onTap: () => _openUrl(url),
    );
  }

  /// TMDb attribution, required by the TMDb terms: their logo, the notice
  /// verbatim, and a link back to themoviedb.org.
  Widget _buildTmdbAttributionTile(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            'assets/branding/tmdb-logo.png',
            height: 20,
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
            errorBuilder: (context, error, stackTrace) => Text(
              'TMDB',
              style: ZplayType.label.toStyle(color: tokens.textPrimary),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10nCurrent().aboutTmdb,
            style: ZplayType.bodySmall
                .toStyle(color: tokens.textSecondary)
                .copyWith(height: 1.35),
          ),
          const SizedBox(height: 6),
          FocusableInkWell(
            onTap: () => _openUrl('https://www.themoviedb.org'),
            borderRadius: ZplayRadius.xsAll,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'themoviedb.org',
                style: ZplayType.label.toStyle(
                  color: tokens.accent,
                  decoration: TextDecoration.underline,
                  decorationColor: tokens.accent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Opens the licence notice: ZPlay's own GPL attribution header plus every
  /// third-party package licence Flutter collected at build time.
  Widget _buildLicenseTile(BuildContext context) {
    final tokens = context.tokens;
    return _CreditTile(
      icon: Icons.gavel_rounded,
      title: 'GNU GPL v3.0',
      subtitle:
          l10nCurrent().aboutGplBody,
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: tokens.textMuted,
      ),
      onTap: () => showLicensePage(
        context: context,
        applicationName: 'Lumora',
        applicationLegalese: l10nCurrent().stgcAboutLegalese,
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Shared visual for the credits rows on the About page.
class _CreditTile extends StatelessWidget {
  const _CreditTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return FocusableInkWell(
      onTap: onTap,
      borderRadius: ZplayRadius.mdAll,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: tokens.accent),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: ZplayType.subtitle.toStyle(
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: ZplayType.bodySmall
                        .toStyle(color: tokens.textSecondary)
                        .copyWith(height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: trailing,
            ),
          ],
        ),
      ),
    );
  }
}
