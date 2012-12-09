#===============================================================================
# Filename:  libjson.sh
# Authors:    
#            David Andreoletti (http://davidandreoletti.com)
#               - Refactored script to compile libjson version:
#                   - 7.6.1
#               - Added support to automatically download libjson version from sourceforge.net
#               - Added support to automatically discover Xcode path.
#               - Added auto detection of GCC/Clang compiler version.
#               - 
# Licence:   Please feel free to use this, with attribution
#===============================================================================
#
# Builds libjson for the iPhone.
#
# Creates a set of universal libraries that can be used on an iPhone and in the
# iPhone simulator (i.e x86/armv6/armv7). Also creates a pseudo-framework to make using libjson in Xcode
# less painful.
#
# Universal libraries and framework are available at ${PREFIXDIR} (See below for definition)
#
# To configure the script, define:
#    LIBJSON_VERSION:       Version number of the libjson library. 
#                           If the version zipball for the requested version does not 
#                           exist, then it will be downloaded.
#
#                           Default value: 7.6.1
#
#    IPHONE_SDKVERSION:     iPhone SDK version.  If not define, default value is used.
#
#                           Default value: Latest (i.e latest SDK available on the host machine)
#
#    LIBJSON_OPTION_BUILD:  Builds libjson. Valid values: "true" or "false"
#
#                           Default value: true
#
#    LIBJSON_OPTION_CLEAN:  Cleans building directory. Valid values: "true" or "false"
#
#                           Default value: true
# Note:
#  - If Xcode 4.5+ is used, library will NOT have support for armv6
#
#===============================================================================

: ${LIBJSON_VERSION:=7.6.1}
: ${IPHONE_SDKVERSION:="Latest"}
if [ "$IPHONE_SDKVERSION" == "Latest" ]
then
	IPHONE_SDKVERSION=`xcodebuild -showsdks | grep iphoneos | sort | tail -n 1 | awk '{ print $2}'`
fi

: ${TARBALLDIR:=`pwd`}
: ${SRCDIR:=`pwd`/src}
: ${BUILDDIR:=`pwd`/build}
: ${BUILDTMPDIR:=${BUILDDIR}/tmp}
: ${PREFIXDIR:=`pwd`/prefix}
: ${FRAMEWORKDIR:=${PREFIXDIR}/framework}

LIBJSON_ZIPBALL=$TARBALLDIR/libjson.zip
LIBJSON_SRC=$SRCDIR/libjson

: ${BOOST_BJAM_MAX_PARALLEL_COMMANDS:=`sysctl hw.logicalcpu | awk '{print $2}'`}
#===============================================================================

: ${LIBJSON_OPTION_CLEAN:="true"}
: ${LIBJSON_OPTION_BUILD:="true"}

#===============================================================================

: ${DEVELOPER_DIR_PATH:="`xcode-select -print-path`"}

ARM_DEV_DIR=${DEVELOPER_DIR_PATH}/Platforms/iPhoneOS.platform/Developer
SIM_DEV_DIR=${DEVELOPER_DIR_PATH}/Platforms/iPhoneSimulator.platform/Developer

: ${ARM_SDK_DIR:="${ARM_DEV_DIR}/SDKs/iPhoneOS${IPHONE_SDKVERSION}.sdk"}
: ${SIM_SDK_DIR:="${SIM_DEV_DIR}/SDKs/iPhoneSimulator${IPHONE_SDKVERSION}.sdk"}

# GCC
#: ${COMPILER_CXX_ARM_PATH:="${ARM_DEV_DIR}/usr/bin/g++-4.2"}
#: ${COMPILER_CXX_SIM_PATH:="${SIM_DEV_DIR}/usr/bin/g++-4.2"}
#: ${COMPILER_CC_ARM_PATH:="${ARM_DEV_DIR}/usr/bin/gcc-4.2"}
#: ${COMPILER_CC_SIM_PATH:="${SIM_DEV_DIR}/usr/bin/gcc-4.2"}

