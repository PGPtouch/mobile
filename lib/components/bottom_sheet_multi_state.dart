import 'package:material_graphics/material_graphics.dart';
import 'package:material_helper/material_helper.dart';
import 'package:material_ui/material_ui.dart';

class BottomSheetMultiState extends StatelessWidget {
  final Widget? child;
  const new({super.key, required this.child});

  static Widget Function(Widget, Animation<double>) transitionBuilder =
      (child, animation) {
        var widget = child;
        if (!animation.isForwardOrCompleted) {
          widget = SlideTransition(
            position: Tween(
              begin: Offset(0.0, 0.06),
              end: Offset.zero,
            ).animate(animation),
            child: Material(color: Colors.transparent, child: widget),
          );
        }
        return FadeTransition(opacity: animation, child: widget);
      };

  static Widget Function(Widget?, List<Widget>) layoutBuilder =
      (Widget? currentChild, List<Widget> previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: <Widget>[
            ...previousChildren.map(
              (child) => Positioned(left: 0, right: 0, top: 0, child: child),
            ),
            ?currentChild,
          ],
        );
      };

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    final curve = ExpressiveCurves.expressiveEffects.slow;
    final duration = ExpressiveCurves.expressiveEffects.slowDuration;

    final loadingState = SafeArea(
      key: ValueKey("_modeLoading"),
      child: SizedBox(
        height: size.height / 6,
        child: Center(
          child: MaterialLoadingIndicator(
            size: MaterialLoadingIndicatorSizes.large,
          ),
        ),
      ),
    );
    return PopScope(
      canPop: child != null,
      child: GestureDetector(
        onVerticalDragStart: child != null ? null : (_) {},
        child: SizedBox(
          width: double.infinity,
          child: AnimatedSize(
            curve: curve,
            duration: duration,
            alignment: Alignment.topCenter,
            clipBehavior: Clip.antiAlias,
            child: AnimatedSwitcher(
              switchInCurve: curve,
              switchOutCurve: curve.flipped,
              duration: duration,
              transitionBuilder: transitionBuilder,
              layoutBuilder: layoutBuilder,
              child: child ?? loadingState,
            ),
          ),
        ),
      ),
    );
  }
}
