import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/local_store.dart';

final currentUserProvider = StateProvider<LitUser?>(
    (ref) => LocalStore.instance.loadCurrentUser() ?? mockUsers[0]);
