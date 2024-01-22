#!/bin/bash
musicDataH=../../libretro/retro_music_data.h
rm -f $musicDataH
for a in DEADFEEL.XM CHIPTUNE.MOD MATKAMIE.MOD CHIPMUNK.MOD UNREEEAL.XM ANAR11.MOD EXTERNAL.XM ESTRAYK.MOD WTH6.MOD HAPPY.XM ASPARTAME.MOD
do
	xxd -i SOUND/$a >> $musicDataH
done
