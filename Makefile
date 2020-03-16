
STATIC_LINKING := 0
AR             := ar
INSTALL        := install
RM             := rm
STRIP          := strip
GIT_VERSION := " $(shell git rev-parse --short HEAD)"
BINDIR	       ?= bin
LIBDIR         ?= lib
DATADIR        ?= share
LIBRETRO_DIR   ?= libretro
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
else ifneq ($(findstring FreeBSD,$(shell uname -o)),)
	system_platform = freebsd
else ifneq ($(findstring Haiku,$(shell uname -o)),)
	system_platform = haiku
ifeq ($(shell uname -p),powerpc)
	arch = ppc
	CFLAGS += -DMSB_FIRST
endif
else ifneq ($(findstring MINGW,$(shell uname -a)),)
	system_platform = win
else ifeq ($(shell uname -p),ppc)
	arch = ppc
	CFLAGS += -DMSB_FIRST
endif

TARGET_NAME := mrboom

ifeq ($(ARCHFLAGS),)
ifeq ($(archs),ppc)
   ARCHFLAGS = -arch ppc -arch ppc64
else
   ARCHFLAGS = -arch i386 -arch x86_64
endif
endif

ifneq ($(SANITIZER),)
    CFLAGS   := -fsanitize=$(SANITIZER) $(CFLAGS)
    LDFLAGS  := -fsanitize=$(SANITIZER) $(LDFLAGS)
endif

ifeq ($(platform), osx)
ifndef ($(NOUNIVERSAL))
   CFLAGS += $(ARCHFLAGS)
   LFLAGS += $(ARCHFLAGS)
ifneq ($(LIBSDL2),)
   CFLAGS += $(shell sdl2-config --cflags)
   LDFLAGS += $(shell sdl2-config --libs)
endif
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
# iOS
else ifneq (,$(findstring ios,$(platform)))
   TARGET := $(TARGET_NAME)_libretro_ios.dylib
	fpic := -fPIC
	SHARED := -dynamiclib
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
CC     += -miphoneos-version-min=8.0
CFLAGS += -miphoneos-version-min=8.0 -DDONT_WANT_ARM_OPTIMIZATIONS
else
CC     += -miphoneos-version-min=5.0
CFLAGS += -miphoneos-version-min=5.0 -DIOS -DDONT_WANT_ARM_OPTIMIZATIONS
endif

# tvOS
else ifeq ($(platform), tvos-arm64)
   TARGET := $(TARGET_NAME)_libretro_tvos.dylib
   fpic := -fPIC
   SHARED := -dynamiclib
   DEFINES := -DIOS
   CFLAGS += -DDONT_WANT_ARM_OPTIMIZATIONS
ifeq ($(IOSSDK),)
   IOSSDK := $(shell xcodebuild -version -sdk appletvos Path)
endif

# QNX
else ifneq (,$(findstring qnx,$(platform)))
	TARGET := $(TARGET_NAME)_libretro_qnx.so
   fpic := -fPIC
   SHARED := -shared -Wl,--version-script=$(CORE_DIR)/link.T -Wl,--no-undefined
else ifeq ($(platform), emscripten)
   TARGET := $(TARGET_NAME)_libretro_emscripten.bc
   fpic := -fPIC
   SHARED := -shared
   STATIC_LINKING := 1
   CFLAGS += -DNO_NETWORK

# PSP
else ifeq ($(platform), psp1)
   TARGET := $(TARGET_NAME)_psp1.a
   CC = psp-gcc
   CXX = psp-c++
   AR = psp-ar
   CFLAGS += $(DEFINES) -Wall -G0 -DNO_NETWORK -Werror -Wcast-align
	CXXFLAGS += $(CFLAGS)
	STATIC_LINKING = 1
# Vita
else ifeq ($(platform), vita)
   TARGET := $(TARGET_NAME)_vita.a
   CC = arm-vita-eabi-gcc
   CXX = arm-vita-eabi-c++
   AR = arm-vita-eabi-ar
   CFLAGS += $(DEFINES) -Wall -DVITA
	CXXFLAGS += $(CFLAGS)
	STATIC_LINKING = 1
