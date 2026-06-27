import 'dart:math' as math;

final class Vec3 {
  const Vec3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

  Vec3 operator +(Vec3 other) => Vec3(x + other.x, y + other.y, z + other.z);

  Vec3 operator -(Vec3 other) => Vec3(x - other.x, y - other.y, z - other.z);

  Vec3 operator *(double scalar) => Vec3(x * scalar, y * scalar, z * scalar);

  double distanceTo(Vec3 other) {
    final dx = x - other.x;
    final dy = y - other.y;
    final dz = z - other.z;
    return math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  @override
  bool operator ==(Object other) {
    return other is Vec3 && other.x == x && other.y == y && other.z == z;
  }

  @override
  int get hashCode => Object.hash(x, y, z);

  @override
  String toString() => 'Vec3($x, $y, $z)';
}

final class AimViewport {
  const AimViewport({required this.width, required this.height});

  final double width;
  final double height;

  double get centerX => width / 2;
  double get centerY => height / 2;
}
