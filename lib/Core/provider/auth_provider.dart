import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_services.dart';

final authServicesProvider = Provider<AuthServices>((ref) => AuthServices());