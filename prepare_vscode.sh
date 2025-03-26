#!/usr/bin/env bash
# shellcheck disable=SC1091,2154

set -e

# include common functions
. ./utils.sh

if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
  cp -rp src/insider/* vscode/
else
  cp -rp src/stable/* vscode/
fi

cp -f LICENSE vscode/LICENSE.txt

cd vscode || { echo "'vscode' dir not found"; exit 1; }

../update_settings.sh

# apply patches
{ set +x; } 2>/dev/null

for file in ../patches/*.patch; do
  if [[ -f "${file}" ]]; then
    echo applying patch: "${file}";
    # grep '^+++' "${file}"  | sed -e 's#+++ [ab]/#./vscode/#' | while read line; do shasum -a 256 "${line}"; done
    if ! git apply --ignore-whitespace "${file}"; then
      echo "warning: failed to apply patch ${file}, continuing anyway" >&2
    fi
  fi
done

if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
  for file in ../patches/insider/*.patch; do
    if [[ -f "${file}" ]]; then
      echo applying patch: "${file}";
      if ! git apply --ignore-whitespace "${file}"; then
        echo "warning: failed to apply patch ${file}, continuing anyway" >&2
      fi
    fi
  done
fi

for file in ../patches/user/*.patch; do
  if [[ -f "${file}" ]]; then
    echo applying user patch: "${file}";
    if ! git apply --ignore-whitespace "${file}"; then
      echo "warning: failed to apply patch ${file}, continuing anyway" >&2
    fi
  fi
done

if [[ -d "../patches/${OS_NAME}/" ]]; then
  for file in "../patches/${OS_NAME}/"*.patch; do
    if [[ -f "${file}" ]]; then
      echo applying patch: "${file}";
      if ! git apply --ignore-whitespace "${file}"; then
        echo "warning: failed to apply patch ${file}, continuing anyway" >&2
      fi
    fi
  done
fi

set -x

export ELECTRON_SKIP_BINARY_DOWNLOAD=1
export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

if [[ "${OS_NAME}" == "linux" ]]; then
  export VSCODE_SKIP_NODE_VERSION_CHECK=1

   if [[ "${npm_config_arch}" == "arm" ]]; then
    export npm_config_arm_version=7
  fi
elif [[ "${OS_NAME}" == "windows" ]]; then
  if [[ "${npm_config_arch}" == "arm" ]]; then
    export npm_config_arm_version=7
  fi
fi

for i in {1..5}; do # try 5 times
  npm ci && break
  if [[ $i == 3 ]]; then
    echo "Npm install failed too many times" >&2
    exit 1
  fi
  echo "Npm install failed $i, trying again..."

  sleep $(( 15 * (i + 1)))
done

setpath() {
  local jsonTmp
  { set +x; } 2>/dev/null
  jsonTmp=$( jq --arg 'path' "${2}" --arg 'value' "${3}" 'setpath([$path]; $value)' "${1}.json" )
  echo "${jsonTmp}" > "${1}.json"
  set -x
}

setpath_json() {
  local jsonTmp
  { set +x; } 2>/dev/null
  jsonTmp=$( jq --arg 'path' "${2}" --argjson 'value' "${3}" 'setpath([$path]; $value)' "${1}.json" )
  echo "${jsonTmp}" > "${1}.json"
  set -x
}

# product.json
cp product.json{,.bak}

setpath "product" "checksumFailMoreInfoUrl" "https://go.microsoft.com/fwlink/?LinkId=828886"
setpath "product" "documentationUrl" "https://voideditor.com"
setpath_json "product" "extensionsGallery" '{"serviceUrl": "https://open-vsx.org/vscode/gallery", "itemUrl": "https://open-vsx.org/vscode/item"}'
setpath "product" "introductoryVideosUrl" "https://go.microsoft.com/fwlink/?linkid=832146"
setpath "product" "keyboardShortcutsUrlLinux" "https://go.microsoft.com/fwlink/?linkid=832144"
setpath "product" "keyboardShortcutsUrlMac" "https://go.microsoft.com/fwlink/?linkid=832143"
setpath "product" "keyboardShortcutsUrlWin" "https://go.microsoft.com/fwlink/?linkid=832145"
setpath "product" "licenseUrl" "https://github.com/voideditor/void/blob/main/LICENSE.txt"
setpath_json "product" "linkProtectionTrustedDomains" '["https://open-vsx.org"]'
setpath "product" "releaseNotesUrl" "https://go.microsoft.com/fwlink/?LinkID=533483#vscode"
setpath "product" "reportIssueUrl" "https://github.com/voideditor/void/issues/new"
setpath "product" "requestFeatureUrl" "https://github.com/voideditor/void/issues/new"
setpath "product" "tipsAndTricksUrl" "https://go.microsoft.com/fwlink/?linkid=852118"
setpath "product" "twitterUrl" "https://x.com/thevoideditor"

if [[ "${DISABLE_UPDATE}" != "yes" ]]; then
  setpath "product" "updateUrl" "https://raw.githubusercontent.com/voideditor/versions/refs/heads/main"
  setpath "product" "downloadUrl" "https://github.com/voideditor/binaries/releases"
fi

if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
  setpath "product" "nameShort" "Void - Insiders"
  setpath "product" "nameLong" "Void - Insiders"
  setpath "product" "applicationName" "void-insiders"
  setpath "product" "dataFolderName" ".void-insiders"
  setpath "product" "linuxIconName" "void-insiders"
  setpath "product" "quality" "insider"
  setpath "product" "urlProtocol" "void-insiders"
  setpath "product" "serverApplicationName" "void-server-insiders"
  setpath "product" "serverDataFolderName" ".void-server-insiders"
  setpath "product" "darwinBundleIdentifier" "ai.voideditor.VoidInsiders"
  setpath "product" "win32AppUserModelId" "Void.VoidInsiders"
  setpath "product" "win32DirName" "Void Insiders"
  setpath "product" "win32MutexName" "voidinsiders"
  setpath "product" "win32NameVersion" "Void Insiders"
  setpath "product" "win32RegValueName" "VoidInsiders"
  setpath "product" "win32ShellNameShort" "Void Insiders"
  setpath "product" "win32AppId" "{{5893CE20-77AA-4856-A655-ECE65CBCF1C7}"
  setpath "product" "win32x64AppId" "{{7A261980-5847-44B6-B554-31DF0F5CDFC9}"
  setpath "product" "win32arm64AppId" "{{EE4FF7AA-A874-419D-BAE0-168C9DBCE211}"
  setpath "product" "win32UserAppId" "{{FA3AE0C7-888E-45DA-AB58-B8E33DE0CB2E}"
  setpath "product" "win32x64UserAppId" "{{5B1813E3-1D97-4E00-AF59-C59A39CF066A}"
  setpath "product" "win32arm64UserAppId" "{{C2FA90D8-B265-41B1-B909-3BAEB21CAA9D}"
else
  setpath "product" "nameShort" "Void"
  setpath "product" "nameLong" "Void"
  setpath "product" "applicationName" "void"
  setpath "product" "linuxIconName" "void"
  setpath "product" "quality" "stable"
  setpath "product" "urlProtocol" "void"
  setpath "product" "serverApplicationName" "void-server"
  setpath "product" "serverDataFolderName" ".void-server"
  setpath "product" "darwinBundleIdentifier" "com.void"
  setpath "product" "win32AppUserModelId" "Void.Void"
  setpath "product" "win32DirName" "Void"
  setpath "product" "win32MutexName" "void"
  setpath "product" "win32NameVersion" "Void"
  setpath "product" "win32RegValueName" "Void"
  setpath "product" "win32ShellNameShort" "Void"
  setpath "product" "win32AppId" "{{763CBF88-25C6-4B10-952F-326AE657F16B}"
  setpath "product" "win32x64AppId" "{{88DA3577-054F-4CA1-8122-7D820494CFFB}"
  setpath "product" "win32arm64AppId" "{{67DEE444-3D04-4258-B92A-BC1F0FF2CAE4}"
  setpath "product" "win32UserAppId" "{{0FD05EB4-651E-4E78-A062-515204B47A3A}"
  setpath "product" "win32x64UserAppId" "{{2E1F05D1-C245-4562-81EE-28188DB6FD17}"
  setpath "product" "win32arm64UserAppId" "{{57FD70A5-1B8D-4875-9F40-C5553F094828}"
fi

jsonTmp=$( jq -s '.[0] * .[1]' product.json ../product.json )
echo "${jsonTmp}" > product.json && unset jsonTmp

cat product.json

# package.json
cp package.json{,.bak}

setpath "package" "version" "$( echo "${RELEASE_VERSION}" | sed -n -E "s/^(.*)\.([0-9]+)(-insider)?$/\1/p" )"
setpath "package" "release" "$( echo "${RELEASE_VERSION}" | sed -n -E "s/^(.*)\.([0-9]+)(-insider)?$/\2/p" )"

replace 's|Microsoft Corporation|Void|' package.json

# announcements
replace "s|\\[\\/\\* BUILTIN_ANNOUNCEMENTS \\*\\/\\]|$( tr -d '\n' < ../announcements-builtin.json )|" src/vs/workbench/contrib/welcomeGettingStarted/browser/gettingStarted.ts

../undo_telemetry.sh

replace 's|Microsoft Corporation|Void|' build/lib/electron.js
replace 's|Microsoft Corporation|Void|' build/lib/electron.ts
replace 's|([0-9]) Microsoft|\1 Void|' build/lib/electron.js
replace 's|([0-9]) Microsoft|\1 Void|' build/lib/electron.ts

if [[ "${OS_NAME}" == "linux" ]]; then
  # microsoft adds their apt repo to sources
  # unless the app name is code-oss
  # as we are renaming the application to void
  # we need to edit a line in the post install template
  if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
    sed -i "s/code-oss/void-insiders/" resources/linux/debian/postinst.template
  else
    sed -i "s/code-oss/void/" resources/linux/debian/postinst.template
  fi

  # fix the packages metadata
  # code.appdata.xml
  sed -i 's|Visual Studio Code|Void|g' resources/linux/code.appdata.xml
  sed -i 's|https://code.visualstudio.com/docs/setup/linux|https://docs.void.dev|' resources/linux/code.appdata.xml
  sed -i 's|https://code.visualstudio.com/home/home-screenshot-linux-lg.png|https://vscodium.com/img/vscodium.png|' resources/linux/code.appdata.xml
  sed -i 's|https://code.visualstudio.com|https://void.dev|' resources/linux/code.appdata.xml

  # control.template
  sed -i 's|Microsoft Corporation <vscode-linux@microsoft.com>|Void Team <team@voideditor.com>|'  resources/linux/debian/control.template
  sed -i 's|Visual Studio Code|Void|g' resources/linux/debian/control.template
  sed -i 's|https://code.visualstudio.com/docs/setup/linux|https://docs.void.dev|' resources/linux/debian/control.template
  sed -i 's|https://code.visualstudio.com|https://void.dev|' resources/linux/debian/control.template

  # code.spec.template
  sed -i 's|Microsoft Corporation|Void Team|' resources/linux/rpm/code.spec.template
  sed -i 's|Visual Studio Code Team <vscode-linux@microsoft.com>|Void Team <team@voideditor.com>|' resources/linux/rpm/code.spec.template
  sed -i 's|Visual Studio Code|Void|' resources/linux/rpm/code.spec.template
  sed -i 's|https://code.visualstudio.com/docs/setup/linux|https://docs.void.dev|' resources/linux/rpm/code.spec.template
  sed -i 's|https://code.visualstudio.com|https://void.dev|' resources/linux/rpm/code.spec.template

  # snapcraft.yaml
  sed -i 's|Visual Studio Code|Void|'  resources/linux/rpm/code.spec.template
elif [[ "${OS_NAME}" == "windows" ]]; then
  # code.iss
  sed -i 's|https://code.visualstudio.com|https://void.dev|' build/win32/code.iss
  sed -i 's|Microsoft Corporation|Void|' build/win32/code.iss
fi

cd ..
