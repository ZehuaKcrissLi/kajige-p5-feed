#!/bin/bash
set -euo pipefail

ARCHIVE_NAME="Kajige-P6-Raid-Trainer-Mac-v1.4.16.zip"
EXPECTED_SHA256="8f2e41b050642a719d4a2044c91081f30e4eaf3f4d6fb35fad4f23a722bd9253"
# 官方源排第一位，后面是中国大陆可达的 GitHub 加速线路。逐个尝试，
# 只有 SHA-256 校验通过才算成功。
if [[ -n "${KAJIGE_BASE_URL:-}" ]]; then
  SOURCES=("${KAJIGE_BASE_URL}/${ARCHIVE_NAME}")
else
  MIRROR_ASSET="https://github.com/ZehuaKcrissLi/kajige-p5-dist/releases/download/v1.4.16-p6-20261003/${ARCHIVE_NAME}"
  SOURCES=(
    "https://kaji-training.kcriss.dev/${ARCHIVE_NAME}"
    "https://gh-proxy.com/${MIRROR_ASSET}"
    "https://gh.llkk.cc/${MIRROR_ASSET}"
    "https://cdn.gh-proxy.com/${MIRROR_ASSET}"
    "https://ghfast.top/${MIRROR_ASSET}"
    "https://ghproxy.net/${MIRROR_ASSET}"
  )
fi
APPLICATIONS_DIR="${KAJIGE_APPLICATIONS_DIR:-${HOME}/Applications}"
BACKUP_DIR="${HOME}/Games/KajigeP5Backups/current-app-rollback"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/kajige-mac-install.XXXXXX")"
ARCHIVE="${WORK_DIR}/${ARCHIVE_NAME}"
EXTRACTED="${WORK_DIR}/extracted"

cleanup() {
  rm -rf "${WORK_DIR}"
}
trap cleanup EXIT INT TERM

echo "正在下载咔鸡哥 P6 Mac 安装器…"
DOWNLOAD_OK=0
for SOURCE_URL in "${SOURCES[@]}"; do
  SOURCE_HOST="${SOURCE_URL#https://}"
  SOURCE_HOST="${SOURCE_HOST%%/*}"
  echo "  线路：${SOURCE_HOST}"
  rm -f "${ARCHIVE}"
  if ! /usr/bin/curl \
    --location \
    --fail \
    --show-error \
    --retry 3 \
    --retry-delay 2 \
    --connect-timeout 20 \
    --output "${ARCHIVE}" \
    "${SOURCE_URL}"; then
    echo "  该线路不可用，换下一条。" >&2
    continue
  fi
  ACTUAL_SHA256="$(/usr/bin/shasum -a 256 "${ARCHIVE}" | /usr/bin/awk '{print $1}')"
  if [[ "${ACTUAL_SHA256}" != "${EXPECTED_SHA256}" ]]; then
    echo "  该线路返回的文件校验不一致，换下一条。" >&2
    continue
  fi
  DOWNLOAD_OK=1
  break
done
if [[ "${DOWNLOAD_OK}" != "1" ]]; then
  echo "所有下载线路都失败或校验不通过，已停止安装。" >&2
  exit 1
fi

/bin/mkdir -p "${EXTRACTED}" "${APPLICATIONS_DIR}"
/usr/bin/ditto -x -k "${ARCHIVE}" "${EXTRACTED}"

APP_COUNT=0
for SOURCE_APP in "${EXTRACTED}"/*.app; do
  if [[ ! -d "${SOURCE_APP}" ]]; then
    continue
  fi
  MODE="$(/usr/libexec/PlistBuddy -c 'Print :KajigeProductMode' \
    "${SOURCE_APP}/Contents/Info.plist" 2>/dev/null || true)"
  if [[ "${MODE}" != "installer" && "${MODE}" != "launcher" ]]; then
    echo "拒绝安装未知应用：${SOURCE_APP}" >&2
    exit 1
  fi

  DESTINATION="${APPLICATIONS_DIR}/${SOURCE_APP##*/}"
  /bin/mkdir -p "${BACKUP_DIR}"
  BACKUP="${BACKUP_DIR}/${SOURCE_APP##*/}"
  if [[ -e "${BACKUP}" ]]; then
    rm -rf "${BACKUP}"
  fi
  if [[ -e "${DESTINATION}" ]]; then
    /bin/mv "${DESTINATION}" "${BACKUP}"
  fi
  /usr/bin/ditto "${SOURCE_APP}" "${DESTINATION}"
  /usr/bin/xattr -dr com.apple.quarantine "${DESTINATION}" 2>/dev/null || true
  /usr/bin/codesign --verify --deep --strict "${DESTINATION}"
  LEGACY_NAME="${SOURCE_APP##*/}"
  LEGACY_NAME="${LEGACY_NAME/P6/P5}"
  LEGACY_APP="${APPLICATIONS_DIR}/${LEGACY_NAME}"
  if [[ -d "${LEGACY_APP}" ]]; then
    LEGACY_BACKUP="${BACKUP_DIR}/${LEGACY_NAME}"
    rm -rf "${LEGACY_BACKUP}"
    /bin/mv "${LEGACY_APP}" "${LEGACY_BACKUP}"
  fi
  APP_COUNT=$((APP_COUNT + 1))
done

if [[ "${APP_COUNT}" -ne 2 ]]; then
  echo "安装包中应有两个应用，实际为 ${APP_COUNT}。" >&2
  exit 1
fi

echo "安装器与启动器已放入 ${APPLICATIONS_DIR}"
if [[ "${KAJIGE_SKIP_OPEN:-0}" != "1" ]]; then
  /usr/bin/open "${APPLICATIONS_DIR}/咔鸡哥P6训练服安装器.app"
fi
