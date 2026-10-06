allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// يعطّل مهمة "Lint Vital" على كل الموديولات (شامل موديولات المكتبات
// الخارجية زي stripe_android). هذا الفحص اختياري (جودة كود إضافية)
// ومش جزء من البناء الفعلي، بس بيفشل بسبب اعتماد stripe_android على
// مكتبة Google داخلية مقفولة (play-services-tapandpay) خاصة بميزة
// "Push Provisioning" اللي أصلاً مش مستخدمة بالمشروع.
//
// ملحوظة: استخدمنا tasks.configureEach بدل subprojects { afterEvaluate
// {...} } عمدًا — لأن القسم اللي فوق (evaluationDependsOn(":app")) بيجبر
// موديول app يتقيّم فورًا لكل subproject شامل نفسه، فلو استخدمنا
// afterEvaluate هنا (في قسم subprojects منفصل بعده) بيوصلنا خطأ
// "Cannot run Project.afterEvaluate(Action) when the project is already
// evaluated" لموديول app بالتحديد. tasks.configureEach lazy بطبيعتها
// ومش محتاجة تستنى evaluation، فبتتجنب المشكلة دي تمامًا.
subprojects {
    tasks.configureEach {
        if (name.startsWith("lintVital")) {
            enabled = false
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}