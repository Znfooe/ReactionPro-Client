import 'client_update_platform_base.dart';
import 'client_update_platform_stub.dart'
    if (dart.library.io) 'client_update_platform_native.dart'
    as implementation;

export 'client_update_platform_base.dart';

ClientUpdatePlatform createClientUpdatePlatform() =>
    implementation.createClientUpdatePlatform();
