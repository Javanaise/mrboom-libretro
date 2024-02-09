STATIC_LINKING := 0
AR             := ar
INSTALL        := install
RM             := rm
STRIP          := strip
BINDIR         ?= bin
LIBDIR         ?= lib
DATADIR        ?= share
LIBRETRO_DIR   ?= libretro
WANT_BPP       := 32
#DEBUG := 1

ifneq ($(SKIP_GIT),1)
GIT_VERSION := " $(shell git rev-parse --short HEAD)"
else 
GIT_VERSION := " "
endif


MANDIR := man/man6
CFLAGS := $(filter-out -D_FORTIFY_SOURCE=1,$(CFLAGS))
CFLAGS := $(filter-out -D_FORTIFY_SOURCE=2,$(CFLAGS))
CFLAGS := $(filter-out -D_FORTIFY_SOURCE,$(CFLAGS))
CXXFLAGS := $(filter-out -D_FORTIFY_SOURCE=1,$(CXXFLAGS))
CXXFLAGS := $(filter-out -D_FORTIFY_SOURCE=2,$(CXXFLAGS))
CXXFLAGS := $(filter-out -D_FORTIFY_SOURCE,$(CXXFLAGS))
CPPFLAGS := $(filter-out -D_FORTIFY_SOURCE=1,$(CPPFLAGS))
CPPFLAGS := $(filter-out -D_FORTIFY_SOURCE=2,$(CPPFLAGS))
CPPFLAGS := $(filter-out -D_FORTIFY_SOURCE,$(CPPFLAGS))

ifeq ($(platform),)
   platform = unix
   ifeq ($(shell uname -a),)
      platform = win
   else ifneq ($(findstring MINGW,$(shell uname -a)),)
      platform = win
   else ifneq ($(findstring Darwin,$(shell uname -a)),)
      platform = osx
   else ifneq ($(findstring win,$(shell uname -a)),)
      platform = win
   endif
endif

ifeq ($(platform), win)
   LDFLAGS += -liphlpapi -lws2_32 
endif

CORE_DIR = .
export DEPSDIR := $(CURDIR)/

# system platform
system_platform = unix
ifeq ($(shell uname -a),)
   EXE_EXT = .exe
   system_platform = win
else ifneq ($(findstring Darwin,$(shell uname -a)),)
   system_platform = osx
   arch = intel
   ifeq ($(shell uname -p),powerpc)
	arch = ppc
   endif
   ifeq ($(shell uname -p),arm)
	arch = arm
   endif
else ifneq ($(findstring FreeBSD,$(shell uname -o)),)
   system_platform = freebsd
   MANDIR = share/man/man6
else ifneq ($(findstring Haiku,$(shell uname -o)),)
   system_platform = haiku
else ifneq ($(findstring MINGW,$(shell uname -a)),)
   system_platform = win
endif

TARGET_NAME := mrboom


ifneq ($(SANITIZER),)
   CFLAGS   := -fsanitize=$(SANITIZER) $(CFLAGS)
   LDFLAGS  := -fsanitize=$(SANITIZER) $(LDFLAGS)
endif

ifeq ($(platform), unix)
   ifneq ($(LIBSDL2),)
      CFLAGS += $(shell sdl2-config --cflags)
      LDFLAGS += $(shell sdl2-config --libs)
   else ifneq ($(LIBSDL),)
      CFLAGS += $(shell sdl-config --cflags)
      LDFLAGS += $(shell sdl-config --libs)
   endif
endif

ifeq ($(STATIC_LINKING), 1)
   EXT := a
endif

ifeq ($(platform), unix)
   EXT ?= so
   TARGET := $(TARGET_NAME)_libretro.$(EXT)
   fpic := -fPIC
   SHARED := -shared -Wl,--version-script=$(CORE_DIR)/link.T -Wl,--no-undefined
   ifeq ($(system_platform), haiku)
      LDFLAGS += -lroot -lnetwork
   endif

else ifeq ($(platform), linux-portable)
   TARGET := $(TARGET_NAME)_libretro.$(EXT)
   fpic := -fPIC -nostdlib
   SHARED := -shared -Wl,--version-script=$(CORE_DIR)/link.T
   LIBM :=

# OS X
else ifneq (,$(findstring osx,$(platform)))
   TARGET := $(TARGET_NAME)_libretro.dylib
   fpic := -fPIC
   SHARED := -dynamiclib
   PREFIX := /usr/local
   MANDIR := share/man/man6

   ifeq ($(UNIVERSAL),1)
   ifeq ($(archs),ppc)
      ARCHFLAGS = -arch ppc -arch ppc64
   else ifeq ($(archs),arm64)
      ARCHFLAGS = -arch arm64 -arch x86_64
   else
      ARCHFLAGS = -arch i386 -arch x86_64
   endif
      CFLAGS += $(ARCHFLAGS)
      LFLAGS += $(ARCHFLAGS)
      ifneq ($(LIBSDL2),)
         CFLAGS += $(shell sdl2-config --cflags)
         LDFLAGS += $(shell sdl2-config --libs)
      endif
   endif


   ifeq ($(CROSS_COMPILE),1)
		TARGET_RULE   = -target $(LIBRETRO_APPLE_PLATFORM) -isysroot $(LIBRETRO_APPLE_ISYSROOT)
		CFLAGS   += $(TARGET_RULE)
		CPPFLAGS += $(TARGET_RULE)
		CXXFLAGS += $(TARGET_RULE)
		LDFLAGS  += $(TARGET_RULE)
   endif
   CFLAGS  += $(ARCHFLAGS)
   CXXFLAGS  += $(ARCHFLAGS)
   LDFLAGS += $(ARCHFLAGS)

