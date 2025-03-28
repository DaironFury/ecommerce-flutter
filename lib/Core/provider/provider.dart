import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_services.dart';
import '../services/firestore_services.dart';
import '../services/api_services.dart';

final authServicesProvider = Provider<AuthServices>((ref) => AuthServices());
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());