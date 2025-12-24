LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)
LOCAL_MODULE := AIOS_GOD_NDK
LOCAL_SRC_FILES := aios_ndk.cpp
LOCAL_LDLIBS := -llog -landroid -lOpenSLES
LOCAL_STATIC_LIBRARIES := cpufeatures
LOCAL_CFLAGS := -O3 -std=c++17 -fexceptions -frtti
include $(BUILD_EXECUTABLE)
