##Mr.Boom port for RetroArch/Libretro.

Mr.Boom is a Bomberman clone for the [RetroArch platform](https://www.libretro.com).

Supports up to 8 players and features like pushing bombs, remote controls and kangaroo riding...

It was converted from DOS ASM using [asm2c](https://github.com/frranck/asm2c)

![alt tag](http://mrboom.mumblecore.org/mrb0.png)
![alt tag](http://mrboom.mumblecore.org/mrb1.png)

![alt tag](http://mrboom.mumblecore.org/mrb2.png)
![alt tag](http://mrboom.mumblecore.org/mrb4.png)

![alt tag](http://mrboom.mumblecore.org/mrb5.png)
![alt tag](http://mrboom.mumblecore.org/draw.gif)

### Packages

Mr.Boom is available in the experimental section from [Retropie](https://retropie.org.uk)

There are linux packages (i.e Gentoo ebuild), mainteners please contact me and I will list them here.

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

You will need SDL2 SDL2_mixer minizip and zlib
