import 'dart:math' as math;

import 'aim_geometry.dart';
import 'sensitivity.dart';
import 'target_manager.dart';

final class ProjectedTarget {
  const ProjectedTarget({
    required this.target,
    required this.centerX,
    required this.centerY,
    required this.radiusPx,
    required this.depth,
    required this.visible,
  });

  final AimTarget target;
  final double centerX;
  final double centerY;
  final double radiusPx;
  final double depth;
  final bool visible;

  bool contains(double x, double y) {
    final dx = x - centerX;
    final dy = y - centerY;
    return dx * dx + dy * dy <= radiusPx * radiusPx;
  }
}

final class CanvasSceneProjector {
  const CanvasSceneProjector({this.horizontalFovDegrees = 106});

  final double horizontalFovDegrees;

  ProjectedTarget? projectTarget({
    required AimTarget target,
    required ViewAngles camera,
    required AimViewport viewport,
  }) {
    final cameraSpace = _toCameraSpace(target.position, camera);
    if (cameraSpace.z <= 0.05) {
      return null;
    }

    final focalLength =
        viewport.width / 2 / math.tan(horizontalFovDegrees * math.pi / 360);
    final centerX =
        viewport.centerX + cameraSpace.x / cameraSpace.z * focalLength;
    final centerY =
        viewport.centerY - cameraSpace.y / cameraSpace.z * focalLength;
    final perspectiveRadiusPx =
        target.radiusMeters / cameraSpace.z * focalLength;
    final radiusPx = target.screenRadiusPx ?? perspectiveRadiusPx;
    final visible =
        centerX + radiusPx >= 0 &&
        centerX - radiusPx <= viewport.width &&
        centerY + radiusPx >= 0 &&
        centerY - radiusPx <= viewport.height;

    return ProjectedTarget(
      target: target,
      centerX: centerX,
      centerY: centerY,
      radiusPx: radiusPx,
      depth: cameraSpace.z,
      visible: visible,
    );
  }

  Vec3 _toCameraSpace(Vec3 world, ViewAngles camera) {
    final yawCos = math.cos(camera.yawRadians);
    final yawSin = math.sin(camera.yawRadians);
    final pitchCos = math.cos(camera.pitchRadians);
    final pitchSin = math.sin(camera.pitchRadians);

    final yawX = yawCos * world.x - yawSin * world.z;
    final yawZ = yawSin * world.x + yawCos * world.z;
    final pitchY = pitchCos * world.y - pitchSin * yawZ;
    final pitchZ = pitchSin * world.y + pitchCos * yawZ;

    return Vec3(yawX, pitchY, pitchZ);
  }
}
