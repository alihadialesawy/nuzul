import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

class _LegalSection {
  final String titleEn;
  final String titleAr;
  final String bodyEn;
  final String bodyAr;
  const _LegalSection({
    required this.titleEn,
    required this.titleAr,
    required this.bodyEn,
    required this.bodyAr,
  });
}

/// شروط الخدمة — FLYNOOM LLC.
///
/// ⚠️ مسودة مكتوبة لتطابق نظام الحجز الفعلي، لكنها ليست رأيًا قانونيًا.
/// يجب أن يراجعها محامٍ مرخّص في ميشيغان قبل الإطلاق، وخاصة البنود:
///   • 3  (الولايات غير المخدومة / Seller of Travel)
///   • 10 (رحلات الطيران وقواعد وزارة النقل DOT للاسترداد)
///   • 15 (إخلاء المسؤولية) و 16 (حدود المسؤولية) و 17 (التعويض)
///   • 18 (حل النزاعات) و 19 (القانون الحاكم)
///
/// النسخة الإنجليزية هي المعتمدة (البند 22). أي لغة غير العربية تعرض الإنجليزية.
class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  static const String _lastUpdatedEn = 'October 12, 2026';
  static const String _lastUpdatedAr = '12 أكتوبر 2026';

  /// بريد خدمة العملاء (موحّد في كل الصفحات القانونية). يجب أن يصل فعلًا.
  static const String _contactEmail = 'support@flynoom.com';

  static const List<_LegalSection> _sections = [
    _LegalSection(
      titleEn: '1. Who We Are and Acceptance of These Terms',
      titleAr: '1. من نحن وقبول هذه الشروط',
      bodyEn:
      'The Flynoom website (flynoom.com) and mobile application (together, the "Service") are operated by FLYNOOM LLC, a Michigan limited liability company ("Flynoom", "we", "us", "our"). These Terms of Service ("Terms") govern your use of the Service and every booking you make through it. By creating an account, searching, or making a booking, you agree to these Terms, to our Privacy Notice, and to the supplier terms shown to you before you pay. If you do not agree, please do not use the Service.',
      bodyAr:
      'يدير موقع Flynoom الإلكتروني (flynoom.com) وتطبيقها على الهاتف (ويُشار إليهما معًا بـ "الخدمة") شركةُ FLYNOOM LLC، وهي شركة ذات مسؤولية محدودة مسجلة في ولاية ميشيغان ("Flynoom" أو "نحن"). تحكم شروط الخدمة هذه ("الشروط") استخدامك للخدمة وكل حجز تجريه من خلالها. بإنشائك حسابًا أو بحثك أو إجرائك حجزًا، فإنك توافق على هذه الشروط، وعلى إشعار الخصوصية لدينا، وعلى شروط المزوّد التي تُعرض عليك قبل الدفع. إذا كنت لا توافق، فيُرجى عدم استخدام الخدمة.',
    ),
    _LegalSection(
      titleEn: '2. Our Role: We Are a Booking Agent',
      titleAr: '2. دورنا: نحن وكيل حجز',
      bodyEn:
      'Flynoom is an online travel agency. We do not own or operate any hotel, airline, or other travel service. We sell travel services supplied by third parties ("Suppliers"). Hotel accommodations are sourced through HOTELBEDS and its affiliates, which act as agent for the hotel operating company. The hotel is responsible for providing the stay itself. We do not currently sell air transportation. In addition to these Terms, each booking is subject to the Supplier\'s own terms, rate rules, fare rules, and conditions of carriage, which are shown or referenced before you pay.',
      bodyAr:
      'Flynoom وكالة سفر إلكترونية. لا نمتلك ولا نشغّل أي فندق أو شركة طيران أو خدمة سفر أخرى، وإنما نبيع خدمات سفر تقدمها جهات أخرى ("المزوّدون"). نحصل على الإقامات الفندقية عبر شركة HOTELBEDS والشركات التابعة لها، والتي تعمل وكيلًا عن الشركة المشغّلة للفندق. والفندق هو المسؤول عن تقديم الإقامة نفسها. ولا نبيع حاليًا أي نقل جوي. وإلى جانب هذه الشروط، يخضع كل حجز لشروط المزوّد الخاصة به، وقواعد السعر أو التذكرة، وشروط النقل، والتي تُعرض أو يُشار إليها قبل الدفع.',
    ),
    _LegalSection(
      titleEn: '3. Eligibility and Where We Operate',
      titleAr: '3. الأهلية ونطاق عملنا',
      bodyEn:
      'You must be at least 18 years old and able to form a binding contract to create an account or make a booking. You are responsible for keeping your login details secure and for all activity under your account. The Service is intended for customers in the United States. At this time, we do not accept bookings from residents of California, Florida, Hawaii, or Washington. By booking, you confirm that you are not a resident of any of these states. We may update this list as our registrations change.',
      bodyAr:
      'يجب أن يكون عمرك 18 عامًا على الأقل وأن تكون قادرًا على إبرام عقد ملزم لإنشاء حساب أو إجراء حجز. أنت مسؤول عن الحفاظ على سرية بيانات دخولك وعن كل نشاط يتم عبر حسابك. الخدمة موجهة للعملاء داخل الولايات المتحدة. ولا نقبل حاليًا حجوزات من المقيمين في ولايات كاليفورنيا وفلوريدا وهاواي وواشنطن. بإجرائك الحجز، فإنك تؤكد أنك لست مقيمًا في أي من هذه الولايات. قد نحدّث هذه القائمة بحسب تغيّر تسجيلاتنا.',
    ),
    _LegalSection(
      titleEn: '4. Prices, Currency, and Fees',
      titleAr: '4. الأسعار والعملة والرسوم',
      bodyEn:
      'All prices on the Service are in U.S. dollars (USD). Prices come from our Suppliers in real time and may change until your booking is confirmed. Before you pay, we re-check the price with the Supplier; if it has changed, we show you the new price and you can decide whether to continue. The amount you pay online includes our compensation and the taxes we collect; we do not add a separate booking fee unless it is clearly shown before you pay. Some hotels charge mandatory fees that must be paid directly at the property (for example, resort fees, destination fees, or local taxes). When a Supplier tells us about these fees, we include them in the total price we display and list them separately as "Payable at the hotel". These fees are collected by the hotel, usually in local currency, and the final amount is set by the hotel. Optional charges such as parking, deposits for incidentals, or minibar items are not included.',
      bodyAr:
      'جميع الأسعار في الخدمة بالدولار الأمريكي (USD). تصلنا الأسعار من المزوّدين لحظيًا وقد تتغيّر حتى يتأكد حجزك. قبل الدفع، نعيد التحقق من السعر لدى المزوّد؛ فإن تغيّر نعرض عليك السعر الجديد ولك أن تقرر المتابعة أو لا. المبلغ الذي تدفعه عبر الإنترنت يشمل أجرنا والضرائب التي نحصّلها، ولا نضيف رسوم حجز منفصلة إلا إذا عُرضت عليك بوضوح قبل الدفع. بعض الفنادق تفرض رسومًا إلزامية تُدفع مباشرة في الفندق (مثل رسوم المنتجع أو رسوم الوجهة أو الضرائب المحلية). عندما يُبلغنا المزوّد بهذه الرسوم، ندرجها في السعر الإجمالي المعروض ونذكرها منفصلة تحت بند "تُدفع في الفندق". يحصّل الفندق هذه الرسوم، عادةً بالعملة المحلية، والمبلغ النهائي يحدده الفندق. ولا يشمل السعر الرسوم الاختيارية مثل مواقف السيارات أو تأمين المصاريف الجانبية أو الميني بار.',
    ),
    _LegalSection(
      titleEn: '5. Payment',
      titleAr: '5. الدفع',
      bodyEn:
      'Payments are processed by our payment processor, Stripe. Flynoom never stores your full card number. When you submit a booking, we place an authorization (a temporary hold) on your card for the amount shown. We capture (charge) that amount only after the Supplier confirms your booking. If the Supplier declines the booking, we release the hold and you are not charged; your bank decides how quickly the hold disappears from your statement. In rare cases where we cannot immediately confirm the outcome with the Supplier, we may keep the hold in place while we verify the booking, and we will contact you. Your card issuer may apply its own fees, which are outside our control.',
      bodyAr:
      'تُعالَج المدفوعات عبر معالج الدفع لدينا Stripe، ولا تخزّن Flynoom رقم بطاقتك الكامل أبدًا. عند إرسالك الحجز، نضع تفويضًا (حجزًا مؤقتًا للمبلغ) على بطاقتك بالقيمة المعروضة، ولا نسحب المبلغ فعليًا إلا بعد أن يؤكد المزوّد حجزك. إذا رفض المزوّد الحجز، نُلغي الحجز المؤقت ولا يُخصم منك شيء؛ ويحدد بنكك سرعة اختفاء الحجز المؤقت من كشف حسابك. في حالات نادرة لا نستطيع فيها التأكد فورًا من نتيجة الحجز لدى المزوّد، قد نُبقي الحجز المؤقت قائمًا ريثما نتحقق، وسنتواصل معك. قد يفرض البنك المُصدر لبطاقتك رسومًا خاصة به لا سيطرة لنا عليها.',
    ),
    _LegalSection(
      titleEn: '6. Booking Confirmation and Guest Information',
      titleAr: '6. تأكيد الحجز وبيانات النزلاء',
      bodyEn:
      'Your booking is confirmed only when we show you, and email you, a confirmation with a booking reference. Please keep your voucher and show it, or your booking reference, at check-in. You must provide accurate information: the lead guest\'s name must match the government-issued ID that will be presented at check-in, and the email address must be one you can access. We are not responsible for problems caused by incorrect information you provide. Hotels set their own check-in requirements, which may include a minimum check-in age (sometimes 21), photo ID, and a credit card for incidentals.',
      bodyAr:
      'لا يُعد حجزك مؤكدًا إلا عندما نعرض لك ونرسل إلى بريدك تأكيدًا يتضمن رقم الحجز. يُرجى الاحتفاظ بالقسيمة وإبرازها، أو إبراز رقم الحجز، عند تسجيل الوصول. يجب أن تقدم معلومات صحيحة: اسم النزيل الرئيسي يجب أن يطابق بطاقة الهوية الرسمية التي ستُقدَّم عند الوصول، والبريد الإلكتروني يجب أن يكون بريدًا تستطيع الوصول إليه. لسنا مسؤولين عن المشكلات الناتجة عن معلومات غير صحيحة تقدمها. تحدد الفنادق متطلبات تسجيل الوصول الخاصة بها، والتي قد تشمل حدًا أدنى للعمر (أحيانًا 21 عامًا)، وهوية تحمل صورة، وبطاقة ائتمان للمصاريف الجانبية.',
    ),
    _LegalSection(
      titleEn: '7. Hotel Cancellations and Refunds',
      titleAr: '7. إلغاء حجوزات الفنادق والاسترداد',
      bodyEn:
      'Each hotel rate has its own cancellation policy, which is shown before you pay and included in your confirmation. Cancellation deadlines are stated in the hotel\'s local time. If you cancel before the free-cancellation deadline, you receive a full refund of the amount you paid online. If you cancel after a deadline, the cancellation fee shown in the policy applies and we refund the remaining balance, if any. Non-refundable rates cannot be refunded. You can cancel eligible bookings from "My Bookings"; before you confirm, we show you the exact fee and refund. Refunds are issued to the original payment card, and they usually appear within 5 to 10 business days, depending on your bank. Fees paid directly at the hotel are handled by the hotel.',
      bodyAr:
      'لكل سعر فندقي سياسة إلغاء خاصة به تُعرض قبل الدفع وتُدرج في تأكيد حجزك. مواعيد الإلغاء محددة بالتوقيت المحلي للفندق. إذا ألغيت قبل انتهاء موعد الإلغاء المجاني، تسترد كامل المبلغ الذي دفعته عبر الإنترنت. وإذا ألغيت بعد أحد المواعيد، تُطبَّق رسوم الإلغاء المبيّنة في السياسة ونردّ لك المبلغ المتبقي إن وُجد. الأسعار غير القابلة للاسترداد لا يُرد مبلغها. يمكنك إلغاء الحجوزات المؤهلة من صفحة "حجوزاتي"، وقبل أن تؤكد الإلغاء نعرض لك الرسوم والمبلغ المسترد بالضبط. يُرد المبلغ إلى البطاقة الأصلية التي دفعت بها، ويظهر عادةً خلال 5 إلى 10 أيام عمل بحسب بنكك. أما الرسوم المدفوعة مباشرة في الفندق فيتولاها الفندق.',
    ),
    _LegalSection(
      titleEn: '8. No-Shows, Early Departures, and Changes',
      titleAr: '8. عدم الحضور والمغادرة المبكرة والتعديلات',
      bodyEn:
      'If you do not arrive at the hotel without cancelling (a "no-show"), the hotel may treat the booking as cancelled after the deadline, and you will generally not receive a refund. If you plan to arrive late, please contact the hotel directly to keep your room. Unused nights after an early departure are generally not refundable. Bookings cannot currently be changed online; to change dates, rooms, or guests, you must cancel under the applicable policy and make a new booking at the current price.',
      bodyAr:
      'إذا لم تصل إلى الفندق دون أن تلغي الحجز ("عدم الحضور")، فقد يعامل الفندق الحجز كأنه أُلغي بعد انتهاء المهلة، ولن تسترد في الغالب أي مبلغ. إذا كنت تتوقع الوصول متأخرًا، فيُرجى التواصل مع الفندق مباشرة للاحتفاظ بغرفتك. الليالي غير المستخدمة بسبب المغادرة المبكرة لا تُسترد في الغالب. لا يمكن حاليًا تعديل الحجوزات عبر الإنترنت؛ فلتغيير التواريخ أو الغرف أو النزلاء يجب إلغاء الحجز وفق السياسة المطبقة ثم إجراء حجز جديد بالسعر الحالي.',
    ),
    _LegalSection(
      titleEn: '9. Problems During Your Stay',
      titleAr: '9. المشكلات أثناء الإقامة',
      bodyEn:
      'If something is wrong when you arrive or during your stay, please raise it with the hotel immediately so it can be fixed on the spot, and contact us as soon as possible with your booking reference. We will work with the Supplier on your behalf. Complaints raised after check-out without notice to the hotel may be harder for us to resolve.',
      bodyAr:
      'إذا وجدت مشكلة عند وصولك أو أثناء إقامتك، فيُرجى إبلاغ الفندق فورًا ليتمكن من إصلاحها في حينها، والتواصل معنا في أقرب وقت مع ذكر رقم حجزك، وسنتابع الأمر مع المزوّد نيابة عنك. الشكاوى التي تُقدَّم بعد المغادرة دون إبلاغ الفندق قد يصعب علينا حلها.',
    ),
    _LegalSection(
      titleEn: '10. Flights',
      titleAr: '10. رحلات الطيران',
      bodyEn:
      'When flight booking is available on the Service, the airline\'s fare rules and conditions of carriage apply to your ticket, including rules on changes, cancellations, baggage, and seating. Fares are shown as the full price including all mandatory taxes and fees. Baggage and other optional fees are set by the airline and disclosed before purchase where available. If an airline cancels or significantly changes your flight, you may be entitled to a refund under U.S. Department of Transportation rules, and we will process refunds we are required to provide. Schedule changes, delays, check-in, and boarding are controlled by the airline.',
      bodyAr:
      'عند توفر حجز رحلات الطيران في الخدمة، تُطبَّق على تذكرتك قواعد التذكرة وشروط النقل الخاصة بشركة الطيران، بما في ذلك قواعد التعديل والإلغاء والأمتعة والمقاعد. تُعرض أسعار التذاكر بالسعر الكامل شاملًا كل الضرائب والرسوم الإلزامية. تحدد شركة الطيران رسوم الأمتعة والرسوم الاختيارية الأخرى، ونعرضها قبل الشراء متى توفرت. إذا ألغت شركة الطيران رحلتك أو غيّرتها تغييرًا جوهريًا، فقد يحق لك استرداد المبلغ بموجب قواعد وزارة النقل الأمريكية، وسنعالج المبالغ التي يُلزمنا القانون بردها. تتحكم شركة الطيران في تغييرات المواعيد والتأخير وتسجيل الوصول والصعود إلى الطائرة.',
    ),
    _LegalSection(
      titleEn: '11. Travel Documents, Health, and Insurance',
      titleAr: '11. وثائق السفر والصحة والتأمين',
      bodyEn:
      'You are responsible for having valid travel documents, such as a passport, visa, REAL ID-compliant identification, or travel authorization, and for meeting any entry or health requirements. We do not sell travel insurance; we recommend that you consider purchasing it independently to protect against cancellations, medical costs, and other risks.',
      bodyAr:
      'أنت مسؤول عن امتلاك وثائق سفر سارية، مثل جواز السفر أو التأشيرة أو بطاقة هوية متوافقة مع REAL ID أو تصريح السفر، وعن استيفاء أي متطلبات دخول أو متطلبات صحية. لا نبيع تأمين السفر، وننصحك بالتفكير في شرائه بشكل مستقل للحماية من الإلغاء والتكاليف الطبية وغيرها من المخاطر.',
    ),
    _LegalSection(
      titleEn: '12. Errors, Fraud, and Our Right to Cancel',
      titleAr: '12. الأخطاء والاحتيال وحقنا في الإلغاء',
      bodyEn:
      'We work hard to show accurate information, but errors can occur. If a booking was made at an obviously incorrect price because of a technical or Supplier error, we may cancel it and refund everything you paid, or offer you the booking at the correct price. We may also decline or cancel a booking, with a full refund, if we reasonably suspect fraud, misuse of a payment card, or a violation of these Terms.',
      bodyAr:
      'نحرص على عرض معلومات دقيقة، لكن الأخطاء قد تحدث. إذا تم حجز بسعر خاطئ بشكل واضح بسبب خطأ تقني أو خطأ من المزوّد، فقد نلغي الحجز ونرد لك كل ما دفعته، أو نعرض عليك الحجز بالسعر الصحيح. ويجوز لنا أيضًا رفض حجز أو إلغاؤه، مع رد كامل المبلغ، إذا اشتبهنا بشكل معقول في احتيال أو إساءة استخدام لبطاقة دفع أو مخالفة لهذه الشروط.',
    ),
    _LegalSection(
      titleEn: '13. Acceptable Use',
      titleAr: '13. الاستخدام المقبول',
      bodyEn:
      'You agree not to make speculative, false, or fraudulent bookings; book for resale; scrape, copy, or reverse-engineer the Service; use automated tools to access it; interfere with its operation or security; impersonate another person; or break any law. If you have a payment concern, please contact us before disputing a charge with your bank so we can try to resolve it quickly. We may suspend or close accounts that violate this section.',
      bodyAr:
      'توافق على عدم إجراء حجوزات وهمية أو كاذبة أو احتيالية، أو الحجز بغرض إعادة البيع، أو استخراج بيانات الخدمة أو نسخها أو إعادة هندستها، أو استخدام أدوات آلية للوصول إليها، أو التدخل في تشغيلها أو أمنها، أو انتحال شخصية غيرك، أو مخالفة أي قانون. إذا كان لديك اعتراض على مبلغ مدفوع، فيُرجى التواصل معنا قبل الاعتراض عليه لدى بنكك لنحاول حله بسرعة. يجوز لنا تعليق الحسابات التي تخالف هذا البند أو إغلاقها.',
    ),
    _LegalSection(
      titleEn: '14. Intellectual Property, Your Content, and Third-Party Content',
      titleAr: '14. الملكية الفكرية ومحتواك ومحتوى الأطراف الأخرى',
      bodyEn:
      'The Service, including its design, text, graphics, logos, and software, is owned by FLYNOOM LLC or its licensors and is protected by law. You may not copy, modify, or distribute it without our written permission. Hotel photos, descriptions, and flight details are provided by Suppliers and their licensors and remain their property. We are not responsible for the content of third-party websites linked from the Service.\n\n'
          'Your content: you keep ownership of the posts, trip journals, comments, reviews, and photos you share in the Community or elsewhere on the Service ("Your Content"). By posting Your Content, you give FLYNOOM LLC a non-exclusive, worldwide, royalty-free license to host, store, display, reproduce, adapt (for example, resize or translate), and distribute it in connection with operating and promoting the Service. This license ends when you delete Your Content or your account, except for copies already shared by others or kept in backups for a limited time. You confirm that you have the rights to everything you post and that it follows our Content Guidelines, which form part of these Terms. Content posted by other users reflects their own views, not Flynoom\'s. We do not review all content before it is posted, but we may remove any content that breaks these Terms or our Content Guidelines.',
      bodyAr:
      'الخدمة، بما في ذلك تصميمها ونصوصها ورسومها وشعاراتها وبرمجياتها، مملوكة لشركة FLYNOOM LLC أو للجهات المرخِّصة لها ومحمية بالقانون. لا يجوز لك نسخها أو تعديلها أو توزيعها دون إذن كتابي منا. صور الفنادق وأوصافها وتفاصيل الرحلات يقدمها المزوّدون والجهات المرخِّصة لهم وتبقى ملكًا لهم. لسنا مسؤولين عن محتوى مواقع الأطراف الأخرى المرتبطة من خلال الخدمة.\n\n'
          'محتواك: تبقى مالكًا للمنشورات ويوميات الرحلات والتعليقات والتقييمات والصور التي تشاركها في قسم المجتمع أو في أي مكان آخر من الخدمة ("محتواك"). وبنشرك لمحتواك، تمنح شركة FLYNOOM LLC ترخيصًا غير حصري وعالميًا ودون مقابل لاستضافته وتخزينه وعرضه ونسخه وتكييفه (مثل تغيير حجم الصور أو ترجمة النص) وتوزيعه في إطار تشغيل الخدمة والترويج لها. وينتهي هذا الترخيص عند حذفك لمحتواك أو لحسابك، باستثناء النسخ التي شاركها آخرون أو المحفوظة في النسخ الاحتياطية لفترة محدودة. وتؤكد أنك تملك حقوق كل ما تنشره وأنه يلتزم بإرشادات المحتوى لدينا، والتي تُعد جزءًا من هذه الشروط. المحتوى الذي ينشره المستخدمون الآخرون يعبّر عن آرائهم لا عن رأي Flynoom. لا نراجع كل المحتوى قبل نشره، لكن يجوز لنا حذف أي محتوى يخالف هذه الشروط أو إرشادات المحتوى.',
    ),
    _LegalSection(
      titleEn: '15. Disclaimers',
      titleAr: '15. إخلاء المسؤولية',
      bodyEn:
      'The Service is provided "as is" and "as available". To the extent permitted by law, we disclaim all implied warranties, including merchantability, fitness for a particular purpose, and non-infringement. Hotel ratings, descriptions, photos, and amenities are supplied by third parties and are for general guidance only. Flynoom is not responsible for the acts, errors, omissions, or failures of hotels, airlines, or other Suppliers, including overbooking, strikes, or changes to services they provide.',
      bodyAr:
      'تُقدَّم الخدمة "كما هي" و"حسب توفرها". وإلى الحد الذي يسمح به القانون، نخلي مسؤوليتنا عن جميع الضمانات الضمنية، بما في ذلك ضمان قابلية التسويق والملاءمة لغرض معين وعدم التعدي. تصنيفات الفنادق وأوصافها وصورها ومرافقها مقدمة من أطراف أخرى وهي للاسترشاد العام فقط. Flynoom غير مسؤولة عن أفعال أو أخطاء أو تقصير أو إخفاق الفنادق أو شركات الطيران أو المزوّدين الآخرين، بما في ذلك الحجز الزائد أو الإضرابات أو التغييرات في الخدمات التي يقدمونها.',
    ),
    _LegalSection(
      titleEn: '16. Limitation of Liability',
      titleAr: '16. حدود المسؤولية',
      bodyEn:
      'To the fullest extent permitted by law, Flynoom will not be liable for any indirect, incidental, special, consequential, or punitive damages, or for lost profits, data, or enjoyment, arising from your use of the Service or any booking. Flynoom\'s total liability for any claim relating to a booking is limited to the total amount you paid to Flynoom for that booking. Some states do not allow certain limitations, so some of these limitations may not apply to you. Nothing in these Terms limits any rights you have that cannot be waived under applicable consumer protection law.',
      bodyAr:
      'إلى أقصى حد يسمح به القانون، لن تكون Flynoom مسؤولة عن أي أضرار غير مباشرة أو عرضية أو خاصة أو تبعية أو عقابية، أو عن خسارة الأرباح أو البيانات أو المتعة، الناشئة عن استخدامك للخدمة أو عن أي حجز. وتقتصر مسؤولية Flynoom الإجمالية عن أي مطالبة تتعلق بحجز ما على إجمالي المبلغ الذي دفعته لـ Flynoom مقابل ذلك الحجز. بعض الولايات لا تسمح ببعض هذه القيود، لذا قد لا ينطبق بعضها عليك. ولا يحدّ أي شيء في هذه الشروط من حقوقك التي لا يجوز التنازل عنها بموجب قوانين حماية المستهلك المعمول بها.',
    ),
    _LegalSection(
      titleEn: '17. Indemnification',
      titleAr: '17. التعويض',
      bodyEn:
      'You agree to indemnify and hold harmless FLYNOOM LLC and its members, employees, and agents from claims, losses, and expenses (including reasonable attorneys\' fees) arising from your violation of these Terms, your misuse of the Service, or your violation of any law or the rights of a third party.',
      bodyAr:
      'توافق على تعويض شركة FLYNOOM LLC وأعضائها وموظفيها ووكلائها وإبراء ذمتهم من أي مطالبات أو خسائر أو نفقات (بما في ذلك أتعاب المحاماة المعقولة) تنشأ عن مخالفتك لهذه الشروط، أو إساءة استخدامك للخدمة، أو مخالفتك لأي قانون أو لحقوق طرف آخر.',
    ),
    _LegalSection(
      titleEn: '18. Dispute Resolution',
      titleAr: '18. حل النزاعات',
      bodyEn:
      'Most concerns can be resolved quickly by contacting us. If we cannot resolve a dispute informally, the procedures described on our Dispute Resolution page apply, and that page forms part of these Terms.',
      bodyAr:
      'يمكن حل معظم المشكلات بسرعة بالتواصل معنا. وإذا تعذّر حل النزاع وديًا، تُطبَّق الإجراءات الموضحة في صفحة حل النزاعات لدينا، وتُعد تلك الصفحة جزءًا من هذه الشروط.',
    ),
    _LegalSection(
      titleEn: '19. Governing Law',
      titleAr: '19. القانون الحاكم',
      bodyEn:
      'These Terms are governed by the laws of the State of Michigan and applicable U.S. federal law, without regard to conflict-of-law rules, except where the consumer protection law of your state of residence requires otherwise.',
      bodyAr:
      'تخضع هذه الشروط لقوانين ولاية ميشيغان والقوانين الفيدرالية الأمريكية المعمول بها، بغض النظر عن قواعد تنازع القوانين، إلا حيثما يقتضي قانون حماية المستهلك في ولاية إقامتك خلاف ذلك.',
    ),
    _LegalSection(
      titleEn: '20. Events Beyond Our Control',
      titleAr: '20. الظروف الخارجة عن إرادتنا',
      bodyEn:
      'We are not responsible for failures or delays caused by events beyond our reasonable control, such as natural disasters, severe weather, epidemics, government actions, war, strikes, or failures of internet, payment, or Supplier systems. In such cases, Supplier policies and applicable law determine whether a refund is available, and we will help you request it.',
      bodyAr:
      'لسنا مسؤولين عن أي إخفاق أو تأخير ناتج عن ظروف خارجة عن سيطرتنا المعقولة، مثل الكوارث الطبيعية أو الأحوال الجوية القاسية أو الأوبئة أو الإجراءات الحكومية أو الحروب أو الإضرابات أو أعطال الإنترنت أو أنظمة الدفع أو أنظمة المزوّدين. وفي هذه الحالات، تحدد سياسات المزوّد والقانون المعمول به إمكانية الاسترداد، وسنساعدك في طلبه.',
    ),
    _LegalSection(
      titleEn: '21. Changes to These Terms and Account Closure',
      titleAr: '21. تعديل هذه الشروط وإغلاق الحساب',
      bodyEn:
      'We may update these Terms from time to time. We will post the updated version with a new "Last updated" date and, for material changes, notify you by email or in the Service. Each booking is governed by the Terms in effect when it was made. You may close your account at any time by contacting us; closing your account does not cancel existing bookings.',
      bodyAr:
      'قد نحدّث هذه الشروط من وقت لآخر. سننشر النسخة المحدّثة مع تاريخ "آخر تحديث" جديد، وفي حال التعديلات الجوهرية سنبلغك عبر البريد الإلكتروني أو داخل الخدمة. يخضع كل حجز للشروط السارية وقت إجرائه. يمكنك إغلاق حسابك في أي وقت بالتواصل معنا، علمًا بأن إغلاق الحساب لا يلغي الحجوزات القائمة.',
    ),
    _LegalSection(
      titleEn: '22. General',
      titleAr: '22. أحكام عامة',
      bodyEn:
      'If any part of these Terms is found unenforceable, the rest remains in effect. Our failure to enforce a provision is not a waiver. You may not transfer your rights under these Terms without our consent. These Terms may be provided in more than one language; if there is any conflict, the English version controls.',
      bodyAr:
      'إذا ثبت أن أي جزء من هذه الشروط غير قابل للتنفيذ، يبقى الباقي ساريًا. وعدم تطبيقنا لأي بند لا يُعد تنازلًا عنه. لا يجوز لك نقل حقوقك بموجب هذه الشروط دون موافقتنا. قد تُقدَّم هذه الشروط بأكثر من لغة، وفي حال وجود أي تعارض تكون النسخة الإنجليزية هي المعتمدة.',
    ),
    _LegalSection(
      titleEn: '23. Contact Us',
      titleAr: '23. التواصل معنا',
      bodyEn:
      'FLYNOOM LLC, Michigan, USA. Email: $_contactEmail. Please include your booking reference when contacting us about a booking.',
      bodyAr:
      'شركة FLYNOOM LLC، ميشيغان، الولايات المتحدة. البريد الإلكتروني: $_contactEmail. يُرجى ذكر رقم الحجز عند التواصل معنا بخصوص أي حجز.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'شروط الخدمة' : 'Terms of Service'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    isArabic ? 'شروط الخدمة' : 'Terms of Service',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isArabic ? 'آخر تحديث: $_lastUpdatedAr' : 'Last updated: $_lastUpdatedEn',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                if (isArabic) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'هذه ترجمة للتيسير، والنسخة الإنجليزية هي المعتمدة عند أي تعارض.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
                const SizedBox(height: AppSizes.lg),
                for (final s in _sections) ...[
                  Semantics(
                    header: true,
                    child: Text(
                      isArabic ? s.titleAr : s.titleEn,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    isArabic ? s.bodyAr : s.bodyEn,
                    style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSizes.lg),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}