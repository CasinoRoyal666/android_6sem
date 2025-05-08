// Репозитории для всех проектов
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Настройка кастомной директории сборки
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

// Зависимости для подпроектов
subprojects {
    project.evaluationDependsOn(":app")
}

// Задача очистки
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Настройка buildscript для плагинов
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Используем Kotlin DSL синтаксис для Google Services
        classpath("com.google.gms:google-services:4.4.2")
    }
}