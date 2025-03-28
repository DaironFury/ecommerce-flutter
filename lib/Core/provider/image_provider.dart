import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/image_services.dart';

final imageServiceProvider = Provider<ImageService>((ref) => ImageService());