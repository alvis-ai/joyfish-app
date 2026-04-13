import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../common/themes/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../auth/providers/session_providers.dart';

@RoutePage()
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionControllerProvider.notifier).bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SessionState>(sessionControllerProvider, (previous, next) {
      if (!next.initialized || _navigated) {
        return;
      }
      _navigated = true;
      if (next.isAuthenticated) {
        context.router.replace(const MainShellRoute());
      } else {
        context.router.replace(const AuthRoute());
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE4F6FF), AppTheme.cream],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120.w,
                  height: 120.w,
                  padding: EdgeInsets.all(18.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(36.r),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A3B82F6),
                        blurRadius: 28,
                        offset: Offset(0, 14),
                      ),
                    ],
                  ),
                  child: SvgPicture.asset('assets/images/home_hero.svg'),
                ),
                SizedBox(height: 28.h),
                Text(
                  'Joyfish',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                SizedBox(height: 10.h),
                Text(
                  '为孩子准备一则温柔的睡前故事',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.mutedInk,
                      ),
                ),
                SizedBox(height: 28.h),
                SizedBox(
                  width: 28.w,
                  height: 28.w,
                  child: const CircularProgressIndicator(strokeWidth: 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
