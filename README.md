##Mr.Boom port for RetroArch/Libretro.

Mr.Boom is a Bomberman clone for the [RetroArch platform](https://www.libretro.com) and was converted from DOS assembly using [asm2c](https://github.com/frranck/asm2c).

![alt tag](http://mrboom.mumblecore.org/mrb0.png)
![alt tag](http://mrboom.mumblecore.org/mrb1.png)

![alt tag](http://mrboom.mumblecore.org/mrb2.png)
![alt tag](http://mrboom.mumblecore.org/mrb4.png)

![alt tag](http://mrboom.mumblecore.org/mrb5.png)
![alt tag](http://mrboom.mumblecore.org/draw.gif)

It supports up to 8 players and features like pushing bombs, remote controls and kangaroo riding...

Check the [Downloading and Playing Mr. Boom Core](https://youtu.be/_0rw36mA9mM) video.

### Mr.Boom packages are available:

- In the experimental section from [Retropie](https://retropie.org.uk).
- At the third-party Gentoo overlay [Abendbrot](https://github.com/stefan-gr/abendbrot).
- At the archlinux user repository [AUR](https://aur.archlinux.org/packages/libretro-mrboom-git/).

Please [contact me](https://twitter.com/frrancck) to be listed here!

### Compiling the RetroArch version

```sh
make clean
make
```

### Compiling a SDL2 stand-alone version

```sh
make clean
make mrboom LIBSDL2=1
```

You will need SDL2 SDL2_mixer minizip and zlib.
