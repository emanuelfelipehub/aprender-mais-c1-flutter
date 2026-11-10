Duration splashDuration({required bool firstLaunch}) =>
    Duration(seconds: firstLaunch ? 10 : 3);

const maxRecordingDuration = Duration(minutes: 1);
