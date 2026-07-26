import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/database/transactional_database.dart';
import '../data/local_data_service.dart';

final Provider<LocalDataService> localDataServiceProvider =
    Provider<LocalDataService>((Ref ref) {
      final database = ref.watch(appDatabaseProvider);
      return LocalDataService(
        database is TransactionalDatabase
            ? database as TransactionalDatabase
            : null,
      );
    });
