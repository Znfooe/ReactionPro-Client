import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('localStorage')
external JSObject get _localStorage;

String? readLocalStorage(String key) {
  return _localStorage
      .callMethod<JSString?>('getItem'.toJS, key.toJS)
      ?.toDart;
}

void writeLocalStorage(String key, String value) {
  _localStorage.callMethod<JSAny?>('setItem'.toJS, key.toJS, value.toJS);
}