# iOS
else ifneq (,$(findstring ios,$(platform)))
   TARGET := $(TARGET_NAME)_libretro_ios.dylib
   fpic := -fPIC
   SHARED := -dynamiclib
   MINVERSION :=
   ifeq ($(IOSSDK),)
      IOSSDK := $(shell xcodebuild -version -sdk iphoneos Path)
   endif
   DEFINES := -DIOS
   ifeq ($(platform),ios-arm64)
      CC = cc -arch arm64 -isysroot $(IOSSDK)
      CXX = c++ -arch arm64 -isysroot $(IOSSDK)
   else	
      CC = cc -arch armv7 -isysroot $(IOSSDK)
      CXX = c++ -arch armv7 -isysroot $(IOSSDK)
   endif
   ifeq ($(platform),$(filter $(platform),ios9 ios-arm64))
      MINVERSION = -miphoneos-version-min=8.0
   else
      MINVERSION = -miphoneos-version-min=5.0
   endif
   CFLAGS += $(MINVERSION) -DIOS

# tvOS
else ifeq ($(platform), tvos-arm64)
   TARGET := $(TARGET_NAME)_libretro_tvos.dylib
   fpic := -fPIC
   SHARED := -dynamiclib
   DEFINES := -DIOS
   ifeq ($(IOSSDK),)
      IOSSDK := $(shell xcodebuild -version -sdk appletvos Path)
   endif
   CC = cc -arch arm64 -isysroot $(IOSSDK)
   CXX = c++ -arch arm64 -isysroot $(IOSSDK)

# QNX
else ifneq (,$(findstring qnx,$(platform)))
   TARGET := $(TARGET_NAME)_libretro_qnx.so
   fpic := -fPIC
   SHARED := -shared -Wl,--version-script=$(CORE_DIR)/link.T -Wl,--no-undefined
   CFLAGS += -D_POSIX_C_SOURCE=200112L
   LDFLAGS += -lsocket
   CC = qcc -Vgcc_ntoarmv7le
   CXX = QCC -Vgcc_ntoarmv7le

# Emscripten
else ifeq ($(platform), emscripten)
   TARGET := $(TARGET_NAME)_libretro_emscripten.bc
   fpic := -fPIC
   SHARED := -shared
   AR=emar
   STATIC_LINKING := 1
   CFLAGS += -DNO_NETWORK

# PS2
else ifeq ($(platform), ps2)
   TARGET := $(TARGET_NAME)_libretro_$(platform).a
   CC = mips64r5900el-ps2-elf-gcc
   CXX = mips64r5900el-ps2-elf-c++
   AR = mips64r5900el-ps2-elf-ar
   CFLAGS += $(DEFINES) -DPS2 -Wall -G0 -DNO_NETWORK -DABGR1555
	CXXFLAGS += $(CFLAGS)
	STATIC_LINKING = 1
   WANT_BPP := 16

# PSP
else ifeq ($(platform), psp1)
   TARGET := $(TARGET_NAME)_libretro_$(platform).a
   CC = psp-gcc
   CXX = psp-c++
   AR = psp-ar
   CFLAGS += $(DEFINES) -Wall -G0 -DNO_NETWORK -Werror -Wcast-align
   CXXFLAGS += $(DEFINES) -Wall -G0 -DNO_NETWORK -Werror -Wcast-align -Wno-long-long
   STATIC_LINKING = 1

# Vita
else ifeq ($(platform), vita)
   TARGET := $(TARGET_NAME)_libretro_$(platform).a
   CC = arm-vita-eabi-gcc
   CXX = arm-vita-eabi-c++
   AR = arm-vita-eabi-ar
   CFLAGS += $(DEFINES) -Wall -DVITA
   CXXFLAGS += $(CFLAGS)
   STATIC_LINKING = 1

# Nintendo Game Cube / Wii / WiiU
else ifneq (,$(filter $(platform), ngc wii wiiu))
   TARGET := $(TARGET_NAME)_libretro_$(platform).a
   CC = $(DEVKITPPC)/bin/powerpc-eabi-gcc$(EXE_EXT)
   CXX = $(DEVKITPPC)/bin/powerpc-eabi-g++$(EXE_EXT)
   AR = $(DEVKITPPC)/bin/powerpc-eabi-ar$(EXE_EXT)
   CFLAGS += -mcpu=750 -meabi -mhard-float -D__ppc__
   CFLAGS += -DUSE_FILE32API -DNO_NETWORK
   CFLAGS += -U__INT32_TYPE__ -U __UINT32_TYPE__ -D__INT32_TYPE__=int
   STATIC_LINKING=1

   # Nintendo WiiU	
   ifneq (,$(findstring wiiu,$(platform)))	
      CFLAGS += -mwup
      
   # Nintendo Wii
   else ifneq (,$(findstring wii,$(platform)))
      CFLAGS += -DGEKKO -mrvl

   # Nintendo Game Cube
   else ifneq (,$(findstring ngc,$(platform)))
      CFLAGS += -DGEKKO -mrvl
   endif

# GCW0
else ifeq ($(platform), gcw0)
   TARGET := $(TARGET_NAME)_libretro.so
   CC = /opt/gcw0-toolchain/usr/bin/mipsel-linux-gcc
   CXX = /opt/gcw0-toolchain/usr/bin/mipsel-linux-g++
   AR = /opt/gcw0-toolchain/usr/bin/mipsel-linux-ar
   fpic := -fPIC
   SHARED := -shared -Wl,--no-undefined -Wl,-version-script=$(CORE_DIR)/link.T
   FLAGS += -DDINGUX -fomit-frame-pointer -ffast-math -march=mips32 -mtune=mips32r2 -mhard-float
   WANT_BPP := 16

# Miyoo
else ifeq ($(platform), miyoo)
   TARGET := $(TARGET_NAME)_libretro.so
   CC = /opt/miyoo/usr/bin/arm-linux-gcc
   CXX = /opt/miyoo/usr/bin/arm-linux-g++
   AR = /opt/miyoo/usr/bin/arm-linux-ar
   fpic := -fPIC
   SHARED := -shared -Wl,--no-undefined -Wl,-version-script=$(CORE_DIR)/link.T
   FLAGS += -fomit-frame-pointer -ffast-math -mcpu=arm926ej-s
   WANT_BPP := 16

