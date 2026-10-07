class DurationFormatter {
  static String format(Duration? duration) {
    if (duration == null || duration.isNegative) {
      return '0:00';
    }

    final totalSeconds = duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
  }

  static String formatSeconds(int? seconds) {
    if (seconds == null) return '0:00';
    return format(Duration(seconds: seconds));
  }
}
