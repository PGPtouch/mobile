import 'package:flutter/widgets.dart';
import 'package:material_graphics/material_graphics.dart';

class KeyedAnimatedList extends StatefulWidget {
  final List<Widget> children;
  const new({super.key, required this.children});

  @override
  State<KeyedAnimatedList> createState() => _KeyedAnimatedListState();
}

class _KeyedAnimatedListState extends State<KeyedAnimatedList> {
  final _list = GlobalKey<AnimatedListState>();
  final List<Key> _keys = [];

  @override
  void initState() {
    super.initState();
    _remapKeys();
  }

  void _remapKeys() {
    _keys.clear();
    for (final child in widget.children) {
      if (child.key == null) {
        throw ArgumentError(
          "All children of KeyedAnimatedList must have a key.",
        );
      } else if (_keys.contains(child.key)) {
        throw ArgumentError(
          "Duplicate key found in KeyedAnimatedList: ${child.key}",
        );
      }
      _keys.add(child.key!);
    }
  }

  @override
  void didUpdateWidget(covariant KeyedAnimatedList oldWidget) {
    final oldKeys = List.of(_keys);
    _remapKeys();

    for (final oldKey in oldKeys) {
      if (!_keys.contains(oldKey)) {
        final index = oldKeys.indexOf(oldKey);
        _list.currentState?.removeItem(
          index,
          (context, animation) =>
              _transitionBuilder(context, animation, oldWidget.children[index]),
          duration: ExpressiveCurves.expressiveEffects.normalDuration,
        );
      }
    }
    for (final newKey in _keys) {
      if (!oldKeys.contains(newKey)) {
        final index = _keys.indexOf(newKey);
        _list.currentState?.insertItem(
          index,
          duration: ExpressiveCurves.expressiveEffects.normalDuration,
        );
      }
    }

    super.didUpdateWidget(oldWidget);
  }

  Widget _transitionBuilder(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) => SizeTransition(
    sizeFactor: CurvedAnimation(
      parent: animation,
      curve: ExpressiveCurves.expressiveEffects.normal,
      reverseCurve: ExpressiveCurves.expressiveEffects.normal.flipped,
    ),
    alignment: .topCenter,
    child: child,
  );

  @override
  Widget build(BuildContext context) => AnimatedList(
    key: _list,
    initialItemCount: _keys.length,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: EdgeInsets.zero,
    itemBuilder: (context, index, animation) =>
        _transitionBuilder(context, animation, widget.children[index]),
  );
}
