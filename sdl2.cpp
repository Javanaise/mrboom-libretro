#include <stdlib.h>
#include <stdio.h>
#ifdef __EMSCRIPTEN__
#include <emscripten/emscripten.h>
#endif
#include <SDL2/SDL.h>
#include <time.h>
#include <unistd.h>
#include <getopt.h>
#include "mrboom.h"
#include "common.hpp"
#include "MrboomHelper.hpp"

SDL_Renderer *renderer;
SDL_Texture *texture;
SDL_bool done = SDL_FALSE;
SDL_bool noVGA = SDL_FALSE;

SDL_Joystick *joysticks[nb_dyna] = { 0 };
int joysticksInstance[nb_dyna];

static clock_t begin;
unsigned int nbFrames=0;
bool testAI=false;
bool slowMode=false;
void quit(int rc)
{
	SDL_Quit();
	exit(rc);
}

void printJoystick() {
	int i;
	for(i=0; i<nb_dyna; i++) {
		if (joysticks[i]!=0) {
			log_debug("Joystick instance %d: (index:%d)\n", joysticksInstance[i],i);
		}
	}
}

void removeJoystick(int instance) {
	int i;
	log_debug("Joystick instance %d removed.\n", (int) instance);
	for (i=0; i<nb_dyna; i++) {
		if (joysticks[i]!=0) {
			if (joysticksInstance[i]==instance) {
				joysticks[i]=0;
				log_debug("Joystick index/player %d removed.\n",i);
			}
		}
	}
}

void addJoystick(int index) {
	log_debug("Add Joystick index %d \n", index);
	//  name = SDL_JoystickNameForIndex(i);
	//  int indexJoystick=i;
	SDL_Joystick* joystick = SDL_JoystickOpen(index);
	if (joystick == NULL) {
		log_error("SDL_JoystickOpen(%d) failed: %s\n", index,
		          SDL_GetError());
	} else {
		int noFreePlayer=1;
		for (int i=0; i<nb_dyna; i++) {
			if (joysticks[i]==0) {
				joysticks[i]=joystick;
				joysticksInstance[i]=SDL_JoystickInstanceID(joystick);
				log_debug("Joystick instance %d added for player %d\n", joysticksInstance[i],i);
				noFreePlayer=0;
				return;
			}
		}

		if (noFreePlayer) {
			log_debug("Joystick cant be added\n");
		}
	}
}

void UpdateTexture(SDL_Texture *texture)
{
	static uint32_t matrixPalette[NB_COLORS_PALETTE];
	Uint32 *dst;
	int row, col;
	void *pixels;
	int pitch;

	if (SDL_LockTexture(texture, NULL, &pixels, &pitch) < 0) {
		log_error( "Couldn't lock texture: %s\n", SDL_GetError());
		quit(5);
	}
	int z=0;
	do {
		matrixPalette[z/3]= ((m.vgaPalette[z]*4) << 16) | ((m.vgaPalette[z+1]*4) << 8) | (m.vgaPalette[z+2]*4);
		z+=3;
	} while (z!=NB_COLORS_PALETTE*3);

	for (row = 0; row < HEIGHT; ++row) {
		dst = (Uint32*)((Uint8*)pixels + row * pitch);
		for (col = 0; col < WIDTH; ++col) {
			*dst++ = matrixPalette[m.vgaRam[col+row*WIDTH]];
		}
	}
	SDL_UnlockTexture(texture);
}

int getPlayerFromJoystickPort(int instance) {
	int i;
	for(i=0; i<nb_dyna; i++) {
		if (joysticks[i]!=0) {
			if (joysticksInstance[i]==instance) {
				return i;
			}
		}
	}
	log_error("Error getPlayerFromJoystickPort %d\n", instance);
	return 0;
}

