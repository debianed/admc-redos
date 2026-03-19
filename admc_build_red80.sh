#!/usr/bin/env bash

# Copyright (c) 2026 Barbyshev Artem <art.barbyshev@mail.ru>
# The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package
# itself (unless the license for the pristine package is not an
# Open Source License, in which case the license is the MIT License).
#
# Copyright (c) 2026 Барбышев Артем <art.barbyshev@mail.ru>
# Лицензия на этот файл, а также на изменения и дополнения к файлу,
# является той же, что и для самого пакета (за исключением случаев,
# когда лицензия на пакет не является лицензией с открытым исходным
# кодом, в этом случае лицензией является лицензия MIT).

set -euo pipefail

ZIP_FILE="admc-master.zip"
SRC_DIR="admc-master"
SPEC_FILE="${SRC_DIR}/.gear/admc.spec"

RPMBUILD_DIR="$(getent passwd "$(id -un)" | cut -d: -f6)/rpmbuild"
SOURCES_DIR="${RPMBUILD_DIR}/SOURCES"
SPECS_DIR="${RPMBUILD_DIR}/SPECS"
SRPMS_DIR="${RPMBUILD_DIR}/SRPMS"

PATCH_SRC="admc-master-1.red80.patch"
SPEC_SRC="admc-red80.spec"

MOCK_CFG="redos-80-x86_64"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOCK_RESULT_DIR="/var/lib/mock/${MOCK_CFG}/result"

echo "[1/14] Скачивание $ZIP_FILE..."
if ! command -v curl >/dev/null 2>&1; then
  echo "Ошибка: команда curl не найдена." >&2
  exit 1
fi
curl -L -o "$ZIP_FILE" "https://github.com/altlinux/admc/archive/refs/heads/master.zip"

if [[ ! -s "$ZIP_FILE" ]]; then
  echo "Ошибка: не удалось скачать архив $ZIP_FILE" >&2
  exit 1
fi

echo "[2/14] Распаковка $ZIP_FILE..."
unzip -o "$ZIP_FILE" >/dev/null

echo "[3/14] Проверка spec-файла..."
if [[ ! -f "$SPEC_FILE" ]]; then
  echo "Ошибка: не найден spec-файл $SPEC_FILE" >&2
  exit 1
fi

echo "[4/14] Чтение версии из spec..."
VERSION="$(awk -F': *' '/^Version:/ {print $2; exit}' "$SPEC_FILE")"

if [[ -z "${VERSION:-}" ]]; then
  echo "Ошибка: не удалось определить версию из $SPEC_FILE" >&2
  exit 1
fi
echo "Найдена версия: $VERSION"

DST_DIR="${SRC_DIR/master/$VERSION}"
TAR_FILE="${DST_DIR}.tar"
PATCH_DST="admc-${VERSION}-1.red80.patch"
SPEC_DST="${SPECS_DIR}/admc-red80.spec"

if [[ "$DST_DIR" == "$SRC_DIR" ]]; then
  echo "Ошибка: не удалось сформировать новое имя каталога" >&2
  exit 1
fi

echo "[5/14] Переименование каталога в $DST_DIR..."
if [[ -d "$DST_DIR" ]]; then
  rm -rf "$DST_DIR"
fi
mv "$SRC_DIR" "$DST_DIR"

echo "[6/14] Упаковка в $TAR_FILE..."
tar -cf "$TAR_FILE" "$DST_DIR"

echo "[7/14] Очистка временных артефактов..."
rm -rf "$DST_DIR"
rm -f "$ZIP_FILE"

echo "[8/14] Подготовка rpmbuild-дерева..."
if ! command -v rpmdev-setuptree >/dev/null 2>&1; then
  echo "Ошибка: команда rpmdev-setuptree не найдена. Установите rpmdevtools." >&2
  exit 1
fi

rpmdev-setuptree >/dev/null

if [[ ! -d "$SOURCES_DIR" ]]; then
  echo "Ошибка: каталог $SOURCES_DIR не создан." >&2
  exit 1
fi

if [[ ! -d "$SPECS_DIR" ]]; then
  echo "Ошибка: каталог $SPECS_DIR не создан." >&2
  exit 1
fi

echo "[9/14] Перенос исходного архива в SOURCES..."
if [[ ! -f "$TAR_FILE" ]]; then
  echo "Ошибка: архив $TAR_FILE не найден для переноса." >&2
  exit 1
fi
mv -f "$TAR_FILE" "$SOURCES_DIR/"

echo "[10/14] Переименование patch и перенос в SOURCES..."
if [[ ! -f "$PATCH_SRC" ]]; then
  echo "Ошибка: patch-файл $PATCH_SRC не найден." >&2
  exit 1
fi
cp -f "$PATCH_SRC" "$SOURCES_DIR/$PATCH_DST"

echo "[11/14] Обновление версии в $SPEC_SRC и перенос в SPECS..."
if [[ ! -f "$SPEC_SRC" ]]; then
  echo "Ошибка: spec-файл $SPEC_SRC не найден." >&2
  exit 1
fi
sed -E "s/^(Version:[[:space:]]*)master$/\1${VERSION}/" "$SPEC_SRC" > "$SPEC_DST"

echo "[12/14] Сборка src-пакета (rpmbuild -bs)..."
rpmbuild -bs "$SPEC_DST"

echo "[13/14] Запрос на сборку в mock..."
read -r -p "Собирать rpm в mock? [y/N]: " BUILD_IN_MOCK

if [[ ! "$BUILD_IN_MOCK" =~ ^([yY]|[yY][eE][sS])$ ]]; then
  echo "Сборка в mock пропущена по выбору пользователя."
  echo "Готово."
  echo "Архив исходников: $SOURCES_DIR/$TAR_FILE"
  echo "Patch-файл:        $SOURCES_DIR/$PATCH_DST"
  echo "Spec-файл:         $SPEC_DST"
  echo "Каталог $DST_DIR и исходный $ZIP_FILE удалены."
  exit 0
fi

echo "[14/14] Сборка в mock..."
if ! command -v mock >/dev/null 2>&1; then
  echo "Ошибка: команда mock не найдена." >&2
  exit 1
fi

if [[ ! -d "$SRPMS_DIR" ]]; then
  echo "Ошибка: каталог $SRPMS_DIR не найден." >&2
  exit 1
fi

SRPM_FILE="$(ls -1t "$SRPMS_DIR"/*.src.rpm 2>/dev/null | head -n1 || true)"
if [[ -z "${SRPM_FILE:-}" || ! -f "$SRPM_FILE" ]]; then
  echo "Ошибка: не найден src.rpm в $SRPMS_DIR после rpmbuild -bs." >&2
  exit 1
fi

mock -r "/etc/mock/$MOCK_CFG.cfg" "$SRPM_FILE"

echo "Копирование результатов mock из $MOCK_RESULT_DIR в $SCRIPT_DIR..."
if [[ ! -d "$MOCK_RESULT_DIR" ]]; then
  echo "Ошибка: каталог результатов mock не найден: $MOCK_RESULT_DIR" >&2
  exit 1
fi
cp -a "$MOCK_RESULT_DIR"/. "$SCRIPT_DIR"/
rm -rf "$RPMBUILD_DIR"

echo "Готово."
echo "Архив исходников: $SOURCES_DIR/$TAR_FILE"
echo "Patch-файл:        $SOURCES_DIR/$PATCH_DST"
echo "Spec-файл:         $SPEC_DST"
echo "SRPM:              $SRPM_FILE"
echo "Результаты mock:   скопированы в $SCRIPT_DIR"
echo "Каталог $DST_DIR и исходный $ZIP_FILE удалены."
