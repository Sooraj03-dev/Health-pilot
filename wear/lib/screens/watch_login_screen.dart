import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'watch_vitals_screen.dart';

class WatchLoginScreen extends StatefulWidget {
  const WatchLoginScreen({super.key});

  @override
  State<WatchLoginScreen> createState() => _WatchLoginScreenState();
}

class _WatchLoginScreenState extends State<WatchLoginScreen> {
  // ── Dev bypass: enter this code to skip Supabase and go straight to vitals ──
  static const String _devBypassCode = '1234';
  static const String _devPatientId = 'dev-patient-00000000-0000-0000-0000-000000000001';

  String _code = '';
  bool _isLoading = false;
  String _errorMessage = '';

  void _onDigitPressed(String digit) {
    if (_code.length < 4) {
      setState(() {
        _code += digit;
        _errorMessage = '';
      });
      if (_code.length == 4) {
        _verifyCode();
      }
    }
  }

  void _onBackspace() {
    if (_code.isNotEmpty) {
      setState(() {
        _code = _code.substring(0, _code.length - 1);
        _errorMessage = '';
      });
    }
  }

  Future<void> _verifyCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // ── Dev bypass ──────────────────────────────────────────────────────────
      if (_code == _devBypassCode) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('watch_patient_id', _devPatientId);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => WatchVitalsScreen(patientId: _devPatientId),
          ),
        );
        return;
      }
      // ── Production flow ──────────────────────────────────────────────────────
      final now = DateTime.now().toUtc().toIso8601String();

      final response = await Supabase.instance.client
          .from('watch_codes')
          .select()
          .eq('code', _code)
          .eq('used', false)
          .gte('expires_at', now)
          .maybeSingle();

      if (response == null) {
        throw Exception('Invalid or expired code');
      }

      final codeId = response['id'];
      final patientId = response['patient_id'];

      // Mark code as used (single-use)
      await Supabase.instance.client
          .from('watch_codes')
          .update({'used': true})
          .eq('id', codeId);

      // Persist session so next launch skips login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('watch_patient_id', patientId);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WatchVitalsScreen(patientId: patientId),
        ),
      );
    } catch (e) {
      setState(() {
        _code = ''; // clear input on error
        _errorMessage = e.toString().contains('Invalid') 
            ? 'Invalid code' 
            : 'Error verifying';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                const Padding(
                   padding: EdgeInsets.only(bottom: 4.0),
                   child: Text(
                      'Enter Code',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                   ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.0),
                    width: 24,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white54, width: 2)),
                    ),
                    child: Text(
                      index < _code.length ? _code[index] : '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              if (_isLoading)
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                _buildKeypad(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKey('1'), _buildKey('2'), _buildKey('3')
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKey('4'), _buildKey('5'), _buildKey('6')
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKey('7'), _buildKey('8'), _buildKey('9')
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKey('⌫', onTap: _onBackspace), 
            _buildKey('0'), 
            _buildKey('', transparent: true)
          ],
        ),
      ],
    );
  }

  Widget _buildKey(String text, {VoidCallback? onTap, bool transparent = false}) {
    return GestureDetector(
      onTap: transparent ? null : (onTap ?? () => _onDigitPressed(text)),
      child: Container(
        margin: const EdgeInsets.all(2.0),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: transparent ? Colors.transparent : Colors.grey[850],
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
             color: Colors.white,
             fontSize: text == '⌫' ? 14 : 16,
             fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