# Nintendo Switch (libnx)
else ifeq ($(platform), libnx)
   include $(DEVKITPRO)/libnx/switch_rules
   EXT=a
   TARGET := $(TARGET_NAME)_libretro_$(platform).$(EXT)
   DEFINES := -DSWITCH=1 -U__linux__ -U__linux
   CFLAGS	:= $(DEFINES) -g -O3 \
                -fPIE -I$(LIBNX)/include/ -ffunction-sections -fdata-sections -ftls-model=local-exec -Wl,--allow-multiple-definition -specs=$(LIBNX)/switch.specs
   CFLAGS += $(INCDIRS)
   CFLAGS += -D__SWITCH__ -DHAVE_LIBNX -march=armv8-a -mtune=cortex-a57 -mtp=soft
   CXXFLAGS := $(ASFLAGS) -fno-rtti -std=gnu++11
   CFLAGS += -std=gnu11
   CFLAGS += -DUSE_FILE32API
   STATIC_LINKING = 1

# Nintendo Switch (libtransistor)
else ifeq ($(platform), switch)
   TARGET := $(TARGET_NAME)_libretro_$(platform).a
   include $(LIBTRANSISTOR_HOME)/libtransistor.mk
   CFLAGS += $(CXX_FLAGS)
   STATIC_LINKING=1

# CTR (3DS)
else ifeq ($(platform), ctr)
   TARGET := $(TARGET_NAME)_libretro_$(platform).a
   CC = $(DEVKITARM)/bin/arm-none-eabi-gcc$(EXE_EXT)
   CXX = $(DEVKITARM)/bin/arm-none-eabi-g++$(EXE_EXT)
   AR = $(DEVKITARM)/bin/arm-none-eabi-ar$(EXE_EXT)
   DEFINES += -D_3DS -DARM11 -march=armv6k -mtune=mpcore -mfloat-abi=hard
   CFLAGS += $(DEFINES) -DNO_NETWORK
   CXXFLAGS += $(CFLAGS)
   STATIC_LINKING = 1

# Lightweight PS3 Homebrew SDK
else ifeq ($(platform), psl1ght)
   TARGET := $(TARGET_NAME)_libretro_$(platform).a
   CC = $(PS3DEV)/ppu/bin/ppu-gcc$(EXE_EXT)
   CXX = $(PS3DEV)/ppu/bin/ppu-g++$(EXE_EXT)
   CC_AS = $(PS3DEV)/ppu/bin/ppu-gcc$(EXE_EXT)
   AR = $(PS3DEV)/ppu/bin/ppu-ar$(EXE_EXT)
   CFLAGS += -D__CELLOS_LV2__ -D__PSL1GHT__ -mcpu=cell
   CFLAGS += -DUSE_FILE32API -DNO_NETWORK
   STATIC_LINKING = 1

# Classic Platforms ####################
# Platform affix = classic_<ISA>_<µARCH>
# Help at https://modmyclassic.com/comp

# (armv7 a7, hard point, neon based) ### 
# NESC, SNESC, C64 mini 
else ifeq ($(platform), classic_armv7_a7)
   TARGET := $(TARGET_NAME)_libretro.so
   fpic := -fPIC
   LDFLAGS := -shared -Wl,--version-script=$(CORE_DIR)/link.T  -Wl,--no-undefined
   CFLAGS += -Ofast \
      -flto=4 -fwhole-program -fuse-linker-plugin \
      -fdata-sections -ffunction-sections -Wl,--gc-sections \
      -fno-stack-protector -fno-ident -fomit-frame-pointer \
      -falign-functions=1 -falign-jumps=1 -falign-loops=1 \
      -fno-unwind-tables -fno-asynchronous-unwind-tables -fno-unroll-loops \
      -fmerge-all-constants -fno-math-errno \
      -marm -mtune=cortex-a7 -mfpu=neon-vfpv4 -mfloat-abi=hard
   CXXFLAGS += $(CFLAGS)
   CPPFLAGS += $(CFLAGS)
   ASFLAGS += $(CFLAGS)
   HAVE_NEON = 1
   ifeq ($(shell echo `$(CC) -dumpversion` "< 4.9" | bc -l), 1)
      CFLAGS += -march=armv7-a
   else
      CFLAGS += -march=armv7ve
      # If gcc is 5.0 or later
      ifeq ($(shell echo `$(CC) -dumpversion` ">= 5" | bc -l), 1)
         LDFLAGS += -static-libgcc -static-libstdc++
      endif
   endif
#######################################

else ifeq ($(platform), genode)
   TARGET   := $(TARGET_NAME)_libretro.lib.so
   CC       := $(shell pkg-config genode-base --variable=cc)
   CXX      := $(shell pkg-config genode-base --variable=cxx)
   LD       := $(shell pkg-config genode-base --variable=ld)
   CFLAGS   += $(shell pkg-config --cflags genode-libc)
   CXXFLAGS += $(shell pkg-config --cflags genode-stdcxx)
   LDFLAGS  += -shared --version-script=link.T
   LDFLAGS  += $(shell pkg-config --libs genode-lib genode-libc genode-stdcxx)
   LIBM =

else ifeq ($(platform), unix-armv7-hardfloat-neon)
   TARGET := $(TARGET_NAME)_libretro.so
   fpic := -fPIC
   SHARED := -shared -Wl,--version-script=$(CORE_DIR)/link.T  -Wl,--no-undefined
   LDFLAGS += -lm -lpthread
   CFLAGS += -marm -march=armv7-a -mtune=cortex-a7 -mfpu=neon-vfpv4 -mfloat-abi=hard
   PLATFLAGS += -DRETRO -DALIGN_DWORD -DARM
   HAVE_NEON = 1

