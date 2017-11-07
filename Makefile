#libretro-buildbot

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

CORE_DIR = .

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
LIBM		= -lm

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
   CFLAGS += -I/usr/local/include
   LDFLAGS += -L/usr/local/lib
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
CFLAGS += -miphoneos-version-min=8.0
else
CC     += -miphoneos-version-min=5.0
CFLAGS += -miphoneos-version-min=5.0 -DIOS
endif

# QNX
else ifneq (,$(findstring qnx,$(platform)))
	TARGET := $(TARGET_NAME)_libretro_qnx.so
   fpic := -fPIC
   SHARED := -shared -Wl,--version-script=$(CORE_DIR)/link.T -Wl,--no-undefined
else ifeq ($(platform), emscripten)
   TARGET := $(TARGET_NAME)_libretro_emscripten.bc
   fpic := -fPIC
   SHARED := -shared -Wl,--version-script=$(CORE_DIR)/link.T -Wl,--no-undefined

# Vita
else ifeq ($(platform), vita)
   TARGET := $(TARGET_NAME)_vita.a
   CC = arm-vita-eabi-gcc
   AR = arm-vita-eabi-ar
   CFLAGS += -Wl,-q -Wall -O3
	STATIC_LINKING = 1
# Nintendo Game Cube
else ifeq ($(platform), ngc)
   TARGET := $(TARGET_NAME)_libretro_$(platform).a
   CC = powerpc-eabi-gcc$(EXE_EXT)
   CXX = powerpc-eabi-g++$(EXE_EXT)
   AR = powerpc-eabi-ar$(EXE_EXT)
   CFLAGS += -DGEKKO -DHW_DOL -mrvl -mcpu=750 -meabi -mhard-float -DMSB_FIRST
   CFLAGS += -DUSE_FILE32API
   CFLAGS += -U__INT32_TYPE__ -U __UINT32_TYPE__ -D__INT32_TYPE__=int
   STATIC_LINKING = 1

# Nintendo Wii
else ifeq ($(platform), wii)
   TARGET := $(TARGET_NAME)_libretro_$(platform).a
   CC = powerpc-eabi-gcc$(EXE_EXT)
   CXX = powerpc-eabi-g++$(EXE_EXT)
   AR = powerpc-eabi-ar$(EXE_EXT)
   CFLAGS += -DGEKKO -DHW_RVL -mrvl -mcpu=750 -meabi -mhard-float -DMSB_FIRST
   CFLAGS += -DUSE_FILE32API
   CFLAGS += -U__INT32_TYPE__ -U __UINT32_TYPE__ -D__INT32_TYPE__=int
   STATIC_LINKING = 1

# Nintendo WiiU
else ifeq ($(platform), wiiu)
   TARGET := $(TARGET_NAME)_libretro_$(platform).a
   CC = powerpc-eabi-gcc$(EXE_EXT)
   CXX = powerpc-eabi-g++$(EXE_EXT)
   AR = powerpc-eabi-ar$(EXE_EXT)
   CFLAGS += -mwup -mcpu=750 -meabi -mhard-float -DMSB_FIRST
   CFLAGS += -DUSE_FILE32API
   CFLAGS += -U__INT32_TYPE__ -U __UINT32_TYPE__ -D__INT32_TYPE__=int
   STATIC_LINKING = 1
else
   CC = gcc
   TARGET := $(TARGET_NAME)_libretro.dll
   SHARED := -shared -static-libgcc -static-libstdc++ -s -Wl,--version-script=$(CORE_DIR)/link.T -Wl,--no-undefined
endif

LDFLAGS += $(LIBM)

ifneq ($(DEBUG),)
CFLAGS += -g -pg -DDEBUG
LDFLAGS += -g -pg
else
ifneq ($(system_platform),freebsd)
CFLAGS += -O3
endif
endif

CFLAGS += -DMRBOOM -DGIT_VERSION=\"$(GIT_VERSION)\"

SDL2LIBS :=  -lSDL2  -lSDL2_mixer -lminizip -lmodplug 
ifneq ($(MINGW),)
PATH := /${MINGW}/bin:${PATH}
CFLAGS += -D__LIBSDL2__ -I/${MINGW}/include
LDFLAGS += Assets/mrboom.res -L/${MINGW}/lib -static-libgcc -static-libstdc++ -Wl,-Bstatic -lstdc++ -lpthread -lstdc++ -lmingw32 -lSDL2main ${SDL2LIBS} -lmad -lbz2 -lz -lstdc++ -lwinpthread 
LDFLAGS += -mwindows -Wl,-Bdynamic -lole32 -limm32 -lversion -lOleaut32 -lGdi32 -lWinmm
else
ifneq ($(LIBSDL2),)
CFLAGS += -D__LIBSDL2__
LDFLAGS += ${SDL2LIBS}
else
CFLAGS += -D__LIBRETRO__
endif
endif

include Makefile.common

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

OBJECTS := $(SOURCES_CXX:.cpp=.o) $(SOURCES_C:.c=.o) $(SOURCES_ASM:.S=.o)

CXXFLAGS := $(CFLAGS) $(INCFLAGS) -std=c++98 -Wall -pedantic $(fpic)
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
else
	$(CXX) $(fpic) $(SHARED) $(INCLUDES) -o $@ $(OBJECTS) $(LDFLAGS)
endif

%.o: %.c
	$(CC) $(CFLAGS) $(fpic) -c -o $@ $<

mrboomTest: $(OBJECTS)
	$(CXX) $(fpic) $(OBJECTS) -o mrboomTest.out $(LDFLAGS)

mrboom: $(OBJECTS)
	$(CXX) $(fpic) $(OBJECTS) -o $(TARGET_NAME).out $(LDFLAGS)

CLEAN_TARGETS = $(OBJECTS)
ifneq ($(TESTS),)
CLEAN_TARGETS += $(TARGET)
endif

clean:
	rm -f *.o */*.o */*/*.o

strip:
	$(STRIP) $(TARGET_NAME).out

install: strip
	$(INSTALL) -m 555 $(TARGET_NAME).out $(DESTDIR)$(PREFIX)/$(BINDIR)/$(TARGET_NAME)
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
