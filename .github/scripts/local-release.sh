#!/bin/bash

RELEASE_ID=2.0.0
RELEASE_TAG=2.0.0
GITHUB_WORKSPACE="$HOME/projects/arduino-esp32"
GITHUB_REPOSITORY="yuetloo/arduino-esp32"

OUTPUT_DIR="$GITHUB_WORKSPACE/build"
PACKAGE_NAME="esp32-$RELEASE_TAG"
PACKAGE_JSON_MERGE="$GITHUB_WORKSPACE/.github/scripts/merge_packages.py"
PACKAGE_JSON_TEMPLATE="$GITHUB_WORKSPACE/package/package_esp32_index.template.json"
PACKAGE_JSON_DEV="package_esp32_dev_index.json"
PACKAGE_JSON_REL="package_esp32_index.json"

echo "Repo: $GITHUB_REPOSITORY, Path: $GITHUB_WORKSPACE"
echo "Output: $OUTPUT_DIR"
echo "ID: $RELEASE_ID" 
echo "Tag: $RELEASE_TAG"

function get_file_size(){
    local file="$1"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        eval `stat -s "$file"`
        local res="$?"
        echo "$st_size"
        return $res
    else
        stat --printf="%s" "$file"
        return $?
    fi
}

set -e

##
## PACKAGE ZIP
##

mkdir -p "$OUTPUT_DIR"
PKG_DIR="$OUTPUT_DIR/$PACKAGE_NAME"
PACKAGE_ZIP="$PACKAGE_NAME.zip"

echo "Updating submodules ..."
git -C "$GITHUB_WORKSPACE" submodule update --init --recursive > /dev/null 2>&1

mkdir -p "$PKG_DIR/tools"

# Copy all core files to the package folder
echo "Copying files for packaging ..."
cp -f  "$GITHUB_WORKSPACE/boards.txt"              "$PKG_DIR/"
cp -f  "$GITHUB_WORKSPACE/programmers.txt"         "$PKG_DIR/"
cp -Rf "$GITHUB_WORKSPACE/cores"                   "$PKG_DIR/"
cp -Rf "$GITHUB_WORKSPACE/libraries"               "$PKG_DIR/"
cp -Rf "$GITHUB_WORKSPACE/variants"                "$PKG_DIR/"
cp -f  "$GITHUB_WORKSPACE/tools/espota.exe"        "$PKG_DIR/tools/"
cp -f  "$GITHUB_WORKSPACE/tools/espota.py"         "$PKG_DIR/tools/"
cp -f  "$GITHUB_WORKSPACE/tools/esptool.py"        "$PKG_DIR/tools/"
cp -f  "$GITHUB_WORKSPACE/tools/gen_esp32part.py"  "$PKG_DIR/tools/"
cp -f  "$GITHUB_WORKSPACE/tools/gen_esp32part.exe" "$PKG_DIR/tools/"
cp -Rf "$GITHUB_WORKSPACE/tools/partitions"        "$PKG_DIR/tools/"
cp -Rf "$GITHUB_WORKSPACE/tools/sdk"               "$PKG_DIR/tools/"

# Remove unnecessary files in the package folder
echo "Cleaning up folders ..."
find "$PKG_DIR" -name '*.DS_Store' -exec rm -f {} \;
find "$PKG_DIR" -name '*.git*' -type f -delete

# Replace tools locations in platform.txt
echo "Generating platform.txt..."
cat "$GITHUB_WORKSPACE/platform.txt" | \
sed "s/version=.*/version=$ver$extent/g" | \
sed 's/runtime.tools.xtensa-esp32-elf-gcc.path={runtime.platform.path}\/tools\/xtensa-esp32-elf//g' | \
sed 's/tools.esptool_py.path={runtime.platform.path}\/tools\/esptool/tools.esptool_py.path=\{runtime.tools.esptool_py.path\}/g' \
 > "$PKG_DIR/platform.txt"

# Add header with version information
echo "Generating core_version.h ..."
ver_define=`echo $RELEASE_TAG | tr "[:lower:].\055" "[:upper:]_"`
ver_hex=`git -C "$GITHUB_WORKSPACE" rev-parse --short=8 HEAD 2>/dev/null`
echo \#define ARDUINO_ESP32_GIT_VER 0x$ver_hex > "$PKG_DIR/cores/esp32/core_version.h"
echo \#define ARDUINO_ESP32_GIT_DESC `git -C "$GITHUB_WORKSPACE" describe --tags 2>/dev/null` >> "$PKG_DIR/cores/esp32/core_version.h"
echo \#define ARDUINO_ESP32_RELEASE_$ver_define >> "$PKG_DIR/cores/esp32/core_version.h"
echo \#define ARDUINO_ESP32_RELEASE \"$ver_define\" >> "$PKG_DIR/cores/esp32/core_version.h"

# Compress package folder
echo "Creating ZIP ..."
pushd "$OUTPUT_DIR" >/dev/null
zip -qr "$PACKAGE_ZIP" "$PACKAGE_NAME"
if [ $? -ne 0 ]; then echo "ERROR: Failed to create $PACKAGE_ZIP ($?)"; exit 1; fi

# Calculate SHA-256
echo "Calculating SHA sum ..."
PACKAGE_PATH="https://github.com/$GITHUB_REPOSITORY/releases/download/$RELEASE_TAG/$PACKAGE_ZIP"
PACKAGE_SHA=`shasum -a 256 "$PACKAGE_ZIP" | cut -f 1 -d ' '`
PACKAGE_SIZE=`get_file_size "$PACKAGE_ZIP"`
popd >/dev/null
rm -rf "$PKG_DIR"
echo "'$PACKAGE_ZIP' Created! Size: $PACKAGE_SIZE, SHA-256: $PACKAGE_SHA"
echo "url: $PACKAGE_PATH"
echo

echo "Update package json file"
cat "$GITHUB_WORKSPACE/package/package_esp32_index.template.json" | \
sed "s/\"version\": \"\"/\"version\": \"$RELEASE_TAG\"/" | \
sed "s/\"checksum\": \"\"/\"checksum\": \"SHA-256:$PACKAGE_SHA\"/" | \
sed "s/\"archiveFileName\": \"\"/\"archiveFileName\": \"$PACKAGE_ZIP\"/" | \
sed "s/\"url\": \"\"/\"url\": \"${PACKAGE_PATH//\//\\/}\"/" | \
sed "s/\"size\": \"\"/\"size\": \"$PACKAGE_SIZE\"/"  \
> "$GITHUB_WORKSPACE/package/package_esp32_index.json"




##
## SUBMODULE VERSIONS
##

# Upload submodules versions
echo "Generating submodules.txt ..."
git -C "$GITHUB_WORKSPACE" submodule status > "$OUTPUT_DIR/submodules.txt"
#echo "Uploading submodules.txt ..."
#echo "Download URL: "`git_safe_upload_asset "$OUTPUT_DIR/submodules.txt"`
echo ""
set +e

##
## DONE
##
echo "DONE!"
