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
subprojects {
    afterEvaluate {
        tasks.matching { it.name.startsWith("lintVital") }.configureEach {
            enabled = false
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}