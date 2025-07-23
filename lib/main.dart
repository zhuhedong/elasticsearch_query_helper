import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/elasticsearch_provider.dart';
import 'screens/welcome_screen.dart';
import 'theme/app_theme.dart';
import 'utils/safe_transform_utils.dart';

void main() {
  // 设置全局错误处理
  FlutterError.onError = (FlutterErrorDetails details) {
    // 只忽略TransformLayer错误，记录其他错误
    final errorString = details.toString();
    if (errorString.contains('TransformLayer') && 
        errorString.contains('invalid matrix')) {
      // 静默忽略TransformLayer矩阵错误
      return;
    }
    // 记录其他错误
    FlutterError.presentError(details);
  };
  
  runApp(const ElasticsearchQueryHelperApp());
}

class ElasticsearchQueryHelperApp extends StatelessWidget {
  const ElasticsearchQueryHelperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ElasticsearchProvider(),
      child: UltraSafeWidget(
        child: MaterialApp(
          title: 'Elasticsearch Query Helper',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,  // 强制使用深色主题
          home: const WelcomeScreen(),
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            // 在整个应用程序周围添加额外的保护层
            return UltraSafeWidget(
              child: child ?? const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }
}