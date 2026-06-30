import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';

final storageProvider = Provider<StorageService>((ref) => StorageService());

final apiProvider =
    Provider<ApiService>((ref) => ApiService(ref.read(storageProvider)));

final audioServiceProvider =
    Provider<AudioService>((ref) => AudioService(ref.read(apiProvider)));
