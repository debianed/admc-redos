# admc-redos
Центр управления Active Directory (Active Directory Management Center, ADMC) — это
комплексный интегрированный инструмент, реализующий модули «Пользователи и компьютеры» и
«Диспетчер групповой политики» из пакета Microsoft Remote Server Administration Tools (RSAT).

Скрипт автоматической соборки ADMC 0.23.1 (https://github.com/altlinux/admc) для Ред ОС 8, собранные пакеты

# Сборка rpm-пакета ADMC для Ред ОС

1. Устанавливаем необходимые зависимости
```bash
sudo dnf install curl mock mock-core-configs rpmdevtools rpm-build systemd-container unzip tar
```

2. Добавляем пользователя в группу mock и применяем изменения без перезагрузки
```bash
sudo usermod -aG mock "$(whoami)"
su - "$(whoami)"
```

3. Создаем какой-либо рабочий каталог и помещаем в него файлы, необходимые для сборки:
- admc_build_red80.sh (скрипт автоматической сборки пакета в mock)
- admc-red80.spec (спецификация)
- admc-master-1.red80.patch (патчи, применяемые к оригинальному исходному коду для сборки под Ред ОС)

4. Для автоматической сборки запускаем скрипт admc_build_red80.sh

# Примечание:
1. Первичная сборка в mock длится долго из-за необходимости создания нового окружения
2. Патчи применимы к версии ADMC 0.23.1
```patch
diff -u src/admc/main.cpp src/admc/main.cpp
--- src/admc/main.cpp	2026-03-26 23:33:55.852042747 +0700
+++ src/admc/main.cpp	2026-03-26 23:37:42.015558322 +0700
@@ -117,7 +117,7 @@
         }
     }
     catch (const std::runtime_error& e) {
-        qWarning(e.what());
+        qWarning("%s", e.what());
     }

     load_connection_options();
diff -u src/admc/managers/icon_manager.cpp src/admc/managers/icon_manager.cpp
--- src/admc/managers/icon_manager.cpp	2026-03-25 21:22:18.000000000 +0700
+++ src/admc/managers/icon_manager.cpp	2026-03-26 23:36:57.515047160 +0700
@@ -317,7 +317,7 @@
 }

 QStringList IconManager::available_themes() {
-    const QStringList available_themes = {impl->system_theme, impl->custom_theme};
+    const QStringList available_themes = {impl->system_theme};

     return available_themes;
 } 
```

