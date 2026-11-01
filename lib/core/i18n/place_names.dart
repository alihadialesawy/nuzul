import 'package:flutter/widgets.dart';

/// ترجمة أسماء المدن والدول للعرض فقط.
///
/// ⚠️ للعرض فقط: ما يُرسل للبحث (HotelBeds) يبقى الاسم الإنجليزي/الرمز كما هو.
/// الاستخدام: `PlaceNames.of(context, 'Venice')` → "البندقية" / "Venecia" / "Venedik"...
/// أي اسم غير موجود هنا يُعرض كما هو بالإنجليزية (لا يتعطل شيء).
/// لإضافة مدينة: سطر واحد بالترتيب [ar, es, tr, id, hi, ur, fr, bn].
class PlaceNames {
  PlaceNames._();

  static const _order = ['ar', 'es', 'tr', 'id', 'hi', 'ur', 'fr', 'bn'];

  static String of(BuildContext context, String english) {
    final code = Localizations.localeOf(context).languageCode;
    return translate(english, code);
  }

  static String translate(String english, String languageCode) {
    final i = _order.indexOf(languageCode);
    if (i < 0) return english;
    final row = _names[english.trim()];
    return row == null ? english : row[i];
  }

  static const Map<String, List<String>> _names = {
    // ── الدول ──
    'Australia': ['أستراليا', 'Australia', 'Avustralya', 'Australia', 'ऑस्ट्रेलिया', 'آسٹریلیا', 'Australie', 'অস্ট্রেলিয়া'],
    'Austria': ['النمسا', 'Austria', 'Avusturya', 'Austria', 'ऑस्ट्रिया', 'آسٹریا', 'Autriche', 'অস্ট্রিয়া'],
    'Bahamas': ['جزر البهاما', 'Bahamas', 'Bahamalar', 'Bahama', 'बहामास', 'بہاماس', 'Bahamas', 'বাহামা'],
    'Canada': ['كندا', 'Canadá', 'Kanada', 'Kanada', 'कनाडा', 'کینیڈا', 'Canada', 'কানাডা'],
    'China': ['الصين', 'China', 'Çin', 'Tiongkok', 'चीन', 'چین', 'Chine', 'চীন'],
    'Egypt': ['مصر', 'Egipto', 'Mısır', 'Mesir', 'मिस्र', 'مصر', 'Égypte', 'মিশর'],
    'France': ['فرنسا', 'Francia', 'Fransa', 'Prancis', 'फ़्रांस', 'فرانس', 'France', 'ফ্রান্স'],
    'French Polynesia': ['بولينيزيا الفرنسية', 'Polinesia Francesa', 'Fransız Polinezyası', 'Polinesia Prancis', 'फ़्रेंच पोलिनेशिया', 'فرانسیسی پولینیشیا', 'Polynésie française', 'ফরাসি পলিনেশিয়া'],
    'Germany': ['ألمانيا', 'Alemania', 'Almanya', 'Jerman', 'जर्मनी', 'جرمنی', 'Allemagne', 'জার্মানি'],
    'Greece': ['اليونان', 'Grecia', 'Yunanistan', 'Yunani', 'ग्रीस', 'یونان', 'Grèce', 'গ্রিস'],
    'India': ['الهند', 'India', 'Hindistan', 'India', 'भारत', 'بھارت', 'Inde', 'ভারত'],
    'Indonesia': ['إندونيسيا', 'Indonesia', 'Endonezya', 'Indonesia', 'इंडोनेशिया', 'انڈونیشیا', 'Indonésie', 'ইন্দোনেশিয়া'],
    'Italy': ['إيطاليا', 'Italia', 'İtalya', 'Italia', 'इटली', 'اٹلی', 'Italie', 'ইতালি'],
    'Japan': ['اليابان', 'Japón', 'Japonya', 'Jepang', 'जापान', 'جاپان', 'Japon', 'জাপান'],
    'Jordan': ['الأردن', 'Jordania', 'Ürdün', 'Yordania', 'जॉर्डन', 'اردن', 'Jordanie', 'জর্ডান'],
    'Malaysia': ['ماليزيا', 'Malasia', 'Malezya', 'Malaysia', 'मलेशिया', 'ملائیشیا', 'Malaisie', 'মালয়েশিয়া'],
    'Maldives': ['جزر المالديف', 'Maldivas', 'Maldivler', 'Maladewa', 'मालदीव', 'مالدیپ', 'Maldives', 'মালদ্বীপ'],
    'Mexico': ['المكسيك', 'México', 'Meksika', 'Meksiko', 'मेक्सिको', 'میکسیکو', 'Mexique', 'মেক্সিকো'],
    'Morocco': ['المغرب', 'Marruecos', 'Fas', 'Maroko', 'मोरक्को', 'مراکش', 'Maroc', 'মরক্কো'],
    'Netherlands': ['هولندا', 'Países Bajos', 'Hollanda', 'Belanda', 'नीदरलैंड्स', 'نیدرلینڈز', 'Pays-Bas', 'নেদারল্যান্ডস'],
    'New Zealand': ['نيوزيلندا', 'Nueva Zelanda', 'Yeni Zelanda', 'Selandia Baru', 'न्यूज़ीलैंड', 'نیوزی لینڈ', 'Nouvelle-Zélande', 'নিউজিল্যান্ড'],
    'Portugal': ['البرتغال', 'Portugal', 'Portekiz', 'Portugal', 'पुर्तगाल', 'پرتگال', 'Portugal', 'পর্তুগাল'],
    'Puerto Rico': ['بورتوريكو', 'Puerto Rico', 'Porto Riko', 'Puerto Riko', 'प्यूर्टो रिको', 'پورٹو ریکو', 'Porto Rico', 'পুয়ের্তো রিকো'],
    'Saudi Arabia': ['السعودية', 'Arabia Saudita', 'Suudi Arabistan', 'Arab Saudi', 'सऊदी अरब', 'سعودی عرب', 'Arabie saoudite', 'সৌদি আরব'],
    'Singapore': ['سنغافورة', 'Singapur', 'Singapur', 'Singapura', 'सिंगापुर', 'سنگاپور', 'Singapour', 'সিঙ্গাপুর'],
    'Spain': ['إسبانيا', 'España', 'İspanya', 'Spanyol', 'स्पेन', 'اسپین', 'Espagne', 'স্পেন'],
    'Switzerland': ['سويسرا', 'Suiza', 'İsviçre', 'Swiss', 'स्विट्ज़रलैंड', 'سوئٹزرلینڈ', 'Suisse', 'সুইজারল্যান্ড'],
    'Thailand': ['تايلاند', 'Tailandia', 'Tayland', 'Thailand', 'थाईलैंड', 'تھائی لینڈ', 'Thaïlande', 'থাইল্যান্ড'],
    'Turkey': ['تركيا', 'Turquía', 'Türkiye', 'Turki', 'तुर्की', 'ترکی', 'Turquie', 'তুরস্ক'],
    'Türkiye': ['تركيا', 'Turquía', 'Türkiye', 'Turki', 'तुर्की', 'ترکی', 'Turquie', 'তুরস্ক'],
    'UAE': ['الإمارات', 'EAU', 'BAE', 'UEA', 'यूएई', 'متحدہ عرب امارات', 'EAU', 'সংযুক্ত আরব আমিরাত'],
    'United Arab Emirates': ['الإمارات العربية المتحدة', 'Emiratos Árabes Unidos', 'Birleşik Arap Emirlikleri', 'Uni Emirat Arab', 'संयुक्त अरब अमीरात', 'متحدہ عرب امارات', 'Émirats arabes unis', 'সংযুক্ত আরব আমিরাত'],
    'UK': ['المملكة المتحدة', 'Reino Unido', 'Birleşik Krallık', 'Inggris', 'यूनाइटेड किंगडम', 'برطانیہ', 'Royaume-Uni', 'যুক্তরাজ্য'],
    'United Kingdom': ['المملكة المتحدة', 'Reino Unido', 'Birleşik Krallık', 'Inggris', 'यूनाइटेड किंगडम', 'برطانیہ', 'Royaume-Uni', 'যুক্তরাজ্য'],
    'USA': ['الولايات المتحدة', 'EE. UU.', 'ABD', 'AS', 'अमेरिका', 'امریکہ', 'États-Unis', 'যুক্তরাষ্ট্র'],
    'United States': ['الولايات المتحدة', 'Estados Unidos', 'Amerika Birleşik Devletleri', 'Amerika Serikat', 'संयुक्त राज्य अमेरिका', 'ریاستہائے متحدہ', 'États-Unis', 'মার্কিন যুক্তরাষ্ট্র'],

    // ── المدن والمناطق ──
    'Agra': ['أغرا', 'Agra', 'Agra', 'Agra', 'आगरा', 'آگرہ', 'Agra', 'আগ্রা'],
    'Amsterdam': ['أمستردام', 'Ámsterdam', 'Amsterdam', 'Amsterdam', 'एम्स्टर्डम', 'ایمسٹرڈیم', 'Amsterdam', 'আমস্টারডাম'],
    'Antalya': ['أنطاليا', 'Antalya', 'Antalya', 'Antalya', 'अंताल्या', 'انطالیہ', 'Antalya', 'আন্তালিয়া'],
    'Aspen': ['أسبن', 'Aspen', 'Aspen', 'Aspen', 'एस्पेन', 'ایسپن', 'Aspen', 'অ্যাসপেন'],
    'Athens': ['أثينا', 'Atenas', 'Atina', 'Athena', 'एथेंस', 'ایتھنز', 'Athènes', 'এথেন্স'],
    'Bali': ['بالي', 'Bali', 'Bali', 'Bali', 'बाली', 'بالی', 'Bali', 'বালি'],
    'Barcelona': ['برشلونة', 'Barcelona', 'Barselona', 'Barcelona', 'बार्सिलोना', 'بارسلونا', 'Barcelone', 'বার্সেলোনা'],
    'Beijing': ['بكين', 'Pekín', 'Pekin', 'Beijing', 'बीजिंग', 'بیجنگ', 'Pékin', 'বেইজিং'],
    'Bora Bora': ['بورا بورا', 'Bora Bora', 'Bora Bora', 'Bora Bora', 'बोरा बोरा', 'بورا بورا', 'Bora-Bora', 'বোরা বোরা'],
    'Cairo': ['القاهرة', 'El Cairo', 'Kahire', 'Kairo', 'काहिरा', 'قاہرہ', 'Le Caire', 'কায়রো'],
    'Cancun': ['كانكون', 'Cancún', 'Cancún', 'Cancun', 'कैनकन', 'کینکون', 'Cancún', 'ক্যানকুন'],
    'Chamonix': ['شاموني', 'Chamonix', 'Chamonix', 'Chamonix', 'शैमॉनिक्स', 'شامونی', 'Chamonix', 'শ্যামোনি'],
    'Condado': ['كوندادو', 'Condado', 'Condado', 'Condado', 'कोंडाडो', 'کونڈاڈو', 'Condado', 'কন্ডাডো'],
    'Coronet Peak': ['قمة كورونيت', 'Coronet Peak', 'Coronet Peak', 'Coronet Peak', 'कोरोनेट पीक', 'کورونیٹ پیک', 'Coronet Peak', 'করোনেট পিক'],
    'Dolomiti': ['جبال الدولوميت', 'Dolomitas', 'Dolomitler', 'Dolomit', 'डोलोमाइट्स', 'ڈولومائٹس', 'Dolomites', 'ডলোমাইটস'],
    'Dubai': ['دبي', 'Dubái', 'Dubai', 'Dubai', 'दुबई', 'دبئی', 'Dubaï', 'দুবাই'],
    'Hawaii': ['هاواي', 'Hawái', 'Hawaii', 'Hawaii', 'हवाई', 'ہوائی', 'Hawaï', 'হাওয়াই'],
    'Istanbul': ['إسطنبول', 'Estambul', 'İstanbul', 'Istanbul', 'इस्तांबुल', 'استنبول', 'Istanbul', 'ইস্তাম্বুল'],
    'Kitzbühel': ['كيتسبوهل', 'Kitzbühel', 'Kitzbühel', 'Kitzbühel', 'कित्ज़बुहेल', 'کٹزبوہل', 'Kitzbühel', 'কিৎসবুয়েল'],
    'Kyoto': ['كيوتو', 'Kioto', 'Kyoto', 'Kyoto', 'क्योटो', 'کیوٹو', 'Kyoto', 'কিয়োটো'],
    'Lisbon': ['لشبونة', 'Lisboa', 'Lizbon', 'Lisboa', 'लिस्बन', 'لزبن', 'Lisbonne', 'লিসবন'],
    'London': ['لندن', 'Londres', 'Londra', 'London', 'लंदन', 'لندن', 'Londres', 'লন্ডন'],
    'Los Angeles': ['لوس أنجلوس', 'Los Ángeles', 'Los Angeles', 'Los Angeles', 'लॉस एंजिल्स', 'لاس اینجلس', 'Los Angeles', 'লস অ্যাঞ্জেলেস'],
    'Madinah': ['المدينة المنورة', 'Medina', 'Medine', 'Madinah', 'मदीना', 'مدینہ منورہ', 'Médine', 'মদিনা'],
    'Makkah': ['مكة المكرمة', 'La Meca', 'Mekke', 'Makkah', 'मक्का', 'مکہ مکرمہ', 'La Mecque', 'মক্কা'],
    'Marrakech': ['مراكش', 'Marrakech', 'Marakeş', 'Marrakesh', 'मराकेश', 'مراکش', 'Marrakech', 'মারাকেশ'],
    'Nice': ['نيس', 'Niza', 'Nice', 'Nice', 'नीस', 'نیس', 'Nice', 'নিস'],
    'Niseko': ['نيسيكو', 'Niseko', 'Niseko', 'Niseko', 'निसेको', 'نیسیکو', 'Niseko', 'নিসেকো'],
    'Orlando': ['أورلاندو', 'Orlando', 'Orlando', 'Orlando', 'ऑरलैंडो', 'اورلینڈو', 'Orlando', 'অরল্যান্ডো'],
    'Palma de Mallorca': ['بالما دي مايوركا', 'Palma de Mallorca', 'Palma de Mallorca', 'Palma de Mallorca', 'पाल्मा डे मायोर्का', 'پالما دے مایورکا', 'Palma de Majorque', 'পালমা দে মায়োরকা'],
    'Paris': ['باريس', 'París', 'Paris', 'Paris', 'पेरिस', 'پیرس', 'Paris', 'প্যারিস'],
    'Phuket': ['بوكيت', 'Phuket', 'Phuket', 'Phuket', 'फुकेत', 'پھوکٹ', 'Phuket', 'ফুকেট'],
    'Rome': ['روما', 'Roma', 'Roma', 'Roma', 'रोम', 'روم', 'Rome', 'রোম'],
    'St. Moritz': ['سانت موريتز', 'St. Moritz', 'St. Moritz', 'St. Moritz', 'सेंट मोरिट्ज़', 'سینٹ مورٹز', 'Saint-Moritz', 'সেন্ট মরিৎস'],
    'Sydney': ['سيدني', 'Sídney', 'Sidney', 'Sydney', 'सिडनी', 'سڈنی', 'Sydney', 'সিডনি'],
    'Tokyo': ['طوكيو', 'Tokio', 'Tokyo', 'Tokyo', 'टोक्यो', 'ٹوکیو', 'Tokyo', 'টোকিও'],
    'Vail': ['فيل', 'Vail', 'Vail', 'Vail', 'वेल', 'ویل', 'Vail', 'ভেইল'],
    'Bangkok': ['بانكوك', 'Bangkok', 'Bangkok', 'Bangkok', 'बैंकॉक', 'بینکاک', 'Bangkok', 'ব্যাংকক'],
    'Bodrum': ['بودروم', 'Bodrum', 'Bodrum', 'Bodrum', 'बोडरम', 'بودرم', 'Bodrum', 'বোদরুম'],
    'Cappadocia': ['كابادوكيا', 'Capadocia', 'Kapadokya', 'Kapadokia', 'कप्पाडोसिया', 'کیپاڈوشیا', 'Cappadoce', 'ক্যাপাডোসিয়া'],
    'Chicago': ['شيكاغو', 'Chicago', 'Chicago', 'Chicago', 'शिकागो', 'شکاگو', 'Chicago', 'শিকাগো'],
    'Chiang Mai': ['شيانغ ماي', 'Chiang Mai', 'Chiang Mai', 'Chiang Mai', 'चियांग माई', 'چیانگ مائی', 'Chiang Mai', 'চিয়াং মাই'],
    'Chinatown': ['الحي الصيني', 'Barrio chino', 'Çin Mahallesi', 'Pecinan', 'चाइनाटाउन', 'چائنا ٹاؤن', 'Quartier chinois', 'চায়নাটাউন'],
    'Hakone': ['هاكوني', 'Hakone', 'Hakone', 'Hakone', 'हाकोने', 'ہاکونے', 'Hakone', 'হাকোনে'],
    'Hiroshima': ['هيروشيما', 'Hiroshima', 'Hiroşima', 'Hiroshima', 'हिरोशिमा', 'ہیروشیما', 'Hiroshima', 'হিরোশিমা'],
    'Izmir': ['إزمير', 'Esmirna', 'İzmir', 'Izmir', 'इज़मिर', 'ازمیر', 'Izmir', 'ইজমির'],
    'Jakarta': ['جاكرتا', 'Yakarta', 'Cakarta', 'Jakarta', 'जकार्ता', 'جکارتہ', 'Jakarta', 'জাকার্তা'],
    'Kampong Glam': ['كامبونغ غلام', 'Kampong Glam', 'Kampong Glam', 'Kampong Glam', 'कम्पोंग ग्लैम', 'کامپونگ گلام', 'Kampong Glam', 'কাম্পং গ্লাম'],
    'Koh Samui': ['كوه ساموي', 'Koh Samui', 'Koh Samui', 'Koh Samui', 'को समुई', 'کوہ سموئی', 'Koh Samui', 'কো সামুই'],
    'Krabi': ['كرابي', 'Krabi', 'Krabi', 'Krabi', 'क्राबी', 'کرابی', 'Krabi', 'ক্রাবি'],
    'Las Vegas': ['لاس فيغاس', 'Las Vegas', 'Las Vegas', 'Las Vegas', 'लास वेगास', 'لاس ویگاس', 'Las Vegas', 'লাস ভেগাস'],
    'Little India': ['الحي الهندي', 'Little India', 'Küçük Hindistan', 'Little India', 'लिटिल इंडिया', 'لٹل انڈیا', 'Little India', 'লিটল ইন্ডিয়া'],
    'Lombok': ['لومبوك', 'Lombok', 'Lombok', 'Lombok', 'लोम्बोक', 'لومبوک', 'Lombok', 'লম্বক'],
    'Marina Bay': ['مارينا باي', 'Marina Bay', 'Marina Bay', 'Marina Bay', 'मरीना बे', 'مرینا بے', 'Marina Bay', 'মেরিনা বে'],
    'Miami': ['ميامي', 'Miami', 'Miami', 'Miami', 'मियामी', 'میامی', 'Miami', 'মায়ামি'],
    'Nara': ['نارا', 'Nara', 'Nara', 'Nara', 'नारा', 'نارا', 'Nara', 'নারা'],
    'New York': ['نيويورك', 'Nueva York', 'New York', 'New York', 'न्यूयॉर्क', 'نیویارک', 'New York', 'নিউ ইয়র্ক'],
    'Orchard Road': ['شارع أوركارد', 'Orchard Road', 'Orchard Road', 'Orchard Road', 'ऑर्चर्ड रोड', 'آرچرڈ روڈ', 'Orchard Road', 'অর্চার্ড রোড'],
    'Osaka': ['أوساكا', 'Osaka', 'Osaka', 'Osaka', 'ओसाका', 'اوساکا', 'Osaka', 'ওসাকা'],
    'Pattaya': ['باتايا', 'Pattaya', 'Pattaya', 'Pattaya', 'पटाया', 'پٹایا', 'Pattaya', 'পাতায়া'],
    'San Francisco': ['سان فرانسيسكو', 'San Francisco', 'San Francisco', 'San Francisco', 'सैन फ़्रांसिस्को', 'سان فرانسسکو', 'San Francisco', 'সান ফ্রান্সিসকো'],
    'Sentosa': ['سنتوسا', 'Sentosa', 'Sentosa', 'Sentosa', 'सेंटोसा', 'سینٹوسا', 'Sentosa', 'সেন্টোসা'],
    'Trabzon': ['طرابزون', 'Trebisonda', 'Trabzon', 'Trabzon', 'त्राबज़ोन', 'طرابزون', 'Trébizonde', 'ত্রাবজোন'],
    'Venice': ['البندقية', 'Venecia', 'Venedik', 'Venesia', 'वेनिस', 'وینس', 'Venise', 'ভেনিস'],
    'Washington, D.C.': ['واشنطن العاصمة', 'Washington D. C.', 'Washington, D.C.', 'Washington, D.C.', 'वॉशिंगटन, डी.सी.', 'واشنگٹن ڈی سی', 'Washington', 'ওয়াশিংটন, ডি.সি.'],
    'Whistler': ['ويسلر', 'Whistler', 'Whistler', 'Whistler', 'व्हिस्लर', 'وسلر', 'Whistler', 'হুইসলার'],
  };
}