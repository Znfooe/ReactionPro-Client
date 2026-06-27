final Stopwatch _monotonicClock = Stopwatch()..start();

double performanceNow() => _monotonicClock.elapsedMicroseconds / 1000;
