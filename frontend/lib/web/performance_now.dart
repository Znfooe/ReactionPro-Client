import 'dart:js_interop';

@JS('performance.now')
external double _performanceNow();

double performanceNow() => _performanceNow();