# Windows MSVC 2003 Xbox 1
else ifeq ($(platform), xbox1_msvc2003)
   TARGET := $(TARGET_NAME)_libretro_xdk1.lib
   CC   = CL.exe
   CXX  = CL.exe
   LD   = lib.exe
   export INCLUDE := $(XDK)/xbox/include
   export LIB := $(XDK)/xbox/lib
   PATH := $(call unixcygpath,$(XDK)/xbox/bin/vc71):$(PATH)
   CFLAGS   += -D_XBOX -D_XBOX1 -DNOMINMAX
   STATIC_LINKING=1
   HAS_GCC := 0

# Windows MSVC 2010 Xbox 360
else ifeq ($(platform), xbox360_msvc2010)
   TARGET := $(TARGET_NAME)_libretro_xdk360.lib
   MSVCBINDIRPREFIX = $(XEDK)/bin/win32
   CC   = "$(MSVCBINDIRPREFIX)/cl.exe"
   CXX  = "$(MSVCBINDIRPREFIX)/cl.exe"
   LD   = "$(MSVCBINDIRPREFIX)/lib.exe"

   export INCLUDE := $(XEDK)/include/xbox
   export LIB := $(XEDK)/lib/xbox
   CFLAGS   += -D_XBOX -D_XBOX1 -DNOMINMAX
   STATIC_LINKING=1
   HAS_GCC := 0

# Windows MSVC 2003 x86
else ifeq ($(platform), windows_msvc2003_x86)
   CC  = cl.exe
   CXX = cl.exe
   LD  = link.exe

   CFLAGS += -DNOMINMAX
   PATH := $(shell IFS=$$'\n'; cygpath "$(VS71COMNTOOLS)../../Vc7/bin"):$(PATH)
   PATH := $(PATH):$(shell IFS=$$'\n'; cygpath "$(VS71COMNTOOLS)../IDE")
   INCLUDE := $(shell IFS=$$'\n'; cygpath "$(VS71COMNTOOLS)../../Vc7/include")
   LIB := $(shell IFS=$$'\n'; cygpath -w "$(VS71COMNTOOLS)../../Vc7/lib")
   BIN := $(shell IFS=$$'\n'; cygpath "$(VS71COMNTOOLS)../../Vc7/bin")

   WindowsSdkDir := $(INETSDK)

   export INCLUDE := $(INCLUDE);$(INETSDK)/Include;src/drivers/libretro/msvc/msvc-2005
   export LIB := $(LIB);$(WindowsSdkDir);$(INETSDK)/Lib
   TARGET := $(TARGET_NAME)_libretro.dll
   LDFLAGS += -DLL ws2_32.lib
   CFLAGS += -D_CRT_SECURE_NO_DEPRECATE

# Windows MSVC 2005 x86
else ifeq ($(platform), windows_msvc2005_x86)
   CC  = cl.exe
   CXX = cl.exe
   LD  = link.exe

   CFLAGS += -DNOMINMAX
   PATH := $(shell IFS=$$'\n'; cygpath "$(VS80COMNTOOLS)../../VC/bin"):$(PATH)
   PATH := $(PATH):$(shell IFS=$$'\n'; cygpath "$(VS80COMNTOOLS)../IDE")
   INCLUDE := $(shell IFS=$$'\n'; cygpath "$(VS80COMNTOOLS)../../VC/include")
   LIB := $(shell IFS=$$'\n'; cygpath -w "$(VS80COMNTOOLS)../../VC/lib")
   BIN := $(shell IFS=$$'\n'; cygpath "$(VS80COMNTOOLS)../../VC/bin")

#WindowsSdkDir := $(shell reg query "HKLM\SOFTWARE\Microsoft\MicrosoftSDK\InstalledSDKs\8F9E5EF3-A9A5-491B-A889-C58EFFECE8B3" -v "Install Dir" | grep -o '[A-Z]:\\.*')
WindowsSdkDir := $(shell reg query "HKLM\SOFTWARE\Microsoft\Microsoft SDKs\Windows\v7.1A" -v "InstallationFolder" | grep -o '[A-Z]:\\.*')
WindowsSdkDir ?= $(shell reg query "HKLM\SOFTWARE\Microsoft\Microsoft SDKs\Windows\v7.0A" -v "InstallationFolder" | grep -o '[A-Z]:\\.*')

WindowsSDKIncludeDir := $(shell cygpath -w "$(WindowsSdkDir)\Include")
WindowsSDKAtlIncludeDir := $(shell cygpath -w "$(WindowsSdkDir)\Include\atl")
WindowsSDKCrtIncludeDir := $(shell cygpath -w "$(WindowsSdkDir)\Include\crt")
WindowsSDKGlIncludeDir := $(shell cygpath -w "$(WindowsSdkDir)\Include\gl")
WindowsSDKMfcIncludeDir := $(shell cygpath -w "$(WindowsSdkDir)\Include\mfc")
WindowsSDKLibDir := $(shell cygpath -w "$(WindowsSdkDir)\Lib")

export INCLUDE := $(INCLUDE);$(WindowsSDKIncludeDir);$(WindowsSDKAtlIncludeDir);$(WindowsSDKCrtIncludeDir);$(WindowsSDKGlIncludeDir);$(WindowsSDKMfcIncludeDir);libretro-common/include/compat/msvc
export LIB := $(LIB);$(WindowsSDKLibDir)
   TARGET := $(TARGET_NAME)_libretro.dll
   LDFLAGS += -DLL ws2_32.lib
   CFLAGS += -D_CRT_SECURE_NO_DEPRECATE
   LIBS =