# Nintendo Game Cube
else ifeq ($(platform), ngc)
   TARGET := $(TARGET_NAME)_libretro_$(platform).a
   CC = powerpc-eabi-gcc$(EXE_EXT)
   CXX = powerpc-eabi-g++$(EXE_EXT)
   AR = powerpc-eabi-ar$(EXE_EXT)
   CFLAGS += -DGEKKO -DHW_DOL -mrvl -mcpu=750 -meabi -mhard-float -DMSB_FIRST
   CFLAGS += -DUSE_FILE32API -DNO_NETWORK
   CFLAGS += -U__INT32_TYPE__ -U __UINT32_TYPE__ -D__INT32_TYPE__=int
   STATIC_LINKING = 1
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
# Nintendo Wii
else ifeq ($(platform), wii)
   TARGET := $(TARGET_NAME)_libretro_$(platform).a
   CC = powerpc-eabi-gcc$(EXE_EXT)
   CXX = powerpc-eabi-g++$(EXE_EXT)
   AR = powerpc-eabi-ar$(EXE_EXT)
   CFLAGS += -DGEKKO -DHW_RVL -mrvl -mcpu=750 -meabi -mhard-float -DMSB_FIRST
   CFLAGS += -DUSE_FILE32API -DNO_NETWORK
   CFLAGS += -U__INT32_TYPE__ -U __UINT32_TYPE__ -D__INT32_TYPE__=int
   STATIC_LINKING = 1

# Nintendo Switch (libnx)
else ifeq ($(platform), libnx)
    include $(DEVKITPRO)/libnx/switch_rules
    EXT=a
    TARGET := $(TARGET_NAME)_libretro_$(platform).$(EXT)
    DEFINES := -DSWITCH=1 -U__linux__ -U__linux
    CFLAGS	:= $(DEFINES) -g -O3 \
                 -fPIE -I$(LIBNX)/include/ -ffunction-sections -fdata-sections -ftls-model=local-exec -Wl,--allow-multiple-definition -specs=$(LIBNX)/switch.specs
    CFLAGS += $(INCDIRS)
    CFLAGS	+=	-D__SWITCH__ -DHAVE_LIBNX -march=armv8-a -mtune=cortex-a57 -mtp=soft
    CXXFLAGS := $(ASFLAGS) -fno-rtti -std=gnu++11
    CFLAGS += -std=gnu11
    CFLAGS += -DUSE_FILE32API
    STATIC_LINKING = 1

# Nintendo WiiU
else ifeq ($(platform), wiiu)
   TARGET := $(TARGET_NAME)_libretro_$(platform).a
   CC = powerpc-eabi-gcc$(EXE_EXT)
   CXX = powerpc-eabi-g++$(EXE_EXT)
   AR = powerpc-eabi-ar$(EXE_EXT)
   CFLAGS += -mwup -mcpu=750 -meabi -mhard-float -DMSB_FIRST
   CFLAGS += -DUSE_FILE32API -DNO_NETWORK
   CFLAGS += -U__INT32_TYPE__ -U __UINT32_TYPE__ -D__INT32_TYPE__=int
   STATIC_LINKING = 1

# Nintendo Switch (libtransistor)
else ifeq ($(platform), switch)
   TARGET := $(TARGET_NAME)_libretro_$(platform).a
   include $(LIBTRANSISTOR_HOME)/libtransistor.mk
   CFLAGS += $(CXX_FLAGS)
   STATIC_LINKING=1

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

# Windows MSVC 2003 Xbox 1
else ifeq ($(platform), xbox1_msvc2003)
TARGET := $(TARGET_NAME)_libretro_xdk1.lib
CC  = CL.exe
CXX  = CL.exe
LD   = lib.exe
LOAD_FROM_FILES := 1
export INCLUDE := $(XDK)/xbox/include
export LIB := $(XDK)/xbox/lib
PATH := $(call unixcygpath,$(XDK)/xbox/bin/vc71):$(PATH)
PSS_STYLE :=2
CFLAGS   += -D_XBOX -D_XBOX1
CXXFLAGS += -D_XBOX -D_XBOX1
STATIC_LINKING=1
HAS_GCC := 0
# Windows MSVC 2010 Xbox 360
else ifeq ($(platform), xbox360_msvc2010)
TARGET := $(TARGET_NAME)_libretro_xdk360.lib
MSVCBINDIRPREFIX = $(XEDK)/bin/win32
CC  = "$(MSVCBINDIRPREFIX)/cl.exe"
CXX  = "$(MSVCBINDIRPREFIX)/cl.exe"
LD   = "$(MSVCBINDIRPREFIX)/lib.exe"

