STATIC_LINKING := 0
AR             := ar

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
ifeq ($(shell uname -p),powerpc)
	arch = ppc
endif
else ifneq ($(findstring MINGW,$(shell uname -a)),)
	system_platform = win
endif

TARGET_NAME := mrboom
LIBM		= -lm -lz -lminizip

ifeq ($(ARCHFLAGS),)
ifeq ($(archs),ppc)
   ARCHFLAGS = -arch ppc -arch ppc64
else
   ARCHFLAGS = -arch i386 -arch x86_64
endif
endif

ifneq ($(SANITIZER),)
    CFLAGS   := -fsanitize=$(SANITIZER) $(CFLAGS)
    CXXFLAGS := -fsanitize=$(SANITIZER) $(CXXFLAGS)
    LDFLAGS  := -fsanitize=$(SANITIZER) $(LDFLAGS)
endif

ifeq ($(platform), osx)
ifndef ($(NOUNIVERSAL))
   CFLAGS += $(ARCHFLAGS) -I/usr/local/include -I/usr/local/Cellar/minizip/1.2.10/include/
   LFLAGS += $(ARCHFLAGS)
   LDFLAGS += -L/usr/local/lib
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
else ifneq (,$(findstring osx,$(platform)))
   TARGET := $(TARGET_NAME)_libretro.dylib
   fpic := -fPIC
   SHARED := -dynamiclib
else ifneq (,$(findstring ios,$(platform)))
   TARGET := $(TARGET_NAME)_libretro_ios.dylib
	fpic := -fPIC
	SHARED := -dynamiclib

ifeq ($(IOSSDK),)
   IOSSDK := $(shell xcodebuild -version -sdk iphoneos Path)
endif

	DEFINES := -DIOS
	CC = cc -arch armv7 -isysroot $(IOSSDK)
ifeq ($(platform),ios9)
CC     += -miphoneos-version-min=8.0
CFLAGS += -miphoneos-version-min=8.0
else
CC     += -miphoneos-version-min=5.0
CFLAGS += -miphoneos-version-min=5.0
endif
else ifneq (,$(findstring qnx,$(platform)))
	TARGET := $(TARGET_NAME)_libretro_qnx.so
   fpic := -fPIC
   SHARED := -shared -Wl,--version-script=$(CORE_DIR)/link.T -Wl,--no-undefined
else ifeq ($(platform), emscripten)
   TARGET := $(TARGET_NAME)_libretro_emscripten.bc
   fpic := -fPIC
   SHARED := -shared -Wl,--version-script=$(CORE_DIR)/link.T -Wl,--no-undefined
else ifeq ($(platform), vita)
   TARGET := $(TARGET_NAME)_vita.a
   CC = arm-vita-eabi-gcc
   AR = arm-vita-eabi-ar
   CFLAGS += -Wl,-q -Wall -O3
	STATIC_LINKING = 1
else
   CC = gcc
   TARGET := $(TARGET_NAME)_libretro.dll
   SHARED := -shared -static-libgcc -static-libstdc++ -s -Wl,--version-script=$(CORE_DIR)/link.T -Wl,--no-undefined
endif

LDFLAGS += $(LIBM)

ifeq ($(DEBUG), 1)
   #CFLAGS += -O0 -g -DDEBUG
   CFLAGS += -O0 -g
else
   CFLAGS += -O0
endif

LIBRETRO_COMMON := $(CORE_DIR)/libretro-common

OBJECTS := mrboom.o common.o retro.o $(LIBRETRO_COMMON)/file/retro_stat.o \
					 $(LIBRETRO_COMMON)/file/file_path.o $(LIBRETRO_COMMON)/compat/compat_strcasestr.o \
					 $(LIBRETRO_COMMON)/string/stdstring.o $(LIBRETRO_COMMON)/compat/compat_strl.o \
           $(LIBRETRO_COMMON)/streams/file_stream.o \
					 $(LIBRETRO_COMMON)/formats/wav/rwav.o $(LIBRETRO_COMMON)/audio/audio_mix.o \
					 $(LIBRETRO_COMMON)/audio/resampler/audio_resampler.o $(LIBRETRO_COMMON)/features/features_cpu.o \
					 $(LIBRETRO_COMMON)/lists/string_list.o $(LIBRETRO_COMMON)/hash/rhash.o \
					 $(LIBRETRO_COMMON)/audio/conversion/float_to_s16.o $(LIBRETRO_COMMON)/audio/conversion/s16_to_float.o \
					 $(LIBRETRO_COMMON)/audio/resampler/drivers/sinc_resampler.o $(LIBRETRO_COMMON)/audio/resampler/drivers/nearest_resampler.o \
					 $(LIBRETRO_COMMON)/audio/resampler/drivers/null_resampler.o $(LIBRETRO_COMMON)/memmap/memalign.o

CFLAGS += -I$(LIBRETRO_COMMON)/include -Wall -pedantic -Wno-gnu-designator -Wno-unused-label $(fpic)

ifneq (,$(findstring qnx,$(platform)))
CFLAGS += -Wc,-std=c99
else
CFLAGS += -std=gnu99
endif

CFLAGS += -DRETRO -I$(LIBRETRO_COMMON)/include

all: $(TARGET)

$(TARGET): $(OBJECTS)
ifeq ($(STATIC_LINKING), 1)
	$(AR) rcs $@ $(OBJECTS)
else
	$(CC) $(fpic) $(SHARED) $(INCLUDES) -o $@ $(OBJECTS) $(LDFLAGS)
endif

%.o: %.c
	$(CC) $(CFLAGS) $(fpic) -c -o $@ $<

test: $(OBJECTS)
	$(CC) $(fpic) $(OBJECTS) -o $(TARGET_NAME).out $(LDFLAGS)

clean:
	rm -f $(OBJECTS) $(TARGET)

.PHONY: clean
