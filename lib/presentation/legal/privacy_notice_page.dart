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

/// إشعار الخصوصية — FLYNOOM LLC.
///
/// ⚠️ مسودة مكتوبة لتطابق النظام الفعلي (Supabase، Stripe، HotelBeds، Duffel،
/// Resend)، لكنها ليست رأيًا قانونيًا. يجب أن يراجعها محامٍ قبل الإطلاق.
///
/// تحقق قبل النشر:
///   • البند 4: لا توجد أي أدوات إعلانية أو تتبع (Meta Pixel، Google Ads...).
///     إن أضفتها لاحقًا يجب تعديل البند 4 والبند 7.
///   • البند 11: الحذف من داخل التطبيق (أمان الحساب ← حذف الحساب، دالة delete-account)،
///     والبريد بديل. بريد حذف الحساب هو نفسه المسجّل في Google Play Console
///     (Data safety → Delete account URL)، ويجب أن يصل فعلًا (تحويل في Namecheap).
class PrivacyNoticePage extends StatelessWidget {
  const PrivacyNoticePage({super.key});

  static const String _lastUpdatedEn = 'October 23, 2026';
  static const String _lastUpdatedAr = '23 أكتوبر 2026';

  /// بريد الخصوصية وحذف الحساب. يجب أن يكون بريدًا يصل فعلًا.
  static const String _contactEmail = 'support@flynoom.com';

