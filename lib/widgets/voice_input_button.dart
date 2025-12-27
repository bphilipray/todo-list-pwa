import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../services/speech_service.dart';

/// A reusable microphone button for voice input
class VoiceInputButton extends StatefulWidget {
  /// Called when transcribed text is available
  final Function(String text) onResult;

  /// Called when an error occurs
  final Function(String error)? onError;

  /// Whether to use compact mode (smaller button for inline use)
  final bool compact;

  /// Optional custom size (overrides compact)
  final double? size;

  const VoiceInputButton({
    super.key,
    required this.onResult,
    this.onError,
    this.compact = false,
    this.size,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  final SpeechService _speechService = SpeechService();
  bool _isListening = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    if (_isListening) {
      _speechService.cancelListening();
    }
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    if (!_speechService.isAvailable) {
      widget.onError?.call('Speech recognition not available on this device');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isListening = true);
    _pulseController.repeat(reverse: true);

    final success = await _speechService.startListening(
      onResult: (text, isFinal) {
        if (isFinal && text.isNotEmpty) {
          widget.onResult(text);
        }
      },
      onError: (error) {
        _stopListening();
        widget.onError?.call(error);
      },
      onListeningComplete: () {
        _stopListening();
      },
    );

    if (!success) {
      _stopListening();
    }
  }

  Future<void> _stopListening() async {
    HapticFeedback.lightImpact();
    _pulseController.stop();
    _pulseController.reset();

    await _speechService.stopListening();

    if (mounted) {
      setState(() => _isListening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final buttonSize = widget.size ?? (widget.compact ? 36.0 : 48.0);
    final iconSize = widget.compact ? 20.0 : 24.0;

    if (!_speechService.isAvailable) {
      // Hide button if speech not available
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isListening ? _pulseAnimation.value : 1.0,
          child: Material(
            color: _isListening
                ? colors.accent
                : colors.surfaceLight,
            borderRadius: BorderRadius.circular(buttonSize / 2),
            child: InkWell(
              onTap: _toggleListening,
              borderRadius: BorderRadius.circular(buttonSize / 2),
              child: SizedBox(
                width: buttonSize,
                height: buttonSize,
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none_rounded,
                  size: iconSize,
                  color: _isListening ? Colors.white : colors.textSecondary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
