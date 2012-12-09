#
#  Makefile
#  Builds libjson
#
all: clean build

IPHONE_SDK_VERSION=Latest

# Current directory
ROOT_MAKEFILE_PATH="$(CURDIR)"

# Location where universal binary library will be installed by makefile
MAKEFILE_PREFIXDIR_PATH="$(ROOT_MAKEFILE_PATH)/prefix"

# Builds libjson (release) library
build:
		# Build universal binary
		export PREFIXDIR=$(MAKEFILE_PREFIXDIR_PATH) && export LIBJSON_OPTION_BUILD=true && export LIBJSON_OPTION_CLEAN=false && export IPHONE_SDKVERSION=$(IPHONE_SDK_VERSION) && bash ./libjson.sh

# Cleans libjson library
clean:
		export PREFIXDIR=$(MAKEFILE_PREFIXDIR_PATH) && export FRAMEWORKDIR=${MAKEFILE_FRAMEWORKDIR_PATH} && export LIBJSON_OPTION_BUILD=false && export LIBJSON_OPTION_CLEAN=true && export IPHONE_SDKVERSION=$(IPHONE_SDK_VERSION) && bash ./libjson.sh
		rm -rvf $(PREFIX_PATH)