void  updateKeyboard(Uint8 scancode,int state) {
	log_debug("updateKeyboard %d",scancode);
	switch(scancode) {
	case SDL_SCANCODE_W:
		mrboom_update_input(button_up,nb_dyna-2,state,false);
		break;
	case SDL_SCANCODE_S:
		mrboom_update_input(button_down,nb_dyna-2,state,false);
		break;
	case SDL_SCANCODE_A:
		mrboom_update_input(button_left,nb_dyna-2,state,false);
		break;
	case SDL_SCANCODE_D:
		mrboom_update_input(button_right,nb_dyna-2,state,false);
		break;
	case SDL_SCANCODE_LALT:
		mrboom_update_input(button_a,nb_dyna-2,state,false);
		break;
	case SDL_SCANCODE_LCTRL:
		mrboom_update_input(button_b,nb_dyna-2,state,false);
		break;
	case SDL_SCANCODE_LSHIFT:
		mrboom_update_input(button_r,nb_dyna-2,state,false);
		break;
	case SDL_SCANCODE_SPACE:
		mrboom_update_input(button_select,nb_dyna-2,state,false);
		break;
	case SDL_SCANCODE_RETURN:
	case SDL_SCANCODE_KP_ENTER:
		mrboom_update_input(button_start,nb_dyna-2,state,false);
		mrboom_update_input(button_start,nb_dyna-1,state,false);
		break;
	case SDL_SCANCODE_UP:
		mrboom_update_input(button_up,nb_dyna-1,state,false);
		break;
	case SDL_SCANCODE_DOWN:
		mrboom_update_input(button_down,nb_dyna-1,state,false);
		break;
	case SDL_SCANCODE_LEFT:
		mrboom_update_input(button_left,nb_dyna-1,state,false);
		break;
	case SDL_SCANCODE_RIGHT:
		mrboom_update_input(button_right,nb_dyna-1,state,false);
		break;
	case SDL_SCANCODE_RALT:
		mrboom_update_input(button_a,nb_dyna-1,state,false);
		break;
	case SDL_SCANCODE_RCTRL:
		mrboom_update_input(button_b,nb_dyna-1,state,false);
		break;
	case SDL_SCANCODE_RSHIFT:
		mrboom_update_input(button_r,nb_dyna-1,state,false);
		break;
	case SDL_SCANCODE_ESCAPE:
		pressESC();
		if (isGameActive()==false) {
			quit(0);
		}
		break;
	default:
		log_debug("updateKeyboard not handled %d %d\n",scancode,state);
		break;
	}
}