# Clang
# Check Clang compiler location. It has changed since Xcode 4.5
CLANG="${DEVELOPER_DIR_PATH}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++"
if [ -f "$CLANG" ]
then
: ${COMPILER_CXX_ARM_PATH:="${DEVELOPER_DIR_PATH}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++"}
: ${COMPILER_CXX_SIM_PATH:="${DEVELOPER_DIR_PATH}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++"}
: ${COMPILER_CC_ARM_PATH:="${DEVELOPER_DIR_PATH}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"}
: ${COMPILER_CC_SIM_PATH:="${DEVELOPER_DIR_PATH}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"}
: ${IS_XCODE_45_OR_PLUS:=true}
else
: ${COMPILER_CXX_ARM_PATH:="${DEVELOPER_DIR_PATH}/usr/bin/clang++"}
: ${COMPILER_CXX_SIM_PATH:="${DEVELOPER_DIR_PATH}/usr/bin/clang++"}
: ${COMPILER_CC_ARM_PATH:="${DEVELOPER_DIR_PATH}/usr/bin/clang"}
: ${COMPILER_CC_SIM_PATH:="${DEVELOPER_DIR_PATH}/usr/bin/clang"}
: ${IS_XCODE_45_OR_PLUS:=false}
fi
# Compiler Version
compilerFileName=`basename "$COMPILER_CXX_ARM_PATH"`
if [[ $compilerFileName =~ ^g\+\+ ]]
then
: ${COMPILER_CXX_ARM_VERSION:=`$COMPILER_CXX_ARM_PATH -v 2>&1 | tail -1 | awk '{print $3}'`}
elif [[ $compilerFileName =~ ^clang ]]
then
: ${COMPILER_CXX_ARM_VERSION:=`$COMPILER_CXX_ARM_PATH -v 2>&1 | head -n 1 | awk '{print $4}'`}
fi

compilerFileName=`basename "$COMPILER_CC_ARM_PATH"`
if [[ $compilerFileName =~ ^gcc ]]
then
: ${COMPILER_CC_ARM_VERSION:=`$COMPILER_CC_ARM_PATH -v 2>&1 | tail -1 | awk '{print $3}'`}
elif [[ $compilerFileName =~ ^clang ]]
then
: ${COMPILER_CC_ARM_VERSION:=`$COMPILER_CC_ARM_PATH -v 2>&1 | head -n 1 | awk '{print $4}'`}
fi

compilerFileName=`basename "$COMPILER_CXX_SIM_PATH"`
if [[ $compilerFileName =~ ^g\+\+ ]]
then
: ${COMPILER_CXX_SIM_VERSION:=`$COMPILER_CXX_SIM_PATH -v 2>&1 | tail -1 | awk '{print $3}'`}
elif [[ $compilerFileName =~ ^clang ]]
then
: ${COMPILER_CXX_SIM_VERSION:=`$COMPILER_CXX_SIM_PATH -v 2>&1 | head -n 1 | awk '{print $4}'`}
fi

compilerFileName=`basename "$COMPILER_CC_SIM_PATH"`
if [[ $compilerFileName =~ ^gcc ]]
then
: ${COMPILER_CC_SIM_VERSION:=`$COMPILER_CC_SIM_PATH -v 2>&1 | tail -1 | awk '{print $3}'`}
elif [[ $compilerFileName =~ ^clang ]]
then
: ${COMPILER_CC_SIM_VERSION:=`$COMPILER_CC_SIM_PATH -v 2>&1 | head -n 1 | awk '{print $4}'`}
fi

ARM_COMBINED_LIB=$BUILDDIR/lib_json_arm.a
SIM_COMBINED_LIB=$BUILDDIR/lib_json_x86.a

#===============================================================================

