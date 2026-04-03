import 'package:flutter/material.dart';

/// A simple data holder for dashboard stat tiles.
class StatData {
  final String label;
  final String value;
  final IconData icon;
  const StatData(this.label, this.value, this.icon);
}
