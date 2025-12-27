import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  bool _isAvailable = false;

  /// Whether speech recognition is available on this device
  bool get isAvailable => _isAvailable;

  /// Whether currently listening
  bool get isListening => _speech.isListening;

  /// Initialize the speech service and check availability
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isAvailable = await _speech.initialize(
        onError: _handleError,
        onStatus: _handleStatus,
      );
      _isInitialized = true;
    } catch (e) {
      _isAvailable = false;
      _isInitialized = true;
    }
  }

  // Current error handler (set during listening)
  Function(String)? _currentErrorHandler;

  void _handleError(SpeechRecognitionError error) {
    _currentErrorHandler?.call(error.errorMsg);
  }

  void _handleStatus(String status) {
    // Status updates can be used for debugging or UI feedback
  }

  /// Start listening for speech input
  /// [onResult] is called with the transcribed text (may be called multiple times with partial results)
  /// [onError] is called if an error occurs
  /// [onListeningComplete] is called when listening stops
  Future<bool> startListening({
    required Function(String text, bool isFinal) onResult,
    Function(String error)? onError,
    Function()? onListeningComplete,
  }) async {
    if (!_isAvailable) {
      onError?.call('Speech recognition not available');
      return false;
    }

    if (_speech.isListening) {
      await stopListening();
    }

    _currentErrorHandler = onError;

    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          onResult(result.recognizedWords, result.finalResult);
          if (result.finalResult) {
            onListeningComplete?.call();
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        listenOptions: SpeechListenOptions(
          cancelOnError: true,
          partialResults: true,
          listenMode: ListenMode.confirmation,
        ),
      );
      return true;
    } catch (e) {
      onError?.call('Failed to start listening: $e');
      return false;
    }
  }

  /// Stop listening for speech input
  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
    _currentErrorHandler = null;
  }

  /// Cancel listening without processing results
  Future<void> cancelListening() async {
    if (_speech.isListening) {
      await _speech.cancel();
    }
    _currentErrorHandler = null;
  }

  /// Get available locales for speech recognition
  Future<List<LocaleName>> getLocales() async {
    if (!_isAvailable) return [];
    return await _speech.locales();
  }
}