# Windows MSVC 2010 x86
else ifeq ($(platform), windows_msvc2010_x86)
   CC  = cl.exe
   CXX = cl.exe
   LD  = link.exe

   CFLAGS += -DNOMINMAX
   PATH := $(shell IFS=$$'\n'; cygpath "$(VS100COMNTOOLS)../../VC/bin"):$(PATH)
   PATH := $(PATH):$(shell IFS=$$'\n'; cygpath "$(VS100COMNTOOLS)../IDE")
   LIB := $(shell IFS=$$'\n'; cygpath -w "$(VS100COMNTOOLS)../../VC/lib")
   INCLUDE := $(shell IFS=$$'\n'; cygpath "$(VS100COMNTOOLS)../../VC/include")

WindowsSdkDir := $(shell reg query "HKLM\SOFTWARE\Microsoft\Microsoft SDKs\Windows\v7.1A" -v "InstallationFolder" | grep -o '[A-Z]:\\.*')
WindowsSdkDir ?= $(shell reg query "HKLM\SOFTWARE\Microsoft\Microsoft SDKs\Windows\v7.0A" -v "InstallationFolder" | grep -o '[A-Z]:\\.*')

WindowsSDKIncludeDir := $(shell cygpath -w "$(WindowsSdkDir)\Include")
WindowsSDKAtlIncludeDir := $(shell cygpath -w "$(WindowsSdkDir)\Include\atl")
WindowsSDKCrtIncludeDir := $(shell cygpath -w "$(WindowsSdkDir)\Include\crt")
WindowsSDKGlIncludeDir := $(shell cygpath -w "$(WindowsSdkDir)\Include\gl")
WindowsSDKMfcIncludeDir := $(shell cygpath -w "$(WindowsSdkDir)\Include\mfc")
WindowsSDKLibDir := $(shell cygpath -w "$(WindowsSdkDir)\Lib")

INCFLAGS_PLATFORM = -I"$(WindowsSDKIncludeDir)"

export INCLUDE := $(INCLUDE);$(WindowsSDKIncludeDir);$(WindowsSDKAtlIncludeDir);$(WindowsSDKCrtIncludeDir);$(WindowsSDKGlIncludeDir);$(WindowsSDKMfcIncludeDir);libretro-common/include/compat/msvc
export LIB := $(LIB);$(WindowsSDKLibDir)
   TARGET := $(TARGET_NAME)_libretro.dll
   LDFLAGS += -DLL ws2_32.lib
   CFLAGS += -D_CRT_SECURE_NO_DEPRECATE

# Windows MSVC 2010 x64
else ifeq ($(platform), windows_msvc2010_x64)
   CC  = cl.exe
   CXX = cl.exe
   LD  = link.exe

   CFLAGS += -DNOMINMAX
   PATH := $(shell IFS=$$'\n'; cygpath "$(VS100COMNTOOLS)../../VC/bin/amd64"):$(PATH)
   PATH := $(PATH):$(shell IFS=$$'\n'; cygpath "$(VS100COMNTOOLS)../IDE")
   LIB := $(shell IFS=$$'\n'; cygpath "$(VS100COMNTOOLS)../../VC/lib/amd64")
   INCLUDE := $(shell IFS=$$'\n'; cygpath "$(VS100COMNTOOLS)../../VC/include")

WindowsSdkDir := $(shell reg query "HKLM\SOFTWARE\Microsoft\Microsoft SDKs\Windows\v7.0A" -v "InstallationFolder" | grep -o '[A-Z]:\\.*')
WindowsSdkDir ?= $(shell reg query "HKLM\SOFTWARE\Microsoft\Microsoft SDKs\Windows\v7.1A" -v "InstallationFolder" | grep -o '[A-Z]:\\.*')

WindowsSDKIncludeDir := $(shell cygpath -w "$(WindowsSdkDir)\Include")
WindowsSDKAtlIncludeDir := $(shell cygpath -w "$(WindowsSdkDir)\Include\atl")
WindowsSDKCrtIncludeDir := $(shell cygpath -w "$(WindowsSdkDir)\Include\crt")
WindowsSDKGlIncludeDir := $(shell cygpath -w "$(WindowsSdkDir)\Include\gl")
WindowsSDKMfcIncludeDir := $(shell cygpath -w "$(WindowsSdkDir)\Include\mfc")
WindowsSDKLibDir := $(shell cygpath -w "$(WindowsSdkDir)\Lib")

INCFLAGS_PLATFORM = -I"$(WindowsSDKIncludeDir)"


INCFLAGS_PLATFORM = -I"$(WindowsSDKIncludeDir)"
export INCLUDE := $(INCLUDE);$(WindowsSDKIncludeDir);$(WindowsSDKAtlIncludeDir);$(WindowsSDKCrtIncludeDir);$(WindowsSDKGlIncludeDir);$(WindowsSDKMfcIncludeDir);libretro-common/include/compat/msvc
export LIB := $(LIB);$(WindowsSDKLibDir)
   TARGET := $(TARGET_NAME)_libretro.dll
   LDFLAGS += -DLL ws2_32.lib
   CFLAGS += -D_CRT_SECURE_NO_DEPRECATE

