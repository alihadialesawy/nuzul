/// إصدارات الشروط وإشعار الخصوصية التي يوافق عليها العميل وقت الحجز.
///
/// ⚠️ عند تعديل شروط الخدمة أو إشعار الخصوصية وتغيير تاريخ "آخر تحديث"
/// في terms_of_service_page.dart أو privacy_notice_page.dart، غيّر الرقم
/// هنا بنفس التاريخ (YYYY-MM-DD). يُحفظ مع كل حجز في جدول booking_consents،
/// فنعرف بالضبط أي نسخة وافق عليها العميل.
const String kTermsVersion = '2026-10-12';
const String kPrivacyVersion = '2026-10-12';