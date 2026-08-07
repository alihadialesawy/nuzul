# قواعد Proguard/R8 مخصصة للمشروع.

# flutter_stripe: نتجاهل تحذيرات الكلاسات الناقصة الخاصة بميزة
# "Push Provisioning" (إضافة بطاقة لمحفظة Google Pay تلقائيًا) —
# ميزة اختيارية مو مستخدمة بالمشروع، وتعتمد على مكتبة Google داخلية
# (play-services-tapandpay) مو متاحة عالميًا. بدون هالسطور، R8 يوقف
# البناء بالكامل بسبب "Missing classes detected".
-dontwarn com.stripe.android.pushProvisioning.**
-dontwarn com.reactnativestripesdk.pushprovisioning.**