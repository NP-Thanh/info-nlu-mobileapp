import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

const studentStatusOptions = ['ACTIVE', 'GRADUATED', 'LOCKED'];

String studentStatusLabel(String? status) {
  return switch (status?.toUpperCase()) {
    'ACTIVE' => 'Đang học',
    'GRADUATED' => 'Đã tốt nghiệp',
    'LOCKED' => 'Vô hiệu hóa',
    _ => status ?? '—',
  };
}

Color studentStatusColor(String? status) {
  return switch (status?.toUpperCase()) {
    'ACTIVE' => AppColors.primary,
    'GRADUATED' => Colors.blueGrey,
    'LOCKED' => Colors.red,
    _ => AppColors.textSecondary,
  };
}
