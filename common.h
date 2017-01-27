#ifndef COMMON_H__
#define COMMON_H__

#define PATH_MAX_LENGTH 256
#define WIDTH 320
#define HEIGHT 200
#define NB_COLORS_PALETTE 256

#define GAME_NAME "MrBoom"
#define GAME_VERSION "v3.1"

#define button_down 5
#define button_right 7
#define button_left 6
#define button_up 4
#define button_a 8
#define button_x 9
#define button_y 1
#define button_b 0
#define button_select 2
#define button_start 3
#define button_l 10
#define button_r 11

int mrboom_init(char * save_directory);
void mrboom_deinit();
void mrboom_update_input(int keyid,int port,int state);
void mrboom_play_fx();

#endif
