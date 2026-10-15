import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../engine/inference_engine.dart';
import '../engine/parser_output_dto.dart';

final inferenceEngineProvider = Provider((ref) => InferenceEngine());

final inferenceStateProvider = StateNotifierProvider<InferenceNotifier, ParserOutputDTO>((ref) {
  return InferenceNotifier(ref.read(inferenceEngineProvider));
});

class InferenceNotifier extends StateNotifier<ParserOutputDTO> {
  final InferenceEngine _engine;
  Timer? _debounceTimer;

  InferenceNotifier(this._engine) : super(ParserOutputDTO.empty());

  void onInputChanged(String input) {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final result = await _engine.parse(input);
      state = result;
    });
  }

  void clear() {
    state = ParserOutputDTO.empty();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
