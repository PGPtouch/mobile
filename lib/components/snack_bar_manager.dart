import 'package:material_graphics/material_graphics.dart';
import 'package:material_ui/material_ui.dart';

class SnackBarManager {
  SnackBarManager._();

  static void showSnackBar(
    BuildContext context,
    String message, [
    SnackBarAction? action,
  ]) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), behavior: .floating, action: action),
      snackBarAnimationStyle: AnimationStyle(
        curve: ExpressiveCurves.expressiveEffects.normal,
        reverseCurve: ExpressiveCurves.expressiveEffects.normal.flipped,
        duration: ExpressiveCurves.expressiveEffects.normalDuration,
      ),
    );
}
