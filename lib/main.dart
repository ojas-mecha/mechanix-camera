import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_camera/core/utils/app_routes.dart';
import 'package:mechanix_camera/features/camera/bloc/camera_bloc.dart';
import 'package:mechanix_camera/features/camera/data/camera_repository_impl.dart';
import 'package:mechanix_camera/features/camera/presentation/screen/camera_screen.dart';
import 'package:show_fps/show_fps.dart';

void main() {
  runApp(const CameraApp());
}

class CameraApp extends StatelessWidget {
  const CameraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => CameraRepositoryImpl()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                CameraBloc(CameraRepositoryImpl())..add(CameraInitialized()),
          ),
        ],
        child: MaterialApp(
          title: 'Mechanix Camera',
          themeMode: ThemeMode.dark,
          darkTheme: ThemeData(
            colorScheme: .fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
          ),
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: .fromSeed(seedColor: Colors.deepPurple),
          ),
          routes: AppRoutes.routes,
          home: const CameraScreen(),
          builder: (context, child) =>
              ShowFPS(visible: kProfileMode, child: child!),
        ),
      ),
    );
  }
}