echo "BUILDDIR:          $BUILDDIR"
echo "PREFIXDIR:         $PREFIXDIR"
echo "FRAMEWORKDIR:      $FRAMEWORKDIR"
echo "BUILDTMPDIR:       $BUILDTMPDIR"
echo "IPHONE_SDKVERSION: $IPHONE_SDKVERSION"
echo "COMPILER_CXX_SIM_PATH: $COMPILER_CXX_SIM_PATH"
echo "COMPILER_CXX_ARM_PATH: $COMPILER_CXX_ARM_PATH"
echo "COMPILER_CC_SIM_PATH:  $COMPILER_CC_SIM_PATH"
echo "COMPILER_CC_ARM_PATH:  $COMPILER_CC_ARM_PATH"
echo "COMPILER_CXX_ARM_VERSION: $COMPILER_CXX_ARM_VERSION"
echo "COMPILER_CXX_SIM_VERSION: $COMPILER_CXX_SIM_VERSION"
echo "COMPILER_CC_ARM_VERSION:  $COMPILER_CC_ARM_VERSION"
echo "COMPILER_CC_SIM_VERSION:  $COMPILER_CC_SIM_VERSION"
echo "LIBJSON_OPTION_CLEAN: $LIBJSON_OPTION_CLEAN"
echo "LIBJSON_OPTION_BUILD: $LIBJSON_OPTION_BUILD"
echo

#===============================================================================

ARCH_X86="x86"
ARCH_ARM="arm"

#===============================================================================
# Functions
#===============================================================================

end()
{
    echo
    echo "End: $@"
    exit 0
}

abort()
{
    echo
    echo "Aborted: $@"
    exit 1
}

doneSection()
{
    echo
    echo "    ================================================================="
    echo "    Done"
    echo
}

#===============================================================================
# Return 0 is library name has special name(s). 1 otherwise
isSpecialLibraryName()
{
    local libName="$1"
    local index=0
    local expectedLibName=""
    local count="${#LIBJSON_LIBS_SPECIAL_NAMES[@]}"
    local returnValue=1
    while [ $index -lt $count ]; do
        expectedLibName=${LIBJSON_LIBS_SPECIAL_NAMES[$index]}
        [ "$expectedLibName" == "$libName" ] && returnValue=0 && break
        let index++; let index++;
    done
    echo $returnValue;
}

#===============================================================================
getSpecialLibraryNames()
{
local libName="$1"
local libsNames=""
local expectedLibName=""
local currentLibName=""
local index=0
local count="${#LIBJSON_LIBS_SPECIAL_NAMES[@]}"
while [ $index -lt $count ]; do
    expectedLibName=${LIBJSON_LIBS_SPECIAL_NAMES[$index]}
    let index++
    currentLibName=${LIBJSON_LIBS_SPECIAL_NAMES[$index]}
    [ "$expectedLibName" == "$libName" ] && libsNames="$libsNames $currentLibName"
    let index++
done
echo "$libsNames"
}

#===============================================================================
getLibraryFilePath()
{
    local expectedLibName="$1"
    local currentLibName="$2"
    local arch="$3" # Supported values: i386,armv6, armv7
    local compilerFlags="$4" #Not used
    local compilerVersion="COMPILER_CXX_VERSION_UNDEFINED";
    local target="TARGET_UNDEFINED"
    local filePath="${BUILDTMPDIR}/${arch}/${expectedLibName}.a"
    echo "$filePath"
}

#===============================================================================
patchLibjson()
{
    case $LIBJSON_VERSION in
    7.6.1)
        echo Patching libjson ...
        # Patch created with: diff -uB src/libjson/makefile patch/libjson/makefile > patch/libjson/makefile.patch
        patch --verbose -p0 src/libjson/makefile < patch/libjson/makefile.patch

        # Patch created with: diff -uB src/libjson/JSONOptions.h patch/libjson/JSONOptions.h > patch/libjson/JSONOptions.h.patch
        patch --verbose -p0 src/libjson/JSONOptions.h < patch/libjson/JSONOptions.h.patch
		doneSection
	;;
    esac
}

#===============================================================================
cleanEverythingReadyToStart()
{
    echo Cleaning everything before we start to build...
    rm -rf $SRCDIR
    rm -rf $BUILDDIR
    rm -rf $BUILDTMPDIR
    rm -rf $PREFIXDIR
    rm -rf $FRAMEWORKDIR
    rm -fv $LIBJSON_ZIPBALL
    doneSection
}

#===============================================================================
downloadLibjson()
{
    if [ ! -f "$LIBJSON_ZIPBALL" ]
    then
        echo "Downloading libjson $LIBJSON_VERSION ..."
        curl --progress-bar -L -o ${LIBJSON_ZIPBALL} http://sourceforge.net/projects/libjson/files/libjson_${LIBJSON_VERSION}.zip/download
        doneSection
    else
        echo "libjson $LIBJSON_VERSION already donwloaded."
        echo ""
    fi
}

