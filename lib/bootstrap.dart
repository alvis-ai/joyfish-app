import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/log/app_logger.dart';
import 'core/network/network_manager.dart';
import 'core/storage/storage_manager.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  AppLogger.init();
  AppLogger.info('乐鱼故事 app booting');

  try {
    await AppConfig.init();
    await Hive.initFlutter();
    await StorageManager.init();
    NetworkManager.init();

    runApp(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) => const App(),
        ),
      ),
    );
  } catch (e, stackTrace) {
    AppLogger.error('App bootstrap failed', error: e, stackTrace: stackTrace);
    rethrow;
  }
}
