#!/bin/bash

if [ -z "${IDF_BUILD_PATH}" -o -z "${IDF_PATH}" ]; then
   echo "IDF_BUILD_PATH not defined"
   exit;
fi

RELEASE_ID=3.0.0
RELEASE_TAG=3.0.0
WORKSPACE="$( cd "$(dirname "$0")" ; cd ../..; pwd -P )"

SDK_DIR="$WORKSPACE/tools/sdk"
LIB_DIR="$SDK_DIR/lib"
INC_DIR="$SDK_DIR/include"
LD_DIR="$SDK_DIR/ld"

echo "Workspace: $WORKSPACE"
echo "IDF Build Path: $IDF_BUILD_PATH"
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

function get_os(){
  	OSBITS=`arch`
  	if [[ "$OSTYPE" == "linux"* ]]; then
        if [[ "$OSBITS" == "i686" ]]; then
        	echo "linux32"
        elif [[ "$OSBITS" == "x86_64" ]]; then
        	echo "linux64"
        elif [[ "$OSBITS" == "armv7l" ]]; then
        	echo "linux-armel"
        else
        	echo "unknown"
	    	return 1
        fi
	elif [[ "$OSTYPE" == "darwin"* ]]; then
	    echo "macos"
	elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
	    echo "win32"
	else
	    echo "$OSTYPE"
	    return 1
	fi
	return 0
}

AR_OS=`get_os`
export SSTAT="stat -c %s"

if [[ "$AR_OS" == "macos" ]]; then
	export SSTAT="stat -f %z"
fi

#cp -f $IDF_BUILD_PATH/../sdkconfig $SDK_DIR/sdkconfig
#cp -f $IDF_BUILD_PATH/include/sdkconfig.h $INC_DIR/config

find $IDF_BUILD_PATH -name '*.ld' -exec cp -f {} $LD_DIR \;


# component libs
for lib in `find ${IDF_PATH}/components -name '*.a' | grep -v arduino`; do
    lsize=$($SSTAT "$lib")
    if (( lsize > minlsize )); then
        cp -f $lib $LIB_DIR
    else
        echo "skipping $lib: size too small $lsize"
    fi
done

# compiled libs
minlsize=8
for lib in `find ${IDF_BUILD_PATH} -name '*.a' | grep -v bootloader | grep -v libmain | grep -v idf_test | grep -v aws_iot | grep -v libmicro | grep -v libarduino`; do
    lsize=$($SSTAT "$lib")
    if (( lsize > minlsize )); then
        cp -f $lib $LIB_DIR
    else
        echo "skipping $lib: size too small $lsize"
    fi
done

cp ${IDF_BUILD_PATH}/bootloader_support/libbootloader_support.a $LIB_DIR
cp ${IDF_BUILD_PATH}/bootloader/micro-ecc/libmicro-ecc.a $LIB_DIR

NIMBLE_COMPONENT_INCLUDEDIRS=( host/nimble/nimble/nimble/include                 \
                             host/nimble/nimble/nimble/host/include                \
                             host/nimble/nimble/porting/nimble/include             \
                             host/nimble/nimble/porting/npl/freertos/include       \
                             host/nimble/nimble/nimble/host/services/ans/include   \
                             host/nimble/nimble/nimble/host/services/bas/include   \
                             host/nimble/nimble/nimble/host/services/gap/include   \
                             host/nimble/nimble/nimble/host/services/gatt/include  \
                             host/nimble/nimble/nimble/host/services/ias/include   \
                             host/nimble/nimble/nimble/host/services/lls/include   \
                             host/nimble/nimble/nimble/host/services/tps/include   \
                             host/nimble/nimble/nimble/host/util/include           \
                             host/nimble/nimble/nimble/host/store/ram/include      \
                             host/nimble/nimble/nimble/host/store/config/include   \
                             host/nimble/esp-hci/include                           \
                             host/nimble/port/include )

mkdir -p $INC_DIR/nimble
for dir in "${NIMBLE_COMPONENT_INCLUDEDIRS[@]}"; do
   echo $dir
   cp -rf ${IDF_PATH}/components/bt/$dir/* $INC_DIR/nimble
done

cp ${IDF_PATH}/components/xtensa/include/esp_debug_helpers.h $INC_DIR/xtensa

echo "done"
