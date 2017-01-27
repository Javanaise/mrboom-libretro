#ifndef COMMON_H__
#define COMMON_H__

#include <audio/audio_mix.h>
#include "libretro.h"

#define PATH_MAX_LENGTH 256
#define FPS_RATE 60.0
#define SAMPLE_RATE 48000.0f

int16_t *frame_sample_buf;
uint32_t num_samples_per_frame;
retro_audio_sample_batch_t audio_batch_cb;

int mrboom_init(char * save_directory);
void mrboom_deinit();

void play_fx();
void audio_callback();

#endif
