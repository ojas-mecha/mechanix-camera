import 'package:flutter/material.dart';
import 'package:mechanix_camera/l10n/app_localizations.dart';

class AspectRatioBar extends StatelessWidget {
  const AspectRatioBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      width: double.infinity,
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => {},
            child: Text(AppLocalizations.of(context)!.aspectRatio11),
          ),
          TextButton(
            onPressed: () => {},
            child: Text(AppLocalizations.of(context)!.aspectRatio43),
          ),
          TextButton(
            onPressed: () => {},
            child: Text(AppLocalizations.of(context)!.aspectRatio169),
          ),
          TextButton(
            onPressed: () => {},
            child: Text(AppLocalizations.of(context)!.aspectRatioFull),
          ),
        ],
      ),
    );
  }
}