void
loop()
{
	SDL_Event event;


	while (SDL_PollEvent(&event)) {
		switch (event.type) {

		case SDL_JOYDEVICEADDED:
			addJoystick(event.jdevice.which);
			break;

		case SDL_JOYDEVICEREMOVED:
			removeJoystick(event.jdevice.which);
			break;

		case SDL_JOYAXISMOTION:
#define MIN_VALUE_AXIS 1000
			if (event.jaxis.axis==0) {
				if (event.jaxis.value>MIN_VALUE_AXIS) {
					mrboom_update_input(button_right,getPlayerFromJoystickPort(event.jaxis.which),1,false);
				} else if (event.jaxis.value<-MIN_VALUE_AXIS) {
					mrboom_update_input(button_left,getPlayerFromJoystickPort(event.jaxis.which),1,false);
				} else {
					mrboom_update_input(button_left,getPlayerFromJoystickPort(event.jaxis.which),0,false);
					mrboom_update_input(button_right,getPlayerFromJoystickPort(event.jaxis.which),0,false);
				}
			}
			if (event.jaxis.axis==1) {
				if (event.jaxis.value>MIN_VALUE_AXIS) {
					mrboom_update_input(button_down,getPlayerFromJoystickPort(event.jaxis.which),1,false);
				} else if (event.jaxis.value<-MIN_VALUE_AXIS) {
					mrboom_update_input(button_up,getPlayerFromJoystickPort(event.jaxis.which),1,false);
				} else {
					mrboom_update_input(button_up,getPlayerFromJoystickPort(event.jaxis.which),0,false);
					mrboom_update_input(button_down,getPlayerFromJoystickPort(event.jaxis.which),0,false);
				}
			}
			break;
		case SDL_JOYBUTTONDOWN:
			log_debug("Joystick %d button %d down\n",
			          event.jbutton.which, event.jbutton.button);
			switch(event.jbutton.button) {
			case 0:
				mrboom_update_input(button_a,getPlayerFromJoystickPort(event.jbutton.which),1,false);
				break;
			case 1:
				mrboom_update_input(button_b,getPlayerFromJoystickPort(event.jbutton.which),1,false);
				break;
			case 2:
				mrboom_update_input(button_x,getPlayerFromJoystickPort(event.jbutton.which),1,false);
				break;
			case 3:
				mrboom_update_input(button_y,getPlayerFromJoystickPort(event.jbutton.which),1,false);
				break;
			case 4:
				mrboom_update_input(button_l,getPlayerFromJoystickPort(event.jbutton.which),1,false);
				break;
			case 5:
				mrboom_update_input(button_r,getPlayerFromJoystickPort(event.jbutton.which),1,false);
				break;
			case 6:
				mrboom_update_input(button_select,getPlayerFromJoystickPort(event.jbutton.which),1,false);
				break;
			case 7:
				mrboom_update_input(button_start,getPlayerFromJoystickPort(event.jbutton.which),1,false);
				break;
			}
			break;
		case SDL_JOYBUTTONUP:
			log_debug("Joystick %d button %d up\n",
			          event.jbutton.which, event.jbutton.button);
			switch(event.jbutton.button) {
			case 0:
				mrboom_update_input(button_a,getPlayerFromJoystickPort(event.jbutton.which),0,false);
				break;
			case 1:
				mrboom_update_input(button_b,getPlayerFromJoystickPort(event.jbutton.which),0,false);
				break;
			case 2:
				mrboom_update_input(button_x,getPlayerFromJoystickPort(event.jbutton.which),0,false);
				break;
			case 3:
				mrboom_update_input(button_y,getPlayerFromJoystickPort(event.jbutton.which),0,false);
				break;
			case 4:
				mrboom_update_input(button_l,getPlayerFromJoystickPort(event.jbutton.which),0,false);
				break;
			case 5:
				mrboom_update_input(button_r,getPlayerFromJoystickPort(event.jbutton.which),0,false);
				break;
			case 6:
				mrboom_update_input(button_select,getPlayerFromJoystickPort(event.jbutton.which),0,false);
				break;
			case 7:
				mrboom_update_input(button_start,getPlayerFromJoystickPort(event.jbutton.which),0,false);
				break;
			}
			break;
		case SDL_KEYDOWN:
			updateKeyboard(event.key.keysym.scancode,1);
			break;
		case SDL_KEYUP:
			updateKeyboard(event.key.keysym.scancode,0);
			break;
		case SDL_FINGERDOWN:
		case SDL_MOUSEBUTTONDOWN:
			break;
		case SDL_QUIT:
			done = SDL_TRUE;
			break;
		default:
			break;
		}
	}

	program();
	mrboom_reset_special_keys();
	mrboom_tick_ai();

#ifdef DEBUG
	if (mrboom_debug_state_failed()) {
		log_error("mrboom_debug_state_failed!\n");
		exit(1);
	}
#endif

	if (m.executionFinished) done = SDL_TRUE;

	mrboom_play_fx();

	if (noVGA == SDL_FALSE) {
		UpdateTexture(texture);
		SDL_RenderClear(renderer);
		SDL_RenderCopy(renderer, texture, NULL, NULL);
		SDL_RenderPresent(renderer);
	}
#ifdef __EMSCRIPTEN__
	if (done) {
		emscripten_cancel_main_loop();
	}
#endif
}

static void fps() {
	nbFrames++;
	if (!(nbFrames%600)) {
		clock_t end = clock();
		double time_spent = (double)(end - begin) / CLOCKS_PER_SEC;
		log_debug("x time_spent=%f %d\n",time_spent,nbFrames);
		log_debug("x fps=%f\n",nbFrames/time_spent);
	}
}