  static const List<_LegalSection> _sections = [
    _LegalSection(
      titleEn: '1. Introduction',
      titleAr: '1. مقدمة',
      bodyEn:
      'This Privacy Notice explains how FLYNOOM LLC, a Michigan limited liability company ("Flynoom", "we", "us"), collects, uses, shares, and protects personal information when you use the Flynoom website (flynoom.com) and the Flynoom mobile app, when available (the "Service"). Flynoom is an online travel agency: we help you search for and book hotel stays supplied by third parties. This notice should be read together with our Terms of Service.',
      bodyAr:
      'يوضح إشعار الخصوصية هذا كيف تجمع شركة FLYNOOM LLC، وهي شركة ذات مسؤولية محدودة مسجلة في ولاية ميشيغان ("Flynoom" أو "نحن")، المعلوماتِ الشخصية وتستخدمها وتشاركها وتحميها عند استخدامك لموقع Flynoom الإلكتروني (flynoom.com) وتطبيقها على الهاتف عند توفره ("الخدمة"). Flynoom وكالة سفر إلكترونية تساعدك على البحث عن إقامات فندقية تقدمها جهات أخرى وحجزها. يُقرأ هذا الإشعار مع شروط الخدمة لدينا.',
    ),
    _LegalSection(
      titleEn: '2. Information We Collect',
      titleAr: '2. المعلومات التي نجمعها',
      bodyEn:
      'Account information: your email address, name, phone number, and login details, or basic profile information from a sign-in provider you choose to use.\n\n'
          'Booking information: the lead guest\'s first and last name, email, and phone number; travel dates, destination, and room choices; the number of guests and the ages of any children (hotels require them); and any special requests.\n\n'
          'Payment information: card payments are entered directly into our payment processor, Stripe. We never receive or store your full card number. We keep limited records such as the amount, currency, payment status, and transaction identifiers.\n\n'
          'Usage and device information: search history, pages viewed, device and browser type, IP address, and technical logs. If you allow it, we use your approximate location to suggest nearby cities.\n\n'
          'Mobile app information: if you use our Android or iPhone app, we also receive the app version, your device\'s operating system, and crash and performance diagnostics that help us fix problems. The app asks for your permission before it uses device features such as location, and you can change these permissions at any time in your device settings. Apple and Google handle app downloads and updates under their own terms and privacy policies; we receive only general statistics from them, such as the number of downloads.\n\n'
          'Community content: posts, trip journals, comments, reviews, and photos you share in the Community, along with your public profile name and picture. Photos you upload may contain location data (for example, GPS information); please remove it before posting if you do not want to share it.\n\n'
          'Communications: messages you send us by email or WhatsApp, and records of emails we send to you.\n\n'
          'Group quote requests: if you ask for a group quote, the contact name, email address, phone number, destination, dates, number of rooms and guests, occasion, and any notes you give us.',
      bodyAr:
      'معلومات الحساب: بريدك الإلكتروني واسمك ورقم هاتفك وبيانات الدخول، أو معلومات الملف الأساسية من مزود تسجيل الدخول الذي تختار استخدامه.\n\n'
          'معلومات الحجز: الاسم الأول والأخير للنزيل الرئيسي وبريده الإلكتروني ورقم هاتفه؛ وتواريخ السفر والوجهة والغرف المختارة؛ وعدد النزلاء وأعمار الأطفال إن وُجدوا (تطلبها الفنادق)؛ وأي طلبات خاصة.\n\n'
          'معلومات الدفع: تُدخَل بيانات البطاقة مباشرة لدى معالج الدفع لدينا Stripe، ولا نستلم رقم بطاقتك الكامل ولا نخزنه أبدًا. نحتفظ بسجلات محدودة مثل المبلغ والعملة وحالة الدفع ومعرّفات المعاملة.\n\n'
          'معلومات الاستخدام والجهاز: سجل البحث، والصفحات التي تزورها، ونوع الجهاز والمتصفح، وعنوان IP، والسجلات التقنية. وإذا سمحت بذلك، نستخدم موقعك التقريبي لاقتراح المدن القريبة.\n\n'
          'معلومات تطبيق الهاتف: إذا استخدمت تطبيقنا على Android أو iPhone، نتلقى أيضًا إصدار التطبيق ونظام تشغيل جهازك وتقارير الأعطال والأداء التي تساعدنا على إصلاح المشاكل. يطلب التطبيق إذنك قبل استخدام ميزات الجهاز مثل الموقع، ويمكنك تغيير هذه الأذونات في أي وقت من إعدادات جهازك. تتولى Apple وGoogle تنزيل التطبيق وتحديثاته وفق شروطهما وسياسات الخصوصية الخاصة بهما، ولا نتلقى منهما إلا إحصاءات عامة مثل عدد مرات التنزيل.\n\n'
          'محتوى المجتمع: المنشورات ويوميات الرحلات والتعليقات والتقييمات والصور التي تشاركها في قسم المجتمع، إلى جانب اسمك وصورتك في ملفك العام. قد تحتوي الصور التي ترفعها على بيانات الموقع (مثل معلومات GPS)، فاحذفها قبل النشر إن كنت لا تريد مشاركتها.\n\n'
          'المراسلات: الرسائل التي ترسلها إلينا عبر البريد الإلكتروني أو واتساب، وسجلات الرسائل التي نرسلها إليك.\n\n'
          'طلبات عروض أسعار المجموعات: إذا طلبت عرض سعر لمجموعة، فنجمع اسم جهة الاتصال والبريد الإلكتروني ورقم الهاتف والوجهة والتواريخ وعدد الغرف والنزلاء والمناسبة وأي ملاحظات تقدمها.',
    ),
    _LegalSection(
      titleEn: '3. How We Use Information',
      titleAr: '3. كيف نستخدم المعلومات',
      bodyEn:
      'We use personal information to: create and manage your account; check prices and availability; make, confirm, and cancel bookings with Suppliers; authorize, capture, and refund payments; send booking confirmations, vouchers, cancellation notices, and other service messages; provide customer support; prevent fraud and keep the Service secure; comply with legal, tax, and accounting obligations; and fix problems and improve the Service. We send marketing emails only if you agree to receive them, and every marketing email includes a way to unsubscribe. Service messages about your bookings are not marketing and will still be sent. We do not send marketing messages by text message or WhatsApp unless you have expressly agreed to receive them.\n\n'
          'When you book, we also record that you accepted our Terms and confirmed your state of residence, together with the time, the version of the Terms, your IP address, and your browser type, and that you approved the final price and cancellation policy. We keep this record so we can show what you agreed to if there is a dispute or a payment chargeback.',
      bodyAr:
      'نستخدم المعلومات الشخصية من أجل: إنشاء حسابك وإدارته؛ والتحقق من الأسعار والتوفر؛ وإجراء الحجوزات وتأكيدها وإلغائها لدى المزوّدين؛ وحجز المبالغ وسحبها وردها؛ وإرسال تأكيدات الحجز والقسائم وإشعارات الإلغاء ورسائل الخدمة الأخرى؛ وتقديم دعم العملاء؛ ومنع الاحتيال والحفاظ على أمان الخدمة؛ والامتثال للالتزامات القانونية والضريبية والمحاسبية؛ وإصلاح المشكلات وتحسين الخدمة. لا نرسل رسائل تسويقية إلا إذا وافقت على استلامها، وكل رسالة تسويقية تتضمن طريقة لإلغاء الاشتراك. أما رسائل الخدمة المتعلقة بحجوزاتك فليست تسويقًا وستستمر في الوصول إليك. ولا نرسل رسائل تسويقية عبر الرسائل النصية أو واتساب إلا إذا وافقت صراحة على استلامها.\n\n'
          'وعند الحجز نسجّل أيضًا موافقتك على شروط الخدمة وتأكيدك لولاية إقامتك، مع الوقت ونسخة الشروط وعنوان IP ونوع المتصفح، وموافقتك على السعر النهائي وسياسة الإلغاء. نحتفظ بهذا السجل لنثبت ما وافقت عليه في حال حدوث نزاع أو اعتراض على الدفع لدى البنك.',
    ),
    _LegalSection(
      titleEn: '4. How We Share Information',
      titleAr: '4. كيف نشارك المعلومات',
      bodyEn:
      'To complete your booking, we must share booking information with the travel providers involved: HOTELBEDS (Hotelbeds Group, based in Spain) and the hotel you booked. These providers use your information under their own privacy policies.\n\n'
          'We also use service providers who process information on our behalf: Stripe (payments), Supabase (account login and database), Netlify (website hosting), Resend (sending booking emails), Google (services such as sign-in and maps, where used), and WhatsApp, operated by Meta, if you choose to message us there.\n\n'
          'Anything you post in the Community, together with your public profile name and picture, is visible to other users and may be visible to visitors who are not signed in. Please do not include booking references or other private details in public posts.\n\n'
          'We may disclose information when required by law or legal process, to protect the rights, safety, and property of our customers, Flynoom, or others, or as part of a merger, sale, or transfer of our business.\n\n'
          'We do not sell your personal information, and we do not share it for cross-context behavioral (targeted) advertising.',
      bodyAr:
      'لإتمام حجزك، يلزمنا مشاركة بيانات الحجز مع مزوّدي السفر المعنيين: مع HOTELBEDS (مجموعة Hotelbeds ومقرها إسبانيا) ومع الفندق الذي حجزته. يستخدم هؤلاء المزوّدون معلوماتك وفق سياسات الخصوصية الخاصة بهم.\n\n'
          'كما نستعين بمزوّدي خدمات يعالجون المعلومات نيابة عنا: Stripe (المدفوعات)، وSupabase (تسجيل الدخول وقاعدة البيانات)، وNetlify (استضافة الموقع)، وResend (إرسال رسائل الحجز)، وGoogle (خدمات مثل تسجيل الدخول والخرائط، حيثما تُستخدم)، وواتساب التابع لشركة Meta إذا اخترت مراسلتنا عبره.\n\n'
          'كل ما تنشره في قسم المجتمع، مع اسمك وصورتك في ملفك العام، يراه المستخدمون الآخرون، وقد يراه الزوار غير المسجلين. يُرجى عدم وضع أرقام الحجز أو أي تفاصيل خاصة في المنشورات العامة.\n\n'
          'قد نفصح عن المعلومات عندما يُلزمنا القانون أو إجراء قانوني بذلك، أو لحماية حقوق عملائنا أو Flynoom أو غيرهم وسلامتهم وممتلكاتهم، أو في إطار اندماج أو بيع أو نقل لأعمالنا.\n\n'
          'لا نبيع معلوماتك الشخصية، ولا نشاركها لأغراض الإعلانات الموجهة عبر المواقع والتطبيقات.',
    ),
    _LegalSection(
      titleEn: '5. Data Retention',
      titleAr: '5. الاحتفاظ بالبيانات',
      bodyEn:
      'We keep account information while your account is open. We keep booking and payment records for as long as needed to provide the Service, handle cancellations, refunds, and disputes, and meet legal, tax, and accounting requirements, which is generally up to seven years after the booking. Records of your acceptance of our Terms are kept together with the booking records. Technical logs are kept for a shorter period. When information is no longer needed, we delete or de-identify it.',
      bodyAr:
      'نحتفظ بمعلومات الحساب ما دام حسابك مفتوحًا. ونحتفظ بسجلات الحجز والدفع طوال المدة اللازمة لتقديم الخدمة ومعالجة الإلغاء والاسترداد والنزاعات والوفاء بالمتطلبات القانونية والضريبية والمحاسبية، وهي في الغالب حتى سبع سنوات بعد الحجز. ونحتفظ بسجل موافقتك على الشروط مع سجلات الحجز. أما السجلات التقنية فنحتفظ بها لمدة أقصر. وعندما لا نعود بحاجة إلى المعلومات، نحذفها أو نزيل ما يربطها بهويتك.',
    ),
    _LegalSection(
      titleEn: '6. Your Privacy Rights',
      titleAr: '6. حقوقك المتعلقة بالخصوصية',
      bodyEn:
      'Depending on the state where you live, you may have the right to: know what personal information we have about you and get a copy of it; correct inaccurate information; delete your information; and opt out of the sale of personal information, targeted advertising, or certain profiling (we do not do any of these). To make a request, email us at $_contactEmail from the email address on your account. We will verify your identity before acting, and we respond within the time required by law, generally 45 days. You may use an authorized agent where your state law allows. If we decline your request, you may appeal by replying to our decision with the subject "Privacy Appeal". We will not discriminate against you for exercising your rights.',
      bodyAr:
      'بحسب الولاية التي تقيم فيها، قد يحق لك: معرفة المعلومات الشخصية التي نحتفظ بها عنك والحصول على نسخة منها؛ وتصحيح المعلومات غير الدقيقة؛ وحذف معلوماتك؛ والاعتراض على بيع المعلومات الشخصية أو الإعلانات الموجهة أو أنواع معينة من التنميط (ونحن لا نقوم بأي منها). لتقديم طلب، راسلنا على $_contactEmail من البريد المسجل في حسابك. سنتحقق من هويتك قبل تنفيذ الطلب، ونرد خلال المدة التي يحددها القانون، وهي في الغالب 45 يومًا. يمكنك الاستعانة بوكيل مفوّض حيث يسمح قانون ولايتك بذلك. وإذا رفضنا طلبك، يمكنك الاعتراض بالرد على قرارنا مع كتابة "Privacy Appeal" في عنوان الرسالة. لن نميّز ضدك بسبب ممارستك لحقوقك.',
    ),
    _LegalSection(
      titleEn: '7. Cookies and Similar Technologies',
      titleAr: '7. ملفات تعريف الارتباط والتقنيات المشابهة',
      bodyEn:
      'Our website uses cookies and browser storage that are needed to keep you signed in, remember your language and currency, and make the Service work. We may also use basic analytics to understand how the Service is used. We do not use advertising cookies. You can clear or block cookies and site data in your browser settings, but you may then need to sign in again and some features may not work. Because we do not sell personal information or use it for targeted advertising, there is nothing to opt out of; if your browser sends a Global Privacy Control (GPC) signal, we honor it as a request to opt out.',
      bodyAr:
      'يستخدم موقعنا ملفات تعريف الارتباط (الكوكيز) والتخزين في المتصفح اللازمة لإبقائك مسجّل الدخول، وتذكّر لغتك وعملتك، وتشغيل الخدمة. وقد نستخدم أيضًا تحليلات أساسية لفهم كيفية استخدام الخدمة. لا نستخدم ملفات تعريف ارتباط إعلانية. يمكنك مسح الكوكيز وبيانات المواقع أو حظرها من إعدادات متصفحك، لكنك قد تحتاج حينها إلى تسجيل الدخول من جديد وقد لا تعمل بعض الميزات. ولأننا لا نبيع المعلومات الشخصية ولا نستخدمها للإعلانات الموجهة، فلا يوجد ما تعترض عليه؛ وإذا أرسل متصفحك إشارة التحكم العالمي في الخصوصية (GPC)، فإننا نحترمها كطلب اعتراض.',
    ),
    _LegalSection(
      titleEn: "8. Children's Privacy",
      titleAr: '8. خصوصية الأطفال',
      bodyEn:
      'You must be 18 or older to create an account or make a booking, and the Service is not directed to children. When an adult books travel that includes children, we collect the information about those children that the booking requires (such as their ages, which hotels require), provided by the adult making the booking. We do not knowingly collect personal information directly from children under 13. If you believe a child has given us personal information, please contact us and we will delete it.',
      bodyAr:
      'يجب أن يكون عمرك 18 عامًا أو أكثر لإنشاء حساب أو إجراء حجز، والخدمة غير موجهة للأطفال. عندما يحجز شخص بالغ رحلة تشمل أطفالًا، نجمع عن هؤلاء الأطفال المعلومات التي يتطلبها الحجز (مثل أعمارهم التي تطلبها الفنادق)، ويقدّمها البالغ الذي يجري الحجز. لا نجمع عن قصد معلومات شخصية مباشرة من أطفال دون 13 عامًا. إذا كنت تعتقد أن طفلًا قدّم لنا معلومات شخصية، فتواصل معنا وسنحذفها.',
    ),
    _LegalSection(
      titleEn: '9. International Transfers',
      titleAr: '9. نقل البيانات خارج بلدك',
      bodyEn:
      'Flynoom is based in the United States, and our service providers may process information in the United States and other countries. Hotel booking information is shared with HOTELBEDS in Spain and with the hotel in the country where it is located. Data protection laws in those countries may differ from those where you live.',
      bodyAr:
      'مقر Flynoom في الولايات المتحدة، وقد يعالج مزوّدو الخدمات لدينا المعلومات في الولايات المتحدة ودول أخرى. تُشارك بيانات حجز الفنادق مع HOTELBEDS في إسبانيا ومع الفندق في البلد الذي يقع فيه. وقد تختلف قوانين حماية البيانات في تلك الدول عن قوانين بلد إقامتك.',
    ),
    _LegalSection(
      titleEn: '10. Data Security',
      titleAr: '10. أمان البيانات',
      bodyEn:
      'We protect information with measures such as encrypted connections (HTTPS), access controls that limit each user to their own bookings, and restricted administrative access. Card data is handled by Stripe, which is certified to the PCI Data Security Standard. No system is completely secure, so we cannot guarantee absolute security. If we learn of a security incident that affects your personal information, we will notify you as required by law.',
      bodyAr:
      'نحمي المعلومات بإجراءات مثل الاتصالات المشفرة (HTTPS)، وضوابط وصول تحصر كل مستخدم في حجوزاته فقط، وتقييد الوصول الإداري. يتولى Stripe بيانات البطاقات، وهو معتمد وفق معيار أمان بيانات صناعة بطاقات الدفع (PCI DSS). لا يوجد نظام آمن تمامًا، لذا لا يمكننا ضمان أمان مطلق. وإذا علمنا بحادث أمني يمس معلوماتك الشخصية، فسنبلغك وفق ما يقتضيه القانون.',
    ),
    _LegalSection(
      titleEn: '11. How to Delete Your Account',
      titleAr: '11. كيف تحذف حسابك',
      bodyEn:
      'You can delete your Flynoom account at any time from within the app: go to Account, then Account security, and choose "Delete account". This immediately closes your account and deletes your saved travelers, favorites, price alerts, community posts, and the name and phone number on your profile. If you have an upcoming or in-progress booking, please cancel it or wait until your stay ends first. If you cannot use the app, you can instead email $_contactEmail from your registered email address with the subject "Account Deletion Request"; we will complete the request within 30 days. In both cases, we keep booking and payment records that we must retain by law (such as transaction and tax records), as described in Section 5. To delete specific data without closing your account, email the same address with the subject "Data Deletion Request".',
      bodyAr:
      'يمكنك حذف حسابك في Flynoom في أي وقت من داخل التطبيق: افتح "الحساب" ثم "أمان الحساب" واختر "حذف الحساب". يُغلق ذلك حسابك فورًا، ويحذف المسافرين المحفوظين والمفضلة وتنبيهات الأسعار ومنشورات المجتمع والاسم ورقم الهاتف في ملفك. إن كان لديك حجز قادم أو قيد التنفيذ، فيُرجى إلغاؤه أو الانتظار حتى انتهاء إقامتك أولًا. وإن لم تتمكن من استخدام التطبيق، فأرسل بريدًا إلى $_contactEmail من بريدك المسجّل مع كتابة "Account Deletion Request" في العنوان، وسننفّذ الطلب خلال 30 يومًا. وفي الحالتين نحتفظ بسجلات الحجز والدفع التي يُلزمنا القانون بالاحتفاظ بها (مثل سجلات المعاملات والسجلات الضريبية) كما في البند 5. ولحذف بيانات معينة دون إغلاق حسابك، راسل البريد نفسه مع كتابة "Data Deletion Request" في العنوان.',
    ),
    _LegalSection(
      titleEn: '12. Changes to This Notice',
      titleAr: '12. تعديلات على هذا الإشعار',
      bodyEn:
      'We may update this Privacy Notice from time to time. We will post the updated version with a new "Last updated" date and, for material changes, notify you by email or in the Service.',
      bodyAr:
      'قد نحدّث إشعار الخصوصية هذا من وقت لآخر. سننشر النسخة المحدّثة مع تاريخ "آخر تحديث" جديد، وفي حال التعديلات الجوهرية سنبلغك عبر البريد الإلكتروني أو داخل الخدمة.',
    ),
    _LegalSection(
      titleEn: '13. Contact Us',
      titleAr: '13. تواصل معنا',
      bodyEn:
      'FLYNOOM LLC, Michigan, USA. For privacy questions or requests, email $_contactEmail. If there is any conflict between language versions of this notice, the English version controls.',
      bodyAr:
      'شركة FLYNOOM LLC، ميشيغان، الولايات المتحدة. لأسئلة الخصوصية أو الطلبات المتعلقة بها، راسلنا على $_contactEmail. وفي حال وجود أي تعارض بين النسخ اللغوية لهذا الإشعار، تكون النسخة الإنجليزية هي المعتمدة.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'إشعار الخصوصية' : 'Privacy Notice'),
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
                    isArabic ? 'إشعار الخصوصية' : 'Privacy Notice',
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