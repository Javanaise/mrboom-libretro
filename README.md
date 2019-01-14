## Mr.Boom port for RetroArch/Libretro and SDL2.

Mr.Boom is a Bomberman clone for the [RetroArch platform](http://www.retroarch.com) and was converted from DOS assembly using [asm2c](https://github.com/frranck/asm2c).

It runs on all RetroArch platforms: Android, Linux, Mac OS X, Nintendo Gamecube (NGC), Nintendo Switch, Nintendo Wii, Raspberry Pi, Sony Playstation 3 (PS3), Sony Playstation Portable (PSP), Windows, Xbox, Xbox360...

It can also be compiled as a stand-alone version using SDL2.

![alt tag](tests/screenshots/mrboom-5.gif)

Mr.Boom supports up to 8 players and features like netplay, AI bots [(new C++ feature)](ai/), pushing bombs, remote controls and kangaroo riding...

Check the [Downloading and Playing Mr. Boom Core](https://youtu.be/_0rw36mA9mM) video.

You can find netplay games by joining the [retroarch discord channel](https://discord.gg/011l9DB6qWt9B4bzO).

### Options available:

- Color, Sex or Skynet team modes.
- No monster mode.
- Drop bomb button autofire.

### Compiling the Libretro version:

```sh
make clean
make
```

### Compiling the SDL2 version:
- OSX: 
```sh
brew install SDL2 minizip SDL2_mixer --with-libmodplug
make clean
make mrboom LIBSDL2=1
make install
```
- Linux Debian/Ubuntu family:
```sh
apt-get install build-essential libsdl2-dev libmodplug-dev libsdl2-mixer-dev libminizip-dev
make clean
make mrboom LIBSDL2=1
make install
```
- Linux RedHat family:
```sh
yum install SDL2-devel SDL2_mixer-devel minizip-devel libmodplug-devel
make clean
make mrboom LIBSDL2=1
make install
```

- Windows (in [msys2](http://www.msys2.org/)):
```sh
pacman -S mingw-w64-x86_64-toolchain
pacman -S mingw-w64-x86_64-SDL2main
pacman -S mingw-w64-x86_64-SDL2_mixer
pacman -S mingw-w64-x86_64-SDL2
pacman -S mingw-w64-x86_64-libmodplug
make clean
make mrboom LIBSDL2=1 MINGW=mingw64
```

### Packages available:

[![Packaging status](https://repology.org/badge/vertical-allrepos/mrboom.svg)](https://repology.org/metapackage/mrboom)

### Raspberry Pi configuration:

To get a proper speed on Raspberry Pi, make sure you use a 60Hz VGA mode in /boot/config.txt:
```sh
hdmi_group=1
hdmi_mode=4
```