#===============================================================================
unpackLibjson()
{
    echo Unpacking libjson into $SRCDIR...
    [ -d $SRCDIR ]    || mkdir -p $SRCDIR
    [ -d $LIBJSON_SRC ] || ( cd $SRCDIR; unzip $LIBJSON_ZIPBALL -d $SRCDIR  )
    [ -d $LIBJSON_SRC ] && echo "    ...unpacked as $LIBJSON_SRC"
    doneSection
}

#===============================================================================

inventMissingHeaders()
{
    # These files are missing in the ARM iPhoneOS SDK, but they are in the simulator.
    # They are supported on the device, so we copy them from x86 SDK to a staging area
    # to use them on ARM, too.
    echo Invent missing headers
    cp /Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator${IPHONE_SDKVERSION}.sdk/usr/include/{crt_externs,bzlib}.h /tmp
}

#===============================================================================

setenv_all()
{
    local arch="$1"
    case $arch in
    $ARCH_ARM)
        export LD=${ARM_DEV_DIR}/usr/bin/ld
        export AR=${ARM_DEV_DIR}/usr/bin/ar
        export AS=${ARM_DEV_DIR}/usr/bin/as
        export NM=${ARM_DEV_DIR}/usr/bin/nm
        export RANLIB=${ARM_DEV_DIR}/usr/bin/ranlib
        export LDFLAGS="-L${ARM_SDK_DIR}/usr/lib/"
    ;;
    $ARCH_X86)
        export LD=${SIM_DEV_DIR}/usr/bin/ld
        export AR=${SIM_DEV_DIR}/usr/bin/ar
        export AS=${SIM_DEV_DIR}/usr/bin/as
        export NM=${SIM_DEV_DIR}/usr/bin/nm
        export RANLIB=${SIM_DEV_DIR}/usr/bin/ranlib
        export LDFLAGS="-L${SIM_SDK_DIR}/usr/lib/"
    ;;
    esac
}

setenv_armv6()
{
    #export CPPFLAGS="-I${ARM_SDK_DIR}/usr/lib/gcc/arm-apple-darwin10/${COMPILER_CXX_ARM_VERSION}/include/ -I${ARM_SDK_DIR}/usr/include/ -miphoneos-version-min=${IPHONE_SDKVERSION}"
    export CPPFLAGS="-v -miphoneos-version-min=${IPHONE_SDKVERSION}"
    export CFLAGS="$CPPFLAGS -fvisibility=hidden -arch armv6 -pipe -no-cpp-precomp -isysroot ${ARM_SDK_DIR}"
    export CPP="${ARM_DEV_DIR}/usr/bin/cpp $CPPFLAGS"
    export CXXFLAGSTMP="$CFLAGS -x c++"
    export CXX="${COMPILER_CXX_ARM_PATH}"
    export CC="${COMPILER_CC_ARM_PATH}"
    #    export PATH="/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin:/Developer/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

    setenv_all $ARCH_ARM
}

setenv_armv7()
{
    #export CPPFLAGS="-I${ARM_SDK_DIR}/usr/lib/gcc/arm-apple-darwin10/${COMPILER_CXX_ARM_VERSION}/include/ -I${ARM_SDK_DIR}/usr/include/ -miphoneos-version-min=${IPHONE_SDKVERSION}"
    export CPPFLAGS="-v -miphoneos-version-min=${IPHONE_SDKVERSION}"
    export CFLAGS="$CPPFLAGS -fvisibility=hidden -arch armv7 -pipe -no-cpp-precomp -isysroot ${ARM_SDK_DIR}"
    export CPP="${ARM_DEV_DIR}/usr/bin/cpp $CPPFLAGS"
    export CXXFLAGSTMP="$CFLAGS -x c++"
    export CXX="${COMPILER_CC_ARM_PATH}"
    export CC="${COMPILER_CC_ARM_PATH}"
    #    export PATH="/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin:/Developer/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
    setenv_all $ARCH_ARM
}

