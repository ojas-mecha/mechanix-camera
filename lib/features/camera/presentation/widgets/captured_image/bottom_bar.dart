import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_camera/features/camera/bloc/camera_bloc.dart';

class BottomBar extends StatelessWidget {
  const BottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8, top: 8),
      child: Row(
        spacing: 2,
        children: [
          IconButton(
            onPressed: () {
              context.read<CameraBloc>().add(CloseImagePreview());
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back_sharp),
          ),
        ],
      ),
    );
  }
}