void manageTestAI() {
	static bool doItOnce=true;
	if (isGameActive()==false) {
		if (numberOfPlayers()!=nb_dyna-2) {
			addOneAIPlayer();
		} else {
			if (doItOnce) {
				pressStart();
				doItOnce=false;
			}
		}
	}
}
int
main(int argc, char **argv)
{
	int c;

	while (1)
	{
		static struct option long_options[] =
		{
			{"test", no_argument, 0, 't'},
			{"cheat", no_argument, 0, 'c'},
			{"level", required_argument, 0, 'l'},
			{"nomonster", no_argument, 0, 'm'},
			{"version", no_argument, 0, 'v'},
			{"help", no_argument, 0, 'h'},
			{0, 0, 0, 0}
		};
		/* getopt_long stores the option index here. */
		int option_index = 0;

		c = getopt_long (argc, argv, "cl:hmstv",
		                 long_options, &option_index);

		/* Detect the end of the options. */
		if (c == -1)
			break;
		switch (c)
		{
		case 'h':
			log_info("Usage: mrboom [options]\n");
			log_info("Options:\n");
			log_debug("  -c, --cheat    \t\tActivate L1/L2 pad key for debugging.\n");
			log_info("  -h, --help     \t\tShow summary of options.\n");
			log_debug("  -l <x>, --level <x>\t\tStart in level <x>. With x between 0 and 7.\n");
			log_info("  -m, --nomonster\t\tNo monster mode.\n");
			log_debug("  -s, --slow    \t\tSlow motion for AI debugging.\n");
			log_debug("  -t, --test     \t\tTest mode for AI.\n");
			log_info("  -v, --version  \t\tDisplay version.\n");
			exit(0);
			break;
		case 'v':
			log_info("%s %s\n",GAME_NAME,GAME_VERSION);
			exit(0);
			break;
		case 'l':
			log_info("-l option given. choosing level %s.\n",optarg);
			chooseLevel(atoi(optarg));
			break;
		case 'm':
			log_info("-m option given. No monster mode.\n");
			setNoMonsterMode(true);
			break;
		case 'c':
			log_info("-c option given. Activate L1 pad key for debugging.\n");
			cheatMode=true;
			break;
		case 't':
			log_info("-t option given. Test mode for AI.\n");
			testAI=true;
			break;
		case 's':
			log_info("-s option given. Slow motion for AI debugging.\n");
			slowMode=true;
			break;
		default:
			abort ();
		}
	}
	SDL_Window *window;

	/* Enable standard application logging */
	SDL_LogSetPriority(SDL_LOG_CATEGORY_APPLICATION, SDL_LOG_PRIORITY_INFO);
	SDL_EventState(SDL_JOYAXISMOTION,SDL_ENABLE);
	SDL_EventState(SDL_JOYBALLMOTION,SDL_ENABLE);
	SDL_EventState(SDL_JOYHATMOTION,SDL_ENABLE);
	SDL_EventState(SDL_JOYBUTTONDOWN,SDL_ENABLE);
	SDL_EventState(SDL_JOYBUTTONUP,SDL_ENABLE);
	SDL_JoystickEventState(SDL_ENABLE);

	if (!mrboom_init()) quit(0);

	if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_JOYSTICK) < 0) {
		log_error("Couldn't initialize SDL: %s\n", SDL_GetError());
		noVGA = SDL_TRUE;
		if (SDL_Init(SDL_INIT_JOYSTICK) < 0) {
			log_error("Couldn't initialize SDL_INIT_JOYSTICK: %s\n", SDL_GetError());
			return 1;
		}
	}

	if (noVGA == SDL_FALSE) {
		/* Create the window and renderer */
		window = SDL_CreateWindow(GAME_NAME,
		                          SDL_WINDOWPOS_UNDEFINED,
		                          SDL_WINDOWPOS_UNDEFINED,

#ifdef DEBUG
															WIDTH*2, HEIGHT*2,
															SDL_WINDOW_RESIZABLE
#else
															WIDTH, HEIGHT,
		                          SDL_WINDOW_FULLSCREEN
#endif
														);
		if (!window) {
			log_error("Couldn't set create window: %s\n", SDL_GetError());
			quit(3);
		}

		renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_PRESENTVSYNC);
		if (!renderer) {
			log_error("Couldn't set create renderer: %s\n", SDL_GetError());
			quit(4);
		}

		texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, WIDTH, HEIGHT);
		if (!texture) {
			log_error("Couldn't set create texture: %s\n", SDL_GetError());
			quit(5);
		}

	}

	/* Loop, waiting for QUIT or the escape key */

#ifdef __EMSCRIPTEN__
	emscripten_set_main_loop(loop, 0, 1);
#else
	begin = clock();
	while (!done) {
		loop();
		fps();
		if (testAI) manageTestAI();
		if (slowMode) usleep(100000);
	}
#endif

	if (noVGA == SDL_FALSE) {
		SDL_DestroyRenderer(renderer);
	}
	fps();
	quit(0);
	return 0;
}
