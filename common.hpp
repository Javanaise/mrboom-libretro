#ifndef COMMON_H__
#define COMMON_H__
#include <stdbool.h>
#ifdef __LIBRETRO__
#include <libretro.h>
#endif
#ifdef __cplusplus
extern "C" {
#endif
#define GAME_NAME          "Mr.Boom"
#define GAME_VERSION       "3.3"
#define PATH_MAX_LENGTH    256
#define WIDTH              320
#define HEIGHT             200
#define NB_COLORS_PALETTE  256
#define nb_dyna            8

class BotTree;
extern BotTree* tree[nb_dyna];
extern bool botsSolidarity;
enum Button {
	button_b,
	button_y,
	button_select,
	button_start,
	button_up,
	button_down,
	button_left,
	button_right,
	button_a,
	button_x,
	button_l,
	button_r,
	button_error
};

#define FIRST_RW_VARIABLE replayer_saver
#define FIRST_RW_VARIABLE_DB nosetjmp
#define NB_DD_VARIABLES_IN_RW_SEGMENT (offsetof(struct Mem,FIRST_RW_VARIABLE_DB)-offsetof(struct Mem,FIRST_RW_VARIABLE))/4
#define FIRST_RO_VARIABLE master
#define SIZE_RO_SEGMENT offsetof(struct Mem,FIRST_RW_VARIABLE)-offsetof(struct Mem,FIRST_RO_VARIABLE)
#define SIZE_SER offsetof(struct Mem,selectorsPointer)-offsetof(struct Mem,FIRST_RW_VARIABLE)
bool mrboom_init();
void mrboom_deinit(void);
void mrboom_update_input(int keyid,int playerNumber,int state,bool isIA);
void mrboom_play_fx(void);
bool mrboom_debug_state_failed();
void mrboom_reset_special_keys();
void mrboom_tick_ai();
void mrboom_deal_with_autofire();
bool debugTracesPlayer(int player);

extern bool cheatMode;
#ifdef __LIBRETRO__
#define FPS_RATE 60.0
#define SAMPLE_RATE 48000.0f
extern int16_t *frame_sample_buf;
extern uint32_t num_samples_per_frame;
extern retro_audio_sample_batch_t audio_batch_cb;
void audio_callback(void);
#define DEFAULT_TRACE_MAX 0
#endif
#ifdef __LIBSDL2__
extern int sdl2_fx_volume;
#define DEFAULT_SDL2_FX_VOLUME 5
#define DEFAULT_TRACE_MAX 1 | DEBUG_MASK_GRIDS
#endif
#define DEBUG_SDL2 1024
#define DEBUG_MASK_BOTTREEDECISIONS 512
#define DEBUG_MASK_GRIDS 256
extern int traceMask;
#ifdef __cplusplus
}
#endif
#endif