# Windows MSVC 2017 all architectures
else ifneq (,$(findstring windows_msvc2017,$(platform)))
   PlatformSuffix = $(subst windows_msvc2017_,,$(platform))
   ifneq (,$(findstring desktop,$(PlatformSuffix)))
      WinPartition = desktop
      MSVC2017CompileFlags = -DWINAPI_FAMILY=WINAPI_FAMILY_DESKTOP_APP -FS
      LDFLAGS += -MANIFEST -LTCG:incremental -NXCOMPAT -DYNAMICBASE -DEBUG -OPT:REF -INCREMENTAL:NO -SUBSYSTEM:WINDOWS -MANIFESTUAC:"level='asInvoker' uiAccess='false'" -OPT:ICF -ERRORREPORT:PROMPT -NOLOGO -TLBID:1
      LIBS += kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib
   else ifneq (,$(findstring uwp,$(PlatformSuffix)))
      WinPartition = uwp
      MSVC2017CompileFlags = -DWINAPI_FAMILY=WINAPI_FAMILY_APP -D_WINDLL -D_UNICODE -DUNICODE -D__WRL_NO_DEFAULT_LIB__ -EHsc -FS
      LDFLAGS += -APPCONTAINER -NXCOMPAT -DYNAMICBASE -MANIFEST:NO -LTCG -OPT:REF -SUBSYSTEM:CONSOLE -MANIFESTUAC:NO -OPT:ICF -ERRORREPORT:PROMPT -NOLOGO -TLBID:1 -DEBUG:FULL -WINMD:NO
      LIBS += WindowsApp.lib
   endif

   CFLAGS += $(MSVC2017CompileFlags) -DNOMINMAX

   TargetArchMoniker = $(subst $(WinPartition)_,,$(PlatformSuffix))

   CC  = cl.exe
   CXX = cl.exe
   LD = link.exe

   reg_query = $(call filter_out2,$(subst $2,,$(shell reg query "$2" -v "$1" 2>nul)))
   fix_path = $(subst $(SPACE),\ ,$(subst \,/,$1))

   ProgramFiles86w := $(shell cmd //c "echo %PROGRAMFILES(x86)%")
   ProgramFiles86 := $(shell cygpath "$(ProgramFiles86w)")

   WindowsSdkDir ?= $(call reg_query,InstallationFolder,HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Microsoft SDKs\Windows\v10.0)
   WindowsSdkDir ?= $(call reg_query,InstallationFolder,HKEY_CURRENT_USER\SOFTWARE\Wow6432Node\Microsoft\Microsoft SDKs\Windows\v10.0)
   WindowsSdkDir ?= $(call reg_query,InstallationFolder,HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SDKs\Windows\v10.0)
   WindowsSdkDir ?= $(call reg_query,InstallationFolder,HKEY_CURRENT_USER\SOFTWARE\Microsoft\Microsoft SDKs\Windows\v10.0)
   WindowsSdkDir := $(WindowsSdkDir)

   WindowsSDKVersion ?= $(firstword $(foreach folder,$(subst $(subst \,/,$(WindowsSdkDir)Include/),,$(wildcard $(call fix_path,$(WindowsSdkDir)Include\*))),$(if $(wildcard $(call fix_path,$(WindowsSdkDir)Include/$(folder)/um/Windows.h)),$(folder),)))$(BACKSLASH)
   WindowsSDKVersion := $(WindowsSDKVersion)

   VsInstallBuildTools = $(ProgramFiles86)/Microsoft Visual Studio/2017/BuildTools
   VsInstallEnterprise = $(ProgramFiles86)/Microsoft Visual Studio/2017/Enterprise
   VsInstallProfessional = $(ProgramFiles86)/Microsoft Visual Studio/2017/Professional
   VsInstallCommunity = $(ProgramFiles86)/Microsoft Visual Studio/2017/Community

   VsInstallRoot ?= $(shell if [ -d "$(VsInstallBuildTools)" ]; then echo "$(VsInstallBuildTools)"; fi)
   ifeq ($(VsInstallRoot), )
      VsInstallRoot = $(shell if [ -d "$(VsInstallEnterprise)" ]; then echo "$(VsInstallEnterprise)"; fi)
   endif
   ifeq ($(VsInstallRoot), )
      VsInstallRoot = $(shell if [ -d "$(VsInstallProfessional)" ]; then echo "$(VsInstallProfessional)"; fi)
   endif
   ifeq ($(VsInstallRoot), )
      VsInstallRoot = $(shell if [ -d "$(VsInstallCommunity)" ]; then echo "$(VsInstallCommunity)"; fi)
   endif
   VsInstallRoot := $(VsInstallRoot)

   VcCompilerToolsVer := $(shell cat "$(VsInstallRoot)/VC/Auxiliary/Build/Microsoft.VCToolsVersion.default.txt" | grep -o '[0-9\.]*')
   VcCompilerToolsDir := $(VsInstallRoot)/VC/Tools/MSVC/$(VcCompilerToolsVer)

   WindowsSDKSharedIncludeDir := $(shell cygpath -w "$(WindowsSdkDir)\Include\$(WindowsSDKVersion)\shared")
   WindowsSDKUCRTIncludeDir := $(shell cygpath -w "$(WindowsSdkDir)\Include\$(WindowsSDKVersion)\ucrt")
   WindowsSDKUMIncludeDir := $(shell cygpath -w "$(WindowsSdkDir)\Include\$(WindowsSDKVersion)\um")
   WindowsSDKUCRTLibDir := $(shell cygpath -w "$(WindowsSdkDir)\Lib\$(WindowsSDKVersion)\ucrt\$(TargetArchMoniker)")
   WindowsSDKUMLibDir := $(shell cygpath -w "$(WindowsSdkDir)\Lib\$(WindowsSDKVersion)\um\$(TargetArchMoniker)")

   # For some reason the HostX86 compiler doesn't like compiling for x64
   # ("no such file" opening a shared library), and vice-versa.
   # Work around it for now by using the strictly x86 compiler for x86, and x64 for x64.
   # NOTE: What about ARM?
   ifneq (,$(findstring x64,$(TargetArchMoniker)))
      VCCompilerToolsBinDir := $(VcCompilerToolsDir)\bin\HostX64
   else
      VCCompilerToolsBinDir := $(VcCompilerToolsDir)\bin\HostX86
   endif

   PATH := $(shell IFS=$$'\n'; cygpath "$(VCCompilerToolsBinDir)/$(TargetArchMoniker)"):$(PATH)
   PATH := $(PATH):$(shell IFS=$$'\n'; cygpath "$(VsInstallRoot)/Common7/IDE")
   INCLUDE := $(shell IFS=$$'\n'; cygpath -w "$(VcCompilerToolsDir)/include")
   LIB := $(shell IFS=$$'\n'; cygpath -w "$(VcCompilerToolsDir)/lib/$(TargetArchMoniker)")
   ifneq (,$(findstring uwp,$(PlatformSuffix)))
      LIB := $(shell IFS=$$'\n'; cygpath -w "$(LIB)/store")
   endif

   export INCLUDE := $(INCLUDE);$(WindowsSDKSharedIncludeDir);$(WindowsSDKUCRTIncludeDir);$(WindowsSDKUMIncludeDir)
   export LIB := $(LIB);$(WindowsSDKUCRTLibDir);$(WindowsSDKUMLibDir)
   TARGET := $(TARGET_NAME)_libretro.dll
   LDFLAGS += -DLL ws2_32.lib
	
else
   CC ?= gcc
   TARGET := $(TARGET_NAME)_libretro.dll
   SHARED := -shared -static-libgcc -static-libstdc++ -s -Wl,--version-script=$(CORE_DIR)/link.T -Wl,--no-undefined
   WINSOCKS := -lws2_32
endif

ifeq (,$(findstring msvc,$(platform)))
LIBM    ?= -lm
LDFLAGS += $(LIBM)
endif

ifneq ($(LOAD_FROM_FILES),)
   CFLAGS += -DLOAD_FROM_FILES
   LDFLAGS += -lminizip
endif

ifneq ($(DEBUG),)
   CFLAGS += -g -pg -DDEBUG
   LDFLAGS += -g -pg
else
   ifneq ($(system_platform),freebsd)
      ifeq ($(FALCON),)
         CFLAGS += -O3
      else
         ifneq ($(PADDING_FALCON),)
            CFLAGS += -DPADDING_FALCON=$(PADDING_FALCON) 
         endif
         LDFLAGS += -Wl,-Map,f.map
         CFLAGS += -O3
	  endif
   endif
endif

CFLAGS += -DMRBOOM -DHAVE_IBXM -D_FORTIFY_SOURCE=0 -DPLATFORM=\"$(platform)\" -DGIT_VERSION=\"$(GIT_VERSION)\"

ifneq ($(FALCON),)
   SDLLIBS := -mshort -L/usr/m68k-atari-mint/sys-root/usr/lib/m68020-60 -lSDL_mixer -lSDL -lSDLmain -lFLAC -lmikmod -lgem -lldg  -lgem -lm -lvorbisfile -lvorbis -logg -lmpg123 
else
   SDLLIBS :=  -lSDL_mixer -lSDL -lSDLmain
   ifeq ($(platform), osx)
      SDLLIBS += -framework Cocoa -L/usr/local/lib
   endif
endif

ifneq (,$(findstring msvc,$(platform)))
   ifeq ($(DEBUG), 1)
      CFLAGS += -MTd -Od -Zi -DDEBUG -D_DEBUG
   else
      CFLAGS += -MT -O2 -DNDEBUG
   endif
   OBJOUT = -Fo
else
   OBJOUT = -o
endif

include Makefile.common
OBJECTS := $(SOURCES_CXX:.cpp=.o) $(SOURCES_C:.c=.o) $(SOURCES_ASM:.S=.o)


ifneq ($(LIBSDL2),)
   CFLAGS += -D__LIBSDL2__ -DLOAD_FROM_FILES -Isdl2/xBRZ -I/usr/local/include -I/opt/homebrew/include
   CFLAGS += $(shell sdl2-config --cflags)
   ifneq ($(MINGW),)
      PATH := /${MINGW}/bin:${PATH}
      CFLAGS += -I/${MINGW}/include
      LDFLAGS += -L/${MINGW}/lib -static-libgcc -static-libstdc++ -Wl,-Bstatic -lstdc++ -lpthread -lstdc++ -lmingw32 -lSDL2main  -lSDL2  -lSDL2_mixer -lminizip -lmodplug -lbz2 -lz -lstdc++ -lwinpthread 
      LDFLAGS += -Wl,-Bdynamic -lole32 -limm32 -lversion -lOleaut32 -lGdi32 -lWinmm -lSetupapi
      OBJECTS += Assets/mrboom.res
   else
      ifneq ($(LIBSDL2),)
         LDFLAGS += $(shell sdl2-config --libs) -lSDL2_mixer -lminizip
      endif
   endif
else
   ifneq ($(LIBSDL),)
      CFLAGS += -D__LIBSDL__ -DONLY_LOCAL -I/usr/local/include -I/usr/m68k-atari-mint/sys-root/usr/include
      LDFLAGS += ${SDLLIBS} -lz
      ifeq ($(FALCON),)
         LDFLAGS += -lminizip
      endif

      fpic=
   else
      CFLAGS += -D__LIBRETRO__
   endif
endif

ifneq ($(FALCON),)
   CFLAGS += -DFALCON
endif

ifneq ($(TESTS),)
   ifeq ($(platform), win)
      LDFLAGS += -mwindows
   else
      ifneq ($(platform), osx)
         LDFLAGS += -lrt
      endif
   endif
   ifeq ($(TESTS), 2)
      CFLAGS += -DAITEST
   endif
endif

CXXFLAGS += $(CFLAGS) $(INCFLAGS) -Wall -pedantic $(fpic)
ifneq ($(LIBSDL2),)
   CXXFLAGS += -std=c++11
else
   CXXFLAGS += -std=c++98
endif

ifneq ($(SCREENSHOTS),)
   CXXFLAGS += -std=c++11 -Isdl2/xBRZ 
endif

ifneq ($(FPS),)
   TMPVAR := $(CXXFLAGS)
   CXXFLAGS = $(filter-out -fPIC, $(TMPVAR)) 
endif

ifneq ($(FALCON),)
   CC=m68k-atari-mint-gcc
   CXX=m68k-atari-mint-g++
   CFLAGS += -m68020-60
   CXXFLAGS += -m68020-60
   LDFLAGS += -m68020-60
   TARGET_NAME=mrboom.tos
endif

ifneq ($(STATETESTS),)
   CXXFLAGS += -std=c++11 -Isdl2/xBRZ 
endif

CFLAGS += $(INCFLAGS) -Wall -pedantic $(fpic)

ifneq (,$(findstring qnx,$(platform)))
   CFLAGS += -Wc,-std=c99
else
   CFLAGS += -std=gnu99
endif

all: $(TARGET)

$(TARGET): $(OBJECTS)
ifeq ($(STATIC_LINKING), 1)
	$(AR) rcs $@ $(OBJECTS)
else ifeq ($(platform),genode)
	$(LD) -o $@ $(OBJECTS) $(LDFLAGS)
else ifneq (,$(findstring msvc,$(platform)))
	$(LD) $(INCLUDES) -out:$@ $(OBJECTS) $(LDFLAGS)
else
	$(CXX) $(fpic) $(SHARED) $(INCLUDES) -o $@ $(OBJECTS) $(LDFLAGS) $(WINSOCKS)
endif


%.o: %.S
	$(CC) $(CFLAGS) -c $(OBJOUT)$@ $<

ifneq ($(FALCON),)
mrboom.o: mrboom.c
	$(CC) -fauto-inc-dec -fbranch-count-reg -fcombine-stack-adjustments -fcompare-elim -fcprop-registers -fdce -fdelayed-branch -fdse -fforward-propagate  -fguess-branch-probability -fif-conversion -fif-conversion2 -finline-functions-called-once -fipa-profile -fipa-pure-const -fipa-reference  -fmerge-constants -fmove-loop-invariants  -freorder-blocks -fsplit-wide-types  -ftree-bit-ccp -ftree-ccp -ftree-ch -ftree-copy-prop -ftree-dce -ftree-dominator-opts -ftree-dse -ftree-forwprop -ftree-fre -ftree-pta -falign-functions  -falign-jumps -falign-labels  -falign-loops -fcaller-saves  -fcrossjumping -fcse-follow-jumps  -fcse-skip-blocks -fdelete-null-pointer-checks -fdevirtualize  -fexpensive-optimizations  -fgcse  -fgcse-lm  -finline-functions -finline-small-functions -findirect-inlining   -fipa-cp -fipa-sra -foptimize-sibling-calls -fpartial-inlining -fpeephole2 -freorder-functions -frerun-cse-after-loop  -fschedule-insns  -fschedule-insns2 -fsched-interblock  -fsched-spec -fstrict-aliasing -fthread-jumps -ftree-builtin-call-dce -ftree-pre -ftree-switch-conversion  -ftree-vrp -fgcse-after-reload -fpeel-loops -fpredictive-commoning -ftree-loop-distribute-patterns -ftree-loop-distribution -ftree-slp-vectorize -funswitch-loops -fvect-cost-model  -DMRBOOM -DHAVE_IBXM -D_FORTIFY_SOURCE=0 -DPLATFORM=\"unix\" -DGIT_VERSION=\"" d34a4659"\" -D__LIBSDL__ -DONLY_LOCAL -I/usr/local/include -I/usr/m68k-atari-mint/sys-root/usr/include -DFALCON  -m68020-60 -I./libretro-common/include -I./libretro-common -I./ai -I. -Wall -pedantic  -std=gnu99  -c -o $@ $<
endif

%.o: %.c
	$(CC) $(CFLAGS) $(fpic) -c $(OBJOUT)$@ $<

%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(fpic) -c $(OBJOUT)$@ $<

%.res: %.rc
	windres $< -O coff $(OBJOUT)$@

mrboomTest: $(OBJECTS)
	$(CXX) $(fpic) $(OBJECTS) $(OBJOUT)$(TARGET_NAME) $(LDFLAGS)

mrboom: $(OBJECTS)
	$(CXX) $(fpic) $(OBJECTS) $(OBJOUT)$(TARGET_NAME) $(LDFLAGS)

CLEAN_TARGETS = $(OBJECTS)
ifneq ($(TESTS),)
CLEAN_TARGETS += $(TARGET)
endif

clean:
	rm -f *.o */*.o */*/*.o */*/*/*.o */*/*/*/*.o */*/*/*/*/*.o
	rm -f *.a */*.a */*/*.a */*/*/*.a */*/*/*/*.a */*/*/*/*/*.a
	rm -f *.d */*.d */*/*.d */*/*/*.d */*/*/*/*.d */*/*/*/*/*.d

strip:
	$(STRIP) $(TARGET_NAME)

install: strip
	$(INSTALL) -m 0755 -d $(DESTDIR)$(PREFIX)/$(BINDIR)
	$(INSTALL) -m 555 $(TARGET_NAME) $(DESTDIR)$(PREFIX)/$(BINDIR)/$(TARGET_NAME)
	$(INSTALL) -m 0755 -d $(DESTDIR)$(PREFIX)/$(MANDIR)
	$(INSTALL) -m 644 Assets/$(TARGET_NAME).6 $(DESTDIR)$(PREFIX)/$(MANDIR) 

install-libretro:
	$(INSTALL) -D -m 755 $(TARGET) $(DESTDIR)$(PREFIX)/$(LIBDIR)/$(LIBRETRO_DIR)/$(TARGET)
	$(INSTALL) -D -m 644 Assets/mrboom.png $(DESTDIR)$(PREFIX)/$(DATADIR)/icons/hicolor/1024x1024/apps/mrboom.png
	$(INSTALL) -D -m 644 Assets/mrboom.libretro $(DESTDIR)$(PREFIX)/$(LIBDIR)/$(LIBRETRO_DIR)/mrboom.libretro

uninstall-libretro:
	$(RM) $(DESTDIR)$(PREFIX)/$(LIBDIR)/$(LIBRETRO_DIR)/$(TARGET)
	$(RM) $(DESTDIR)$(PREFIX)/$(DATADIR)/icons/hicolor/1024x1024/apps/mrboom.png
	$(RM) $(DESTDIR)$(PREFIX)/$(LIBDIR)/$(LIBRETRO_DIR)/mrboom.libretro

.PHONY: clean install-libretro uninstall-libretro