setenv_x86()
{
    #export CPPFLAGS="-I${ARM_SDK_DIR}/usr/lib/gcc/arm-apple-darwin10/${COMPILER_CXX_ARM_VERSION}/include/ -I${ARM_SDK_DIR}/usr/include/ -miphoneos-version-min=${IPHONE_SDKVERSION}"
    export CPPFLAGS="-v -D__IPHONE_OS_VERSION_MIN_REQUIRED=40300"
    export CFLAGS="$CPPFLAGS -fvisibility=hidden -arch i386 -pipe -no-cpp-precomp -isysroot ${SIM_SDK_DIR}"
    export CPP="${ARM_DEV_DIR}/usr/bin/cpp $CPPFLAGS"
    export CXXFLAGSTMP="$CFLAGS -x c++"
    export CXX="${COMPILER_CC_ARM_PATH}"
    export CC="${COMPILER_CC_ARM_PATH}"
    #    export PATH="/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin:/Developer/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
    setenv_all $ARCH_X86
}

#===============================================================================

buildLibJSONWithMakefile()
{
    local archName=$1
    local libName="libjson"
    # Static library generated by makefile
    LIBPATH_static="${libName}.a"

    # Use native makefile
    cd $LIBJSON_SRC
    export BUILD_TYPE="default";
    export SHARED=0;
    make clean
    make prefix=${PREFIXDIR} && make prefix=${PREFIXDIR} install
    cd ..

    mkdir -p "${BUILDTMPDIR}/${archName}"
    mv -v "${LIBJSON_SRC}/${LIBPATH_static}" "${BUILDTMPDIR}/${archName}/${libName}.a"
    LIBJSON_LIBS="${libName}"
}

#===============================================================================

buildLibjsonForiPhoneOS()
{
    EXTRA_ARM_COMPILE_FLAGS=""
    EXTRA_SIM_COMPILE_FLAGS=""
    case $LIBJSON_VERSION in
        6.7.1)
            EXTRA_ARM_COMPILE_FLAGS=""
            EXTRA_SIM_COMPILE_FLAGS=""
        ;;
    esac

	if [ $IS_XCODE_45_OR_PLUS == false ]
	then
		setenv_armv6
		buildLibJSONWithMakefile "armv6"
	fi
	
    setenv_armv7
    buildLibJSONWithMakefile "armv7"

    setenv_x86
    buildLibJSONWithMakefile "i386"

    doneSection
}

#===============================================================================

# $1: Name of a libjson library to lipoficate (technical term)
lipoficate()
{
    : ${1:?}
    NAME=$1
    echo liboficate: $1

    local expectedLibName=""
    local libsNames="$NAME"
    if [ `isSpecialLibraryName $NAME` -eq 0 ]
    then
	expectedLibName=$NAME
        libsNames=`getSpecialLibraryNames "$NAME"`
    fi

    for currentLibName in $libsNames; do
		if [ $IS_XCODE_45_OR_PLUS == false ]
		then
			ARMV6=`getLibraryFilePath "$NAME" "$currentLibName" "armv6" "$EXTRA_ARM_COMPILE_FLAGS"`
		else
			ARMV6=""
		fi
        ARMV7=`getLibraryFilePath "$NAME" "$currentLibName" "armv7" "$EXTRA_ARM_COMPILE_FLAGS"`
        I386=`getLibraryFilePath "$NAME" "$currentLibName" "i386" "$EXTRA_SIM_COMPILE_FLAGS"`

        mkdir -p $PREFIXDIR
		
		if [ $IS_XCODE_45_OR_PLUS == false ]
		then
			lipo \
            	-create \
				"$ARMV6" \
				"$ARMV7" \
				"$I386" \
				-o          "$PREFIXDIR/libjson.a" \
        	|| abort "Lipo $1 failed"
		else
			lipo \
            	-create \
				"$ARMV7" \
				"$I386" \
				-o          "$PREFIXDIR/libjson.a" \
        	|| abort "Lipo $1 failed"
		fi
		
    done
}

# This creates universal library
lipoLibsjon()
{
    for i in $LIBJSON_LIBS; do lipoficate $i; done;

    doneSection
}

#===============================================================================

                    VERSION_TYPE=Alpha
                  FRAMEWORK_NAME=libjson
               FRAMEWORK_VERSION=A

       FRAMEWORK_CURRENT_VERSION=$LIBJSON_VERSION
 FRAMEWORK_COMPATIBILITY_VERSION=$LIBJSON_VERSION

buildFramework()
{
    FRAMEWORK_BUNDLE=$FRAMEWORKDIR/$FRAMEWORK_NAME.framework

    rm -rf $FRAMEWORK_BUNDLE

    echo "Framework: Setting up directories..."
    mkdir -p $FRAMEWORK_BUNDLE
    mkdir -p $FRAMEWORK_BUNDLE/Versions
    mkdir -p $FRAMEWORK_BUNDLE/Versions/$FRAMEWORK_VERSION
    mkdir -p $FRAMEWORK_BUNDLE/Versions/$FRAMEWORK_VERSION/Resources
    mkdir -p $FRAMEWORK_BUNDLE/Versions/$FRAMEWORK_VERSION/Headers
    mkdir -p $FRAMEWORK_BUNDLE/Versions/$FRAMEWORK_VERSION/Documentation

    echo "Framework: Creating symlinks..."
    ln -s $FRAMEWORK_VERSION               $FRAMEWORK_BUNDLE/Versions/Current
    ln -s Versions/Current/Headers         $FRAMEWORK_BUNDLE/Headers
    ln -s Versions/Current/Resources       $FRAMEWORK_BUNDLE/Resources
    ln -s Versions/Current/Documentation   $FRAMEWORK_BUNDLE/Documentation
    ln -s Versions/Current/$FRAMEWORK_NAME $FRAMEWORK_BUNDLE/$FRAMEWORK_NAME

    FRAMEWORK_INSTALL_NAME=$FRAMEWORK_BUNDLE/Versions/$FRAMEWORK_VERSION/$FRAMEWORK_NAME

    echo "Lipoing library into $FRAMEWORK_INSTALL_NAME..."
	if [ $IS_XCODE_45_OR_PLUS == false ]
	then
		lipo \
        	-create \
			-arch armv6 "$BUILDTMPDIR/armv6/libjson.a" \
			-arch armv7 "$BUILDTMPDIR/armv7/libjson.a" \
			-arch i386  "$BUILDTMPDIR/i386/libjson.a" \
        	-o          "$FRAMEWORK_INSTALL_NAME" \
		|| abort "Lipo $1 failed"
	else
		lipo \
        	-create \
			-arch armv7 "$BUILDTMPDIR/armv7/libjson.a" \
			-arch i386  "$BUILDTMPDIR/i386/libjson.a" \
        	-o          "$FRAMEWORK_INSTALL_NAME" \
		|| abort "Lipo $1 failed"
	fi

    echo "Framework: Copying includes..."
    cp -r ${PREFIXDIR}/include/libjson/ $FRAMEWORK_BUNDLE/Headers

    echo "Framework: Creating plist..."
    cat > $FRAMEWORK_BUNDLE/Resources/Info.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>English</string>
	<key>CFBundleExecutable</key>
	<string>${FRAMEWORK_NAME}</string>
	<key>CFBundleIdentifier</key>
	<string>com.libjson</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundlePackageType</key>
	<string>FMWK</string>
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleVersion</key>
	<string>${FRAMEWORK_CURRENT_VERSION}</string>
</dict>
</plist>
EOF
    doneSection
}

#===============================================================================
# Execution starts here
#===============================================================================

[ "$LIBJSON_OPTION_CLEAN" == "true" ] && cleanEverythingReadyToStart;
[ "$LIBJSON_OPTION_BUILD" == "false" ] && end "Build not performed since LIBJSON_OPTION_BUILD=$LIBJSON_OPTION_BUILD";

downloadLibjson

[ -f "$LIBJSON_ZIPBALL" ] || abort "Source zipball missing."
mkdir -p $BUILDDIR

unpackLibjson && patchLibjson;

# NOT SURE ABOUT THIS ONE inventMissingHeaders

case $LIBJSON_VERSION in
    7.6.1)
        buildLibjsonForiPhoneOS
        ;;
    default)
        abort "This version ($LIBJSON_VERSION) is not supported"
        ;;
esac

lipoLibsjon
buildFramework

echo "Completed successfully"

#===============================================================================

