#ifndef COMMON_H__
#define COMMON_H__

#include <audio/audio_mix.h>
#include <libretro.h>

#define PATH_MAX_LENGTH    256
#define WIDTH              320
#define HEIGHT             200
#define NB_COLORS_PALETTE  256

#define GAME_NAME          "MrBoom"
#define GAME_VERSION       "v3.1"

#define button_down        5
#define button_right       7
#define button_left        6
#define button_up          4
#define button_a           8
#define button_x           9
#define button_y           1
#define button_b           0
#define button_select      2
#define button_start       3
#define button_l           10
#define button_r           11
#define nb_dyna            8

int mrboom_init(char * save_directory);
void mrboom_deinit(void);
void mrboom_update_input(int keyid,int playerNumber,int state);
void mrboom_play_fx(void);

#ifdef __LIBRETRO__
#define FPS_RATE 60.0
#define SAMPLE_RATE 48000.0f
int16_t *frame_sample_buf;
uint32_t num_samples_per_frame;
retro_audio_sample_batch_t audio_batch_cb;
void audio_callback(void);
#endif


#endif
