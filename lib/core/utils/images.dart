import 'package:flutter/material.dart';

class Images extends StatelessWidget {
  final Size size;
  final String image;

  const Images({
    super.key,
    required this.image,
    this.size = const Size(24, 24),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size.height,
      width: size.width,
      child: Image.asset(image),
    );
  }
}
