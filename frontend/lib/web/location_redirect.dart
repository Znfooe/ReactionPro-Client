import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('location')
external JSObject get _location;

void redirectTo(String url) {
  _location.callMethod<JSAny?>('assign'.toJS, url.toJS);
}
