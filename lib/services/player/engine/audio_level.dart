/// How loud the film's audio was over one short stretch, stamped with where
/// in the film that stretch plays.
///
/// The player reports these while it plays so the subtitle timing can be
/// checked against when people are actually speaking. [timeSec] is media
/// time (the position in the film, not the wall clock), so a pause or a
/// seek doesn't shift the comparison. [rmsDb] is the root-mean-square level
/// of the speech band in dBFS (0 is full scale, silence is very negative).
class AudioLevelSample {
  const AudioLevelSample(this.timeSec, this.rmsDb);

  final double timeSec;
  final double rmsDb;

  @override
  String toString() => 'AudioLevelSample($timeSec, $rmsDb)';
}

/// The stretch each [AudioLevelSample] covers, in seconds.
const double audioLevelStepSec = 0.1;
