import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../config/api_config.dart';
import '../models/category_model.dart';
import '../services/ai_service.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';

/// Shows a full-screen voice / text entry experience.
///
/// When [prefillOnly] is true, tapping apply returns a [VoiceParseResult] for
/// the caller to fill form fields instead of saving a transaction directly.
Future<VoiceParseResult?> showVoiceInputSheet(
  BuildContext context, {
  bool prefillOnly = false,
}) {
  return showModalBottomSheet<VoiceParseResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _VoiceInputSheet(prefillOnly: prefillOnly),
  );
}

class _VoiceInputSheet extends StatefulWidget {
  const _VoiceInputSheet({this.prefillOnly = false});

  final bool prefillOnly;

  @override
  State<_VoiceInputSheet> createState() => _VoiceInputSheetState();
}

class _VoiceInputSheetState extends State<_VoiceInputSheet>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _recorder = AudioRecorder();
  final _ai = AiService();

  String _status = 'Tap mic to speak';
  bool _isListening = false;
  bool _isProcessing = false;
  bool _showKeyboard = false;
  bool _parsed = false;
  VoiceParseResult? _result;
  String? _recordingPath;

  late AnimationController _ripple1;
  late AnimationController _ripple2;
  late AnimationController _barController;

  final List<double> _barHeights = List.generate(7, (_) => 0.3);
  final _random = math.Random();

  @override
  void initState() {
    super.initState();

    _ripple1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _ripple2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: false);

    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && _isListening) {
          setState(() {
            for (int i = 0; i < _barHeights.length; i++) {
              _barHeights[i] = 0.2 + _random.nextDouble() * 0.8;
            }
          });
          _barController
            ..reset()
            ..forward();
        }
      });
  }

  Map<String, dynamic> _voiceContext(AppState state) => {
        'categories': state.categories
            .map((c) => {
                  'id': c.id,
                  'name': c.name,
                  'section': c.section.name,
                })
            .toList(),
        'tags': state.tags
            .map((t) => {
                  'id': t.id,
                  'name': t.name,
                })
            .toList(),
      };

  Future<bool> _ensureMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> _toggleListening() async {
    if (_isProcessing) return;

    if (_isListening) {
      await _stopAndProcess();
      return;
    }

    if (!await _ensureMicPermission()) {
      setState(() => _status = 'Microphone permission denied');
      return;
    }

    final dir = await getTemporaryDirectory();
    _recordingPath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    try {
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
        path: _recordingPath!,
      );
      setState(() {
        _isListening = true;
        _parsed = false;
        _result = null;
        _controller.clear();
        _status = 'Listening... tap mic when done';
      });
      _barController.forward();
    } catch (e) {
      setState(() => _status = 'Could not start recording');
    }
  }

  Future<void> _stopAndProcess() async {
    setState(() {
      _isListening = false;
      _isProcessing = true;
      _status = 'Processing...';
      _barController.stop();
    });

    String? path;
    try {
      path = await _recorder.stop();
    } catch (_) {}

    path ??= _recordingPath;
    await _processInput(audioPath: path);
  }

  Future<void> _processInput({String? audioPath, bool fromText = false}) async {
    final state = context.read<AppState>();
    final ctx = _voiceContext(state);

    List<int>? audioBytes;
    String? filename;
    if (audioPath != null && File(audioPath).existsSync()) {
      audioBytes = await File(audioPath).readAsBytes();
      filename = audioPath.split(Platform.pathSeparator).last;
    }

    final typed = _controller.text.trim();
    VoiceParseResult? result;

    try {
      if (ApiConfig.isConfigured && (audioBytes != null || typed.isNotEmpty)) {
        result = await _ai.parseVoiceExpense(
          context: ctx,
          audioBytes: audioBytes,
          audioFilename: filename,
          text: typed.isNotEmpty ? typed : null,
        );
      }

      if (result == null && typed.isNotEmpty) {
        result = _localParse(typed, state);
      }
    } catch (_) {
      result = null;
    }

    if (!mounted) return;

    if (result == null) {
      setState(() {
        _isProcessing = false;
        _status = ApiConfig.isConfigured
            ? 'Could not reach AI backend — check API_BASE_URL and APP_SECRET'
            : 'Set API_BASE_URL to use voice AI';
      });
      return;
    }

    if (result.error != null && result.error!.isNotEmpty && !result.hasAmount) {
      setState(() {
        _isProcessing = false;
        _status = result!.error!;
        _controller.text = result.transcription;
      });
      return;
    }

    setState(() {
      _isProcessing = false;
      _result = result;
      _parsed = result!.hasAmount;
      _controller.text = result.transcription.isNotEmpty ? result.transcription : typed;
      if (result.hasAmount) {
        final cat = result.categoryName ?? 'expense';
        _status = 'Rs.${result.amount!.toStringAsFixed(0)} · $cat';
      } else {
        _status = 'Could not find an amount — edit or try again';
      }
    });
  }

  VoiceParseResult _localParse(String text, AppState state) {
    final lower = text.toLowerCase();
    final amountMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(lower);
    final amount = amountMatch != null ? double.tryParse(amountMatch.group(1)!) : null;

    CategoryModel? matched;
    for (final c in state.categoriesBySection(CategorySection.daily)) {
      if (lower.contains(c.name.toLowerCase())) {
        matched = c;
        break;
      }
    }
    matched ??= state.categoriesBySection(CategorySection.daily).isNotEmpty
        ? state.categoriesBySection(CategorySection.daily).first
        : null;

    return VoiceParseResult(
      transcription: text,
      amount: amount,
      categoryId: matched?.id,
      categoryName: matched?.name,
      note: text,
    );
  }

  Future<void> _parseFromText() async {
    if (_controller.text.trim().isEmpty) {
      setState(() => _status = 'Say or type an expense first');
      return;
    }
    setState(() {
      _isProcessing = true;
      _status = 'Processing...';
    });
    await _processInput(fromText: true);
  }

  VoiceParseResult _buildPrefillResult(VoiceParseResult? result, String text) {
    if (result != null) {
      return VoiceParseResult(
        transcription: result.transcription.isNotEmpty ? result.transcription : text,
        amount: result.amount,
        categoryId: result.categoryId,
        categoryName: result.categoryName,
        note: result.note.isNotEmpty ? result.note : text,
        paymentMethod: result.paymentMethod,
        date: result.date,
        tagIds: result.tagIds,
        error: result.error,
      );
    }
    return VoiceParseResult(transcription: text, note: text);
  }

  Future<void> _confirm() async {
    var result = _result;
    final text = _controller.text.trim();

    if (widget.prefillOnly) {
      if (result == null && text.isNotEmpty) {
        await _parseFromText();
        if (!mounted) return;
        result = _result;
      }
      if (!mounted) return;
      if (result != null || text.isNotEmpty) {
        Navigator.pop(context, _buildPrefillResult(result, text));
        return;
      }
      setState(() => _status = 'Say or type an expense first');
      return;
    }

    if (result != null && result.hasAmount && result.categoryId != null) {
      final state = context.read<AppState>();
      await state.addTransaction(
        amount: result.amount!,
        note: result.note.isNotEmpty ? result.note : text,
        categoryId: result.categoryId!,
        date: result.date ?? DateTime.now(),
        paymentMethod: result.paymentMethod,
        tagIds: result.tagIds,
      );
      if (mounted) Navigator.pop(context);
      return;
    }

    if (text.isNotEmpty) {
      await _parseFromText();
      if (!mounted) return;
      final retry = _result;
      if (retry != null && retry.hasAmount && retry.categoryId != null) {
        await _confirm();
      }
      return;
    }

    setState(() => _status = 'Could not parse expense');
  }

  @override
  void dispose() {
    _recorder.dispose();
    _ripple1.dispose();
    _ripple2.dispose();
    _barController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm = widget.prefillOnly
        ? !_isProcessing && !_isListening && (_parsed || _controller.text.trim().isNotEmpty)
        : _parsed && !_isProcessing && !_isListening;

    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: const BoxDecoration(
        color: AppColors.bg0,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Row(
                    children: [
                      Icon(Icons.close, color: AppColors.t2, size: 22),
                      SizedBox(width: 4),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'VOICE ENTRY',
                  style: AppText.label.copyWith(color: AppColors.t3, letterSpacing: 1.4),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _showKeyboard = !_showKeyboard),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: AppColors.bg3,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      _showKeyboard ? Icons.mic : Icons.keyboard,
                      size: 20,
                      color: AppColors.t2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _ripple1,
                        builder: (_, __) {
                          final v = _ripple1.value;
                          return Container(
                            width: 180 * (1 + v * 0.5),
                            height: 180 * (1 + v * 0.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.amberBright.withValues(alpha: 0.15 * (1 - v)),
                            ),
                          );
                        },
                      ),
                      AnimatedBuilder(
                        animation: _ripple2,
                        builder: (_, __) {
                          final v = (_ripple2.value + 0.5) % 1.0;
                          return Container(
                            width: 180 * (1 + v * 0.5),
                            height: 180 * (1 + v * 0.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.amberBright.withValues(alpha: 0.1 * (1 - v)),
                            ),
                          );
                        },
                      ),
                      GestureDetector(
                        onTap: _toggleListening,
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: _isListening ? AppColors.amberBright : AppColors.amber,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.amber.withValues(alpha: 0.35),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: _isProcessing
                              ? const SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: AppColors.onAmber,
                                  ),
                                )
                              : Icon(
                                  _isListening ? Icons.stop_rounded : Icons.mic,
                                  size: 46,
                                  color: AppColors.onAmber,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_isListening)
                  SizedBox(
                    height: 48,
                    width: 120,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (int i = 0; i < _barHeights.length; i++) ...[
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            width: 8,
                            height: 48 * _barHeights[i],
                            decoration: BoxDecoration(
                              color: AppColors.amber.withValues(
                                alpha: 0.4 + _barHeights[i] * 0.6,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          if (i < _barHeights.length - 1) const SizedBox(width: 4),
                        ],
                      ],
                    ),
                  )
                else
                  const SizedBox(height: 48),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _status,
                          key: ValueKey(_status),
                          style: AppText.labelMd.copyWith(
                            color: _parsed ? AppColors.amber : AppColors.amber.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_showKeyboard)
                        TextField(
                          controller: _controller,
                          autofocus: true,
                          style: AppText.h2.copyWith(fontSize: 22),
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Type expense...',
                          ),
                          onSubmitted: (_) => _parseFromText(),
                        )
                      else
                        Text(
                          _controller.text.isEmpty
                              ? '"Tap the mic and say your expense..."'
                              : '"${_controller.text}"',
                          style: AppText.h2.copyWith(
                            fontSize: 20,
                            color: AppColors.t1,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: canConfirm ? _confirm : (_isProcessing || _isListening ? null : _parseFromText),
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: Text(
                  widget.prefillOnly ? 'APPLY TO FORM' : 'DONE',
                  style: const TextStyle(letterSpacing: 1.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  foregroundColor: AppColors.onAmber,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                  textStyle: AppText.label.copyWith(fontSize: 14),
                  shadowColor: AppColors.amber.withValues(alpha: 0.3),
                  elevation: 4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