export INCLUDE := $(XEDK)/include/xbox
export LIB := $(XEDK)/lib/xbox
PSS_STYLE :=2
FLAGS += -DMSB_FIRST
CFLAGS   += -D_XBOX -D_XBOX360
CXXFLAGS += -D_XBOX -D_XBOX360
STATIC_LINKING=1
HAS_GCC := 0
else ifeq ($(platform), unix-armv7-hardfloat-neon)
   TARGET := $(TARGET_NAME)_libretro.so
   fpic := -fPIC
   SHARED := -shared -Wl,--version-script=$(CORE_DIR)/link.T  -Wl,--no-undefined
   LDFLAGS += -lm -lpthread
   CFLAGS += -marm -march=armv7-a -mtune=cortex-a7 -mfpu=neon-vfpv4 -mfloat-abi=hard
   PLATFLAGS += -DRETRO -DALIGN_DWORD -DARM
   HAVE_NEON = 1
# Windows MSVC 2003 x86
else ifeq ($(platform), windows_msvc2003_x86)
	CC  = cl.exe
	CXX = cl.exe

LOAD_FROM_FILES := 1
CFLAGS += -DLOAD_FROM_FILES
PATH := $(shell IFS=$$'\n'; cygpath "$(VS71COMNTOOLS)../../Vc7/bin"):$(PATH)
PATH := $(PATH):$(shell IFS=$$'\n'; cygpath "$(VS71COMNTOOLS)../IDE")
INCLUDE := $(shell IFS=$$'\n'; cygpath "$(VS71COMNTOOLS)../../Vc7/include")
LIB := $(shell IFS=$$'\n'; cygpath -w "$(VS71COMNTOOLS)../../Vc7/lib")
BIN := $(shell IFS=$$'\n'; cygpath "$(VS71COMNTOOLS)../../Vc7/bin")

WindowsSdkDir := $(INETSDK)

export INCLUDE := $(INCLUDE);$(INETSDK)/Include;src/drivers/libretro/msvc/msvc-2005
export LIB := $(LIB);$(WindowsSdkDir);$(INETSDK)/Lib
TARGET := $(TARGET_NAME)_libretro.dll
PSS_STYLE :=2
LDFLAGS += -DLL
CFLAGS += -D_CRT_SECURE_NO_DEPRECATE

else
   CC ?= gcc
   TARGET := $(TARGET_NAME)_libretro.dll
   SHARED := -shared -static-libgcc -static-libstdc++ -s -Wl,--version-script=$(CORE_DIR)/link.T -Wl,--no-undefined
endif

LIBM    ?= -lm
LDFLAGS += $(LIBM)

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

SDL2LIBS :=  -lSDL2  -lSDL2_mixer -lminizip -lmodplug
ifneq ($(FALCON),)
SDLLIBS := -mshort -L/usr/m68k-atari-mint/sys-root/usr/lib/m68020-60 -lSDL_mixer -lSDL -lSDLmain -lFLAC -lmikmod -lgem -lldg  -lgem -lm -lvorbisfile -lvorbis -logg -lmpg123 
else
 SDLLIBS :=  -lSDL_mixer -lSDL -lSDLmain
ifeq ($(platform), osx)
  SDLLIBS += -framework Cocoa -L/usr/local/lib
endif
endif

include Makefile.common
OBJECTS := $(SOURCES_CXX:.cpp=.o) $(SOURCES_C:.c=.o) $(SOURCES_ASM:.S=.o)


ifneq ($(LIBSDL2),)
CFLAGS += -D__LIBSDL2__ -DLOAD_FROM_FILES -Isdl2/xBRZ 
ifneq ($(MINGW),)
PATH := /${MINGW}/bin:${PATH}
CFLAGS += -I/${MINGW}/include
LDFLAGS += -L/${MINGW}/lib -static-libgcc -static-libstdc++ -Wl,-Bstatic -lstdc++ -lpthread -lstdc++ -lmingw32 -lSDL2main ${SDL2LIBS} -lbz2 -lz -lstdc++ -lwinpthread 
LDFLAGS += -Wl,-Bdynamic -lole32 -limm32 -lversion -lOleaut32 -lGdi32 -lWinmm
OBJECTS += Assets/mrboom.res
else
ifneq ($(LIBSDL2),)
LDFLAGS += ${SDL2LIBS}
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
TARGET_NAME=mrboomTest.out
endif

