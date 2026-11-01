import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

double canvasMatrixScale(Matrix4 matrix) {
  final values = matrix.storage;
  final scaleX = math.sqrt(values[0] * values[0] + values[1] * values[1]);
  final scaleY = math.sqrt(values[4] * values[4] + values[5] * values[5]);

  if (scaleX == 0) return scaleY;
  if (scaleY == 0) return scaleX;
  return (scaleX + scaleY) / 2;
}

Matrix4 canvasMatrixFromScaleAndTranslation({
  required double scale,
  required double tx,
  required double ty,
}) {
  return Matrix4.identity()
    ..scaleByVector3(Vector3(scale, scale, 1.0))
    ..translateByVector3(Vector3(tx / scale, ty / scale, 0.0));
}
