/// 红线波动模拟 —— 一维离散弦模型
///
/// 不使用物理引擎，只对一条绳子做显式有限差分：
/// - 两端固定为 0，模拟图钉钉住
/// - 拨动时在触点附近注入高斯形位移
/// - 位移沿弦向两侧传播，遇到端点反射
/// - 阻尼让能量逐渐衰减，低于阈值后自动判定静止
///
/// 单位约定：位移为画布像素，[segments] 为采样段数，参数经过调参
/// 使波在约 0.7s 内穿过整条线，并在 3~5s 内自然停下。
library;

import 'dart:math' as math;

class ThreadWave {
  /// 采样段数；位移数组长度为 segments + 1
  final int segments;

  /// 弦张力系数，越大波速越快（需满足 stiffness * dt² < 0.5 保证稳定）
  final double stiffness;

  /// 阻尼系数，越大衰减越快
  final double damping;

  /// 位移上限，避免连续拨动把线拉出画面
  final double maxDisplacement;

  /// 判定静止的位移/速度阈值（像素、像素/秒）
  final double settleThreshold;

  final List<double> _displacement;
  final List<double> _velocity;
  final List<double> _acceleration;

  ThreadWave({
    this.segments = 28,
    this.stiffness = 1500,
    this.damping = 2.4,
    this.maxDisplacement = 24,
    this.settleThreshold = 0.02,
  })  : _displacement = List<double>.filled(segments + 1, 0),
        _velocity = List<double>.filled(segments + 1, 0),
        _acceleration = List<double>.filled(segments + 1, 0);

  /// 当前各采样点的横向位移（只读视图，长度 segments + 1）
  List<double> get displacements => _displacement;

  /// 最大绝对位移，便于调试/测试
  double get maxAbsDisplacement {
    var maxValue = 0.0;
    for (final value in _displacement) {
      final abs = value.abs();
      if (abs > maxValue) maxValue = abs;
    }
    return maxValue;
  }

  /// 是否已静止：所有位移和速度都低于阈值
  bool get isSettled {
    for (var i = 0; i <= segments; i++) {
      if (_displacement[i].abs() > settleThreshold ||
          _velocity[i].abs() > settleThreshold) {
        return false;
      }
    }
    return true;
  }

  /// 在归一化位置 [t]（0~1）附近注入一个高斯形位移
  ///
  /// [amplitude] 为峰值位移（像素），可为负值改变拨动方向；
  /// [width] 为高斯宽度占整条线的比例。端点始终固定为 0。
  void pluck(
    double t, {
    double amplitude = 10,
    double width = 0.08,
  }) {
    final clampedT = t.clamp(0.0, 1.0);
    final center = clampedT * segments;
    final sigma = (width * segments).clamp(1.0, segments * 0.45);

    for (var i = 1; i < segments; i++) {
      final distance = (i - center) / sigma;
      final bump = amplitude * math.exp(-0.5 * distance * distance);
      _displacement[i] =
          (_displacement[i] + bump).clamp(-maxDisplacement, maxDisplacement);
    }
    _displacement[0] = 0;
    _displacement[segments] = 0;
    _velocity[0] = 0;
    _velocity[segments] = 0;
  }

  /// 推进 [dt] 秒
  ///
  /// 调用方应保证 dt 足够小（建议 1/120s）；ThreadLayer 会做固定步长子步进。
  void step(double dt) {
    if (dt <= 0) return;

    for (var i = 1; i < segments; i++) {
      final spring = stiffness *
          (_displacement[i - 1] + _displacement[i + 1] - 2 * _displacement[i]);
      _acceleration[i] = spring - damping * _velocity[i];
    }

    for (var i = 1; i < segments; i++) {
      _velocity[i] += _acceleration[i] * dt;
      _displacement[i] = (_displacement[i] + _velocity[i] * dt)
          .clamp(-maxDisplacement, maxDisplacement);
    }

    _displacement[0] = 0;
    _displacement[segments] = 0;
    _velocity[0] = 0;
    _velocity[segments] = 0;
  }

  /// 清空所有位移与速度
  void clear() {
    _displacement.fillRange(0, segments + 1, 0);
    _velocity.fillRange(0, segments + 1, 0);
    _acceleration.fillRange(0, segments + 1, 0);
  }
}
