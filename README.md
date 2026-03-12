# admc-redos
Скрипт автоматической соборки ADMC 0.22.3 (https://github.com/altlinux/admc) для Ред ОС 8, собранные пакеты

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

3. Создаем какой-либо рабочий каталог и помещаем в него файлы, необходимые для сборки, из каталога redos:
- admc_build_red80.sh (скрипт автоматической сборки пакета в mock)
- admc-red80.spec (спецификация)
- admc-master-1.red80.patch (патчи, применяемые к оригинальному исходному коду для сборки под Ред ОС)

4. Для автоматической сборки запускаем скрипт admc_build_red80.sh

# Примечание:
1. Первичная сборка в mock длится долго из-за необходимости создания нового окружения
2. Патчи применимы к версии ADMC 0.22.3
- только для Ред ОС (исправляет ошибку сборки):
```patch
diff -u src/admc/main.cpp src/admc/main.cpp
--- src/admc/main.cpp	2026-02-21 07:52:57.000000000 +0700
+++ src/admc/main.cpp	2026-03-01 14:30:00.000000000 +0700
@@ -106,7 +106,7 @@
         }
     }
     catch (const std::runtime_error& e) {
-        qWarning(e.what());
+        qWarning("%s", e.what());
     }

     load_connection_options();
```
- для Ред ОС и Debian 13 (опечатка в CMakeLists.txt):
```patch
diff -u src/adldap/CMakeLists.txt src/adldap/CMakeLists.txt
--- src/adldap/CMakeLists.txt	2026-02-21 07:52:57.000000000 +0700
+++ src/adldap/CMakeLists.txt	2026-03-01 11:40:05.111637402 +0700
@@ -81,7 +81,7 @@
              DESTINATION ${SMB_SRC_PATH})
         file(COPY ${SMB_SRC_PATH}/src_older/ndr_sec_helper.c
              DESTINATION ${SMB_SRC_PATH})
-    endif(VERSION_SMB_MINOR GREATER_EQUAL 20)
+    endif(VERSION_SMB_MINOR GREATER_EQUAL 22)
 else()
     message(WARNING "Failed to find Samba version. If its version is 20 or greater, use sources from src_4_20.")
 endif(EXISTS ${VERSION_H})
```

- для Ред ОС и Debian 13 (падение ADMC при запуске без предварительного выполнения kinit):
```patch
diff -u src/adldap/krb5client.cpp src/adldap/krb5client.cpp
--- src/adldap/krb5client.cpp	2026-02-21 07:52:57.000000000 +0700
+++ src/adldap/krb5client.cpp	2026-03-01 11:41:57.677958846 +0700
@@ -228,7 +228,7 @@

 void Krb5Client::Krb5ClientImpl::load_cache_data(krb5_ccache ccache, bool is_system) {
     krb5_error_code res;
-    krb5_principal principal;
+    krb5_principal principal = nullptr;
     krb5_creds creds;
     Krb5TGTData tgt_data;
```

- для Ред ОС и Debian 13 (отключение поиска тем, используемых только в AltLinux):
```patch
diff -u src/admc/managers/icon_manager.cpp src/admc/managers/icon_manager.cpp
--- src/admc/managers/icon_manager.cpp	2026-02-21 07:52:57.000000000 +0700
+++ src/admc/managers/icon_manager.cpp	2026-03-12 10:34:53.465392423 +0700
@@ -297,7 +297,7 @@
 }

 QStringList IconManager::available_themes() {
-    const QStringList available_themes = {impl->system_theme, impl->custom_theme};
+    const QStringList available_themes = {impl->system_theme};

     return available_themes;
 }
```

