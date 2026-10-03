import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

/// يزوّد حساسية السحب باللمس/الماوس (drag) على الويب.
class FastScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}

/// يعترض حدث عجلة الماوس (mouse wheel) ويكبّر قيمته يدويًا، عشان
/// السكرول على الويب يحس بنفس سرعة نسخة الـ Desktop تقريبًا. يلف أي
/// ListView/SingleChildScrollView ويمنع الـ scroll الافتراضي بتاعه
/// (physics: NeverScrollableScrollPhysics على الـ child) عشان
/// ميتضاعفش التمرير مرتين.
class FastWheelScroll extends StatelessWidget {
  final ScrollController controller;
  final Widget child;
  final double multiplier;

  const FastWheelScroll({
    super.key,
    required this.controller,
    required this.child,
    this.multiplier = 3.5,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent && controller.hasClients) {
          debugPrint('WHEEL EVENT: delta=${event.scrollDelta.dy}, offset=${controller.offset}');
          final newOffset = (controller.offset + event.scrollDelta.dy * multiplier)
              .clamp(0.0, controller.position.maxScrollExtent);
          controller.jumpTo(newOffset);
        }
      },
      child: child,
    );
  }
}