ifneq ($(FPS),)
TMPVAR := $(CXXFLAGS)
CXXFLAGS = $(filter-out -fPIC, $(TMPVAR)) 
TARGET_NAME=mrboomTest.out
endif

ifneq ($(FALCON),)
CC=m68k-atari-mint-gcc
CXX=m68k-atari-mint-g++
CFLAGS += -m68020-60 -DMSB_FIRST
CXXFLAGS += -m68020-60 -DMSB_FIRST
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
ifeq ($(platform), emscripten)
	$(CXX) $(fpic) -r $(SHARED) $(INCLUDES) -o $@ $(OBJECTS) $(LDFLAGS)
else ifeq ($(STATIC_LINKING), 1)
	$(AR) rcs $@ $(OBJECTS)
else ifeq ($(platform),genode)
	$(LD) -o $@ $(OBJECTS) $(LDFLAGS)
else
	$(CXX) $(fpic) $(SHARED) $(INCLUDES) -o $@ $(OBJECTS) $(LDFLAGS)
endif


%.o: %.S
	$(CC) $(CFLAGS) -c -o $@ $<

ifneq ($(FALCON),)
mrboom.o: mrboom.c
	$(CC) -fauto-inc-dec -fbranch-count-reg -fcombine-stack-adjustments -fcompare-elim -fcprop-registers -fdce -fdelayed-branch -fdse -fforward-propagate  -fguess-branch-probability -fif-conversion -fif-conversion2 -finline-functions-called-once -fipa-profile -fipa-pure-const -fipa-reference  -fmerge-constants -fmove-loop-invariants  -freorder-blocks -fsplit-wide-types  -ftree-bit-ccp -ftree-ccp -ftree-ch -ftree-copy-prop -ftree-dce -ftree-dominator-opts -ftree-dse -ftree-forwprop -ftree-fre -ftree-pta -falign-functions  -falign-jumps -falign-labels  -falign-loops -fcaller-saves  -fcrossjumping -fcse-follow-jumps  -fcse-skip-blocks -fdelete-null-pointer-checks -fdevirtualize  -fexpensive-optimizations  -fgcse  -fgcse-lm  -finline-functions -finline-small-functions -findirect-inlining   -fipa-cp -fipa-sra -foptimize-sibling-calls -fpartial-inlining -fpeephole2 -freorder-functions -frerun-cse-after-loop  -fschedule-insns  -fschedule-insns2 -fsched-interblock  -fsched-spec -fstrict-aliasing -fthread-jumps -ftree-builtin-call-dce -ftree-pre -ftree-switch-conversion  -ftree-vrp -fgcse-after-reload -fpeel-loops -fpredictive-commoning -ftree-loop-distribute-patterns -ftree-loop-distribution -ftree-slp-vectorize -funswitch-loops -fvect-cost-model  -DMRBOOM -DHAVE_IBXM -D_FORTIFY_SOURCE=0 -DPLATFORM=\"unix\" -DGIT_VERSION=\"" d34a4659"\" -D__LIBSDL__ -DONLY_LOCAL -I/usr/local/include -I/usr/m68k-atari-mint/sys-root/usr/include -DFALCON  -m68020-60 -DMSB_FIRST -I./libretro-common/include -I./libretro-common -I./ai -I. -Wall -pedantic  -std=gnu99  -c -o $@ $<
endif

%.o: %.c
	$(CC) $(CFLAGS) $(fpic) -c -o $@ $<

%.res: %.rc
	windres $< -O coff -o $@

mrboomTest: $(OBJECTS)
	$(CXX) $(fpic) $(OBJECTS) -o $(TARGET_NAME) $(LDFLAGS)

mrboom: $(OBJECTS)
	$(CXX) $(fpic) $(OBJECTS) -o $(TARGET_NAME) $(LDFLAGS)

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
