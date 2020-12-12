#$NDK_ROOT_LOCAL/ndk-build -j6 APP_ABI=armeabi clean
#armeabi armeabi-v7a
ARCHI=x86
$NDK_ROOT_LOCAL/ndk-build -j6 APP_ABI=$ARCHI clean
$NDK_ROOT_LOCAL/ndk-build -j6 APP_ABI=$ARCHI
adb shell ls /data/data/com.retroarch/cores
adb push ../../libs/$ARCHI/libretro.so /data/data/com.retroarch/cores/mrboom_libretro_android.so
