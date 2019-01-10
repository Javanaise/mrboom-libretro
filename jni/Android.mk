LOCAL_PATH := $(call my-dir)

CORE_DIR := $(LOCAL_PATH)/..

include $(CORE_DIR)/Makefile.common

COREFLAGS := -DMRBOOM -DPLATFORM=\"Android\" -DHAVE_IBXM -D__LIBRETRO__ $(INCFLAGS) -fno-strict-aliasing

GIT_VERSION := " $(shell git rev-parse --short HEAD || echo unknown)"
ifneq ($(GIT_VERSION)," unknown")
  COREFLAGS += -DGIT_VERSION=\"$(GIT_VERSION)\"
endif

include $(CLEAR_VARS)
LOCAL_MODULE    := retro
LOCAL_SRC_FILES := $(SOURCES_C) $(SOURCES_CXX)
LOCAL_CPPFLAGS  := -std=c++11 $(COREFLAGS)
LOCAL_CFLAGS    := $(COREFLAGS)
LOCAL_LDFLAGS   := -Wl,-version-script=$(CORE_DIR)/link.T

# armv5 clang workarounds
ifeq ($(TARGET_ARCH_ABI),armeabi)
  LOCAL_ARM_MODE := arm
endif

include $(BUILD_SHARED_LIBRARY)
