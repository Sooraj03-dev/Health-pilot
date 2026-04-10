import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'watch_login_screen.dart';

class WatchVitalsScreen extends StatefulWidget {
  final String patientId;

  const WatchVitalsScreen({super.key, required this.patientId});

  @override
  State<WatchVitalsScreen> createState() => _WatchVitalsScreenState();
}

class _WatchVitalsScreenState extends State<WatchVitalsScreen> with SingleTickerProviderStateMixin {
  static const _sensorChannel = MethodChannel('health_pilot/sensor');

  int? _hr;
  int? _spo2;
  bool _isScanning = false;
  bool _isSaved = false;
  String? _error;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _isSaved = false;
      _error = null;
      _hr = null;
      _spo2 = null;
    });

    try {
      final dynamic rawResult = await _sensorChannel.invokeMethod('startScan');
      if (rawResult == null) throw Exception('Scan canceled or no data');

      final result = Map<String, dynamic>.from(rawResult);
      final hr = result['heart_rate'] as int;
      final spo2 = result['spo2'] as int;

      if (mounted) {
        setState(() {
          _hr = hr;
          _spo2 = spo2;
          _isScanning = false;
        });
      }

      await _uploadToSupabase(hr, spo2);
    } on PlatformException catch (e) {
      if (mounted) setState(() { _error = e.message; _isScanning = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _isScanning = false; });
    }
  }

  Future<void> _uploadToSupabase(int hr, int spo2) async {
    try {
      await Supabase.instance.client.from('health_metrics').insert({
        'patient_id': widget.patientId,
        'heart_rate': hr,
        'spo2': spo2,
        'recorded_at': DateTime.now().toUtc().toIso8601String(),
      });
      if (mounted) setState(() => _isSaved = true);
    } catch (e) {
      if (mounted) setState(() => _error = 'Sync failed');
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('watch_patient_id');
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WatchLoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.8,
            colors: [
              Color(0xFF1A0A0A),
              Colors.black,
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background scanning ring
            if (_isScanning)
              SizedBox.expand(
                child: Center(
                  child: SizedBox(
                    width: 170,
                    height: 170,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent.withOpacity(0.5)),
                    ),
                  ),
                ),
              ),

            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   // Top Bar / Logout
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildSmallCircleButton(Icons.logout, _logout),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Results display
                  if (_hr != null && _spo2 != null)
                    Column(
                      children: [
                        _buildGlassCard(Icons.favorite, Colors.redAccent, '$_hr', 'BPM'),
                        const SizedBox(height: 8),
                        _buildGlassCard(Icons.water_drop, Colors.blueAccent, '$_spo2', '%'),
                        if (_isSaved)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text('Sync ✓', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    )
                  else if (_isScanning)
                    const Column(
                      children: [
                        Text('MEASURING', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Stay Still', style: TextStyle(color: Colors.white38, fontSize: 10)),
                      ],
                    )
                  else
                    const Column(
                      children: [
                        Icon(Icons.monitor_heart, color: Colors.white24, size: 40),
                        SizedBox(height: 8),
                        Text('READY TO SCAN', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600)),
                      ],
                    ),

                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 4),
                      child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 9), textAlign: TextAlign.center, maxLines: 1),
                    ),

                  const Spacer(),

                  // Bottom Button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildScanButton(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard(IconData icon, Color color, String value, String unit) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          width: 140,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Text(unit, style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanButton() {
    return FadeTransition(
      opacity: _isScanning ? _pulseController : const AlwaysStoppedAnimation(1.0),
      child: GestureDetector(
        onTap: _isScanning ? null : _startScan,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isScanning 
                ? [Colors.grey[900]!, Colors.grey[800]!] 
                : [const Color(0xFFE53935), const Color(0xFFD32F2F)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _isScanning ? Colors.transparent : Colors.redAccent.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            _isScanning ? 'SCANNING...' : 'TAP TO SCAN',
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallCircleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, color: Colors.white54, size: 14),
      ),
    );
  }
}
