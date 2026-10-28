import '../../l10n/generated/app_localizations.dart';
import '../../services/audiobook/audiobook_settings.dart';

/// The audiobook settings' choices, in the viewer's language. The enums carry
/// English labels of their own; these pages show these instead.
String abkDensityLabel(AppLocalizations l, AudiobookCardDensity d) =>
    switch (d) {
      AudiobookCardDensity.compact => l.abkDensityCompact,
      AudiobookCardDensity.standard => l.abkDensityStandard,
      AudiobookCardDensity.spacious => l.abkDensitySpacious,
    };

String abkPresetLabel(AppLocalizations l, AudiobookPlayerPreset p) =>
    switch (p) {
      AudiobookPlayerPreset.modernGlass => l.abkPresetModern,
      AudiobookPlayerPreset.vinylStudio => l.abkPresetVinyl,
      AudiobookPlayerPreset.minimalCapsule => l.abkPresetCapsule,
      AudiobookPlayerPreset.immersiveCanvas => l.abkPresetCanvas,
      AudiobookPlayerPreset.customStudio => l.abkPresetCustom,
    };

String abkSeekLabel(AppLocalizations l, AudiobookSeekbarStyle s) => switch (s) {
  AudiobookSeekbarStyle.audioWaveformCanvas => l.abkSeekWaveform,
  AudiobookSeekbarStyle.gradientProgress => l.abkSeekGradient,
  AudiobookSeekbarStyle.standardSlider => l.abkSeekSlider,
  AudiobookSeekbarStyle.circularRing => l.abkSeekRing,
};

String abkButtonLabel(AppLocalizations l, AudiobookPlayButtonStyle s) =>
    switch (s) {
      AudiobookPlayButtonStyle.circleGlow => l.abkButtonCircle,
      AudiobookPlayButtonStyle.liquidGlassNeo => l.abkButtonGlass,
      AudiobookPlayButtonStyle.roundedSquare => l.abkButtonSquare,
      AudiobookPlayButtonStyle.accentPill => l.abkButtonPill,
    };

/// The user agent the audiobook covers are fetched with; some hosts refuse
/// a request without one.
const Map<String, String> abkCoverHeaders = {
  'User-Agent':
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
};
