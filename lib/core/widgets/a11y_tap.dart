import 'package:flutter/material.dart';

/// بديل GestureDetector للعناصر القابلة للضغط (أزرار مخصّصة، أشرطة، تبويبات).
///
/// لماذا؟ GestureDetector يستجيب للماوس/اللمس فقط:
///   • لا يصل إليه Tab (لوحة المفاتيح) ← مخالفة WCAG 2.1.1.
///   • لا يظهر إطار تركيز مرئي ← مخالفة WCAG 2.4.7.
///   • قارئ الشاشة لا يتوقف عنده عند التنقل بـ Tab.
///
/// A11yTap يضيف:
///   • قابلية التركيز بـ Tab، والتفعيل بـ Enter أو Space.
///   • إطار تركيز واضح عند التنقل بلوحة المفاتيح فقط (لا يظهر عند النقر بالماوس).
///   • دور "button" (أو "link") واسم لقارئ الشاشة (من النص الداخلي أو [semanticLabel]).
///
/// الاستخدام: استبدل `GestureDetector(` بـ `A11yTap(` (نفس key/behavior/onTap/child).
/// للعناصر التي محتواها أيقونة أو صورة فقط أعطِ [semanticLabel].
class A11yTap extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;
  final HitTestBehavior? behavior;

  /// اسم العنصر لقارئ الشاشة. إن تُرك فارغًا يُقرأ النص الموجود داخله.
  final String? semanticLabel;

  /// تجاهل نصوص المحتوى الداخلي، واستخدم [semanticLabel] فقط.
  final bool excludeSemantics;

  /// للتبويبات والخيارات: هل هذا العنصر هو المختار حاليًا؟
  final bool? selected;

  /// لأزرار التبديل (مثل الحفظ في المفضلة).
  final bool? toggled;

  /// يُقرأ "link" بدل "button".
  final bool isLink;

  /// استدارة إطار التركيز (طابقها مع شكل العنصر).
  final BorderRadius focusRadius;

  /// لون إطار التركيز.
  final Color focusColor;

  const A11yTap({
    super.key,
    required this.onTap,
    required this.child,
    this.behavior,
    this.semanticLabel,
    this.excludeSemantics = false,
    this.selected,
    this.toggled,
    this.isLink = false,
    this.focusRadius = const BorderRadius.all(Radius.circular(16)),
    this.focusColor = const Color(0xFFFFC107),
  });

  @override
  State<A11yTap> createState() => _A11yTapState();
}

class _A11yTapState extends State<A11yTap> {
  bool _showFocus = false;

  void _activate() => widget.onTap?.call();

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    Widget content = DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: _showFocus
          ? BoxDecoration(
        borderRadius: widget.focusRadius,
        border: Border.all(color: widget.focusColor, width: 3),
      )
          : const BoxDecoration(),
      child: widget.child,
    );

    content = GestureDetector(
      behavior: widget.behavior ?? HitTestBehavior.opaque,
      onTap: widget.onTap,
      // أفعال قارئ الشاشة تأتي من Semantics أدناه (لتفادي تكرار العنصر).
      excludeFromSemantics: true,
      child: content,
    );

    content = Semantics(
      button: !widget.isLink,
      link: widget.isLink,
      enabled: enabled,
      selected: widget.selected,
      toggled: widget.toggled,
      label: widget.semanticLabel,
      onTap: widget.onTap,
      excludeSemantics: widget.excludeSemantics,
      child: content,
    );

    content = FocusableActionDetector(
      enabled: enabled,
      mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onShowFocusHighlight: (v) {
        if (mounted && v != _showFocus) setState(() => _showFocus = v);
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
          _activate();
          return null;
        }),
        ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(onInvoke: (_) {
          _activate();
          return null;
        }),
      },
      child: content,
    );

    // دمج عقدة التركيز (focusable) مع عقدة الزر واسمه في عنصر واحد يقرؤه NVDA.
    return MergeSemantics(child: content);
  }
}