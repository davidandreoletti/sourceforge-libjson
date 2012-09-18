#
#  Makefile
#  Builds libjson
#
all: clean build

IPHONE_SDK_VERSION=5.1

# Current directory
ROOT_MAKEFILE_PATH="$(CURDIR)"

# Location where universal binary library will be installed by makefile
MAKEFILE_PREFIXDIR_PATH="$(ROOT_MAKEFILE_PATH)/build"
# Location where universal binary framwwork will be installed by makefile
MAKEFILE_FRAMEWORKDIR_PATH="$(MAKEFILE_PREFIXDIR_PATH)/framework"

# Location where release universal binaries will be installed (ready for dev to use)
PREFIX_PATH="$(CURDIR)/prefix"
RELEASE_PATH="$(PREFIX_PATH)"
# Location where universal binary release libraries/framework will be stored
RELEASE_FRAMEWORK_PATH=${RELEASE_PATH}/framework
RELEASE_LIB_PATH="$(RELEASE_PATH)/lib"

# Builds libjson (release) library
build:
		# Build universal binary
		export PREFIXDIR=$(MAKEFILE_PREFIXDIR_PATH) && export FRAMEWORKDIR=${MAKEFILE_FRAMEWORKDIR_PATH} && export LIBJSON_OPTION_BUILD=true && export LIBJSON_OPTION_CLEAN=false && export IPHONE_SDKVERSION=$(IPHONE_SDK_VERSION) && bash ./libjson.sh
		# Copy universal binary/framework to release directory
		mkdir -p ${RELEASE_FRAMEWORK_PATH}
		mkdir -p ${RELEASE_LIB_PATH}
		cp -r ${MAKEFILE_PREFIXDIR_PATH}/include ${RELEASE_LIB_PATH}/
		cp ${MAKEFILE_PREFIXDIR_PATH}/libjson.a ${RELEASE_LIB_PATH}/
		cp -r ${MAKEFILE_FRAMEWORKDIR_PATH}/* ${RELEASE_FRAMEWORK_PATH}/

# Cleans libjson library
clean:
		export PREFIXDIR=$(MAKEFILE_PREFIXDIR_PATH) && export FRAMEWORKDIR=${MAKEFILE_FRAMEWORKDIR_PATH} && export LIBJSON_OPTION_BUILD=false && export LIBJSON_OPTION_CLEAN=true && export IPHONE_SDKVERSION=$(IPHONE_SDK_VERSION) && bash ./libjson.sh
		rm -rvf $(PREFIX_PATH)
