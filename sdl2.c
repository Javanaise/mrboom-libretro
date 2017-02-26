#include <stdlib.h>
#include <stdio.h>
#ifdef __EMSCRIPTEN__
#include <emscripten/emscripten.h>
#endif
#include <SDL2/SDL.h>
#include "mrboom.h"
#include "common.h"
#include <time.h>

extern Memory m;

// [21:01]  <bparker> and other things you can try like -Wunsafe-loop-optimizations
// [20:59]  <bparker> http://blog.regehr.org/archives/28


SDL_Renderer *renderer;
SDL_Texture *texture;
SDL_bool done = SDL_FALSE;
SDL_bool noVGA = SDL_FALSE;

SDL_Joystick *joysticks[nb_dyna] = { 0 };
int joysticksInstance[nb_dyna];


static clock_t begin; // = clock();
unsigned int nbFrames=0;


void quit(int rc)
{
    SDL_Quit();
    exit(rc);
}

void printJoystick() {
    int i;
    for(i=0;i<nb_dyna;i++) {
        if (joysticks[i]!=0) {
            SDL_Log("Joystick instance %d: (index:%d)\n", joysticksInstance[i],i);
        }
    }
}

void removeJoystick(int instance) {
    int i;
SDL_Log("Joystick instance %d removed.\n", (int) instance);
    for (i=0;i<nb_dyna;i++) {
        if (joysticks[i]!=0) {
            if (joysticksInstance[i]==instance) {
                joysticks[i]=0;
                SDL_Log("Joystick index/player %d removed.\n",i);
            }
        }
    }
}

void addJoystick(int index) {
    int i;
    SDL_Log("Add Joystick index %d \n", index);
  //  name = SDL_JoystickNameForIndex(i);
  //  int indexJoystick=i;
    SDL_Joystick* joystick = SDL_JoystickOpen(index);
    if (joystick == NULL) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "SDL_JoystickOpen(%d) failed: %s\n", index,
                     SDL_GetError());
    } else {
        int noFreePlayer=1;
        for (i=0;i<nb_dyna;i++) {
            if (joysticks[i]==0) {
                joysticks[i]=joystick;
                joysticksInstance[i]=SDL_JoystickInstanceID(joystick);
                SDL_Log("Joystick instance %d added for player %d\n", joysticksInstance[i],i);
                noFreePlayer=0;
                return;
            }
        }
        
        if (noFreePlayer) {
            SDL_Log("Joystick instance %d cant be added\n", joysticksInstance[i]);
        }
        
        //    SDL_assert(SDL_JoystickFromInstanceID(SDL_JoystickInstanceID(joystick)) == joystick);
        //SDL_JoystickGetGUIDString(SDL_JoystickGetGUID(joystick),
        //                          guid, sizeof (guid));
        //SDL_Log("       axes: %d\n", SDL_JoystickNumAxes(joystick));
        //SDL_Log("      balls: %d\n", SDL_JoystickNumBalls(joystick));
        //SDL_Log("       hats: %d\n", SDL_JoystickNumHats(joystick));
        //SDL_Log("    buttons: %d\n", SDL_JoystickNumButtons(joystick));
        //SDL_Log("instance id: %d\n", SDL_JoystickInstanceID(joystick));
        //SDL_Log("       guid: %s\n", guid);
    }
    //printJoystick();
}

void UpdateTexture(SDL_Texture *texture)
{
    static uint32_t matrixPalette[NB_COLORS_PALETTE];
    Uint32 *dst;
    int row, col;
    void *pixels;
    int pitch;
    
    if (SDL_LockTexture(texture, NULL, &pixels, &pitch) < 0) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't lock texture: %s\n", SDL_GetError());
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
    for(i=0;i<nb_dyna;i++) {
        if (joysticks[i]!=0) {
            if (joysticksInstance[i]==instance) {
                return i;
            }
        }
    }
    SDL_Log("Error getPlayerFromJoystickPort %d\n", instance);
    return 0;
}

void  updateKeyboard(Uint8 scancode,int state) {
    switch(scancode) {
        case SDL_SCANCODE_Q:
            mrboom_update_input(button_up,nb_dyna-2,state);
            break;
        case SDL_SCANCODE_A:
            mrboom_update_input(button_down,nb_dyna-2,state);
            break;
        case SDL_SCANCODE_R:
            mrboom_update_input(button_left,nb_dyna-2,state);
            break;
        case SDL_SCANCODE_T:
            mrboom_update_input(button_right,nb_dyna-2,state);
            break;
        case SDL_SCANCODE_TAB:
            mrboom_update_input(button_a,nb_dyna-2,state);
            break;
        case SDL_SCANCODE_CAPSLOCK:
            mrboom_update_input(button_b,nb_dyna-2,state);
            break;
        case SDL_SCANCODE_LSHIFT:
            mrboom_update_input(button_r,nb_dyna-2,state);
            break;
        case SDL_SCANCODE_RETURN:
        case SDL_SCANCODE_KP_ENTER:
            mrboom_update_input(button_start,nb_dyna-2,state);
            mrboom_update_input(button_start,nb_dyna-1,state);
            break;
        case SDL_SCANCODE_UP:
            mrboom_update_input(button_up,nb_dyna-1,state);
            break;
        case SDL_SCANCODE_DOWN:
            mrboom_update_input(button_down,nb_dyna-1,state);
            break;
        case SDL_SCANCODE_LEFT:
            mrboom_update_input(button_left,nb_dyna-1,state);
            break;
        case SDL_SCANCODE_RIGHT:
            mrboom_update_input(button_right,nb_dyna-1,state);
            break;
        case SDL_SCANCODE_RALT:
            mrboom_update_input(button_a,nb_dyna-1,state);
            break;
        case SDL_SCANCODE_RCTRL:
            mrboom_update_input(button_b,nb_dyna-1,state);
            break;
        case SDL_SCANCODE_RSHIFT:
            mrboom_update_input(button_r,nb_dyna-1,state);
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
                /*
                 case SDL_KEYDOWN:
                 if (event.key.keysym.sym == SDLK_ESCAPE) {
                 done = SDL_TRUE;
                 }
                 break;
                 */
                
            case SDL_JOYDEVICEADDED:
                addJoystick(event.jdevice.which);
                break;
            
            case SDL_JOYDEVICEREMOVED:
                removeJoystick(event.jdevice.which);
                //  SDL_Log("Our instance ID is %d\n", (int) SDL_JoystickInstanceID(joystick));
                break;
                
            case SDL_JOYAXISMOTION:
#define MIN_VALUE_AXIS 1000
                if (event.jaxis.axis==0) {
                    if (event.jaxis.value>MIN_VALUE_AXIS) {
                        mrboom_update_input(button_right,getPlayerFromJoystickPort(event.jaxis.which),1);
                    } else if (event.jaxis.value<-MIN_VALUE_AXIS) {
                        mrboom_update_input(button_left,getPlayerFromJoystickPort(event.jaxis.which),1);
                    } else {
                        mrboom_update_input(button_left,getPlayerFromJoystickPort(event.jaxis.which),0);
                        mrboom_update_input(button_right,getPlayerFromJoystickPort(event.jaxis.which),0);
                    }
                }
                if (event.jaxis.axis==1) {
                    if (event.jaxis.value>MIN_VALUE_AXIS) {
                        mrboom_update_input(button_down,getPlayerFromJoystickPort(event.jaxis.which),1);
                    } else if (event.jaxis.value<-MIN_VALUE_AXIS) {
                        mrboom_update_input(button_up,getPlayerFromJoystickPort(event.jaxis.which),1);
                    } else {
                        mrboom_update_input(button_up,getPlayerFromJoystickPort(event.jaxis.which),0);
                        mrboom_update_input(button_down,getPlayerFromJoystickPort(event.jaxis.which),0);
                    }
                }
                break;
            case SDL_JOYHATMOTION:
                SDL_Log("Joystick %d hat %d value:",
                        event.jhat.which, event.jhat.hat);
                if (event.jhat.value == SDL_HAT_CENTERED)
                    SDL_Log(" centered");
                if (event.jhat.value & SDL_HAT_UP)
                    SDL_Log(" up");
                
                if (event.jhat.value & SDL_HAT_RIGHT)
                    SDL_Log(" right");
                if (event.jhat.value & SDL_HAT_DOWN)
                    SDL_Log(" down");
                if (event.jhat.value & SDL_HAT_LEFT)
                    SDL_Log(" left");
                SDL_Log("\n");
                break;
            case SDL_JOYBALLMOTION:
                SDL_Log("Joystick %d ball %d delta: (%d,%d)\n",
                        event.jball.which,
                        event.jball.ball, event.jball.xrel, event.jball.yrel);
                break;
            case SDL_JOYBUTTONDOWN:
                SDL_Log("Joystick %d button %d down\n",
                        event.jbutton.which, event.jbutton.button);
                switch(event.jbutton.button) {
                    case 0:
                        mrboom_update_input(button_a,getPlayerFromJoystickPort(event.jbutton.which),1);
                        break;
                    case 1:
                        mrboom_update_input(button_b,getPlayerFromJoystickPort(event.jbutton.which),1);
                        break;
                    case 2:
                        mrboom_update_input(button_x,getPlayerFromJoystickPort(event.jbutton.which),1);
                        break;
                    case 3:
                        mrboom_update_input(button_y,getPlayerFromJoystickPort(event.jbutton.which),1);
                        break;
                    case 4:
                        mrboom_update_input(button_l,getPlayerFromJoystickPort(event.jbutton.which),1);
                        break;
                    case 5:
                        mrboom_update_input(button_r,getPlayerFromJoystickPort(event.jbutton.which),1);
                        break;
                    case 6:
                        mrboom_update_input(button_select,getPlayerFromJoystickPort(event.jbutton.which),1);
                        break;
                    case 7:
                        mrboom_update_input(button_start,getPlayerFromJoystickPort(event.jbutton.which),1);
                        break;
                }
                break;
            case SDL_JOYBUTTONUP:
                SDL_Log("Joystick %d button %d up\n",
                        event.jbutton.which, event.jbutton.button);
                switch(event.jbutton.button) {
                    case 0:
                        mrboom_update_input(button_a,getPlayerFromJoystickPort(event.jbutton.which),0);
                        break;
                    case 1:
                        mrboom_update_input(button_b,getPlayerFromJoystickPort(event.jbutton.which),0);
                        break;
                    case 2:
                        mrboom_update_input(button_x,getPlayerFromJoystickPort(event.jbutton.which),0);
                        break;
                    case 3:
                        mrboom_update_input(button_y,getPlayerFromJoystickPort(event.jbutton.which),0);
                        break;
                    case 4:
                        mrboom_update_input(button_l,getPlayerFromJoystickPort(event.jbutton.which),0);
                        break;
                    case 5:
                        mrboom_update_input(button_r,getPlayerFromJoystickPort(event.jbutton.which),0);
                        break;
                    case 6:
                        mrboom_update_input(button_select,getPlayerFromJoystickPort(event.jbutton.which),0);
                        break;
                    case 7:
                        mrboom_update_input(button_start,getPlayerFromJoystickPort(event.jbutton.which),0);
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
    
 
  //  SDL_Log("NB_DD_VARIABLES_IN_RW_SEGMENT=%d\n",NB_DD_VARIABLES_IN_RW_SEGMENT);

   /// stackDump();
    program();
    if (mrboom_debug_state_failed()) {
        log_error("mrboom_debug_state_failed!\n");
        exit(1);
    }

    
    if (m.executionFinished)  done = SDL_TRUE;
    
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
        log_info("x time_spent=%f %d\n",time_spent,nbFrames);
        log_info("x fps=%f\n",nbFrames/time_spent);
    }
}

int
main(int argc, char **argv)
{
    SDL_Window *window;
    
    /* Enable standard application logging */
    SDL_LogSetPriority(SDL_LOG_CATEGORY_APPLICATION, SDL_LOG_PRIORITY_INFO);
    SDL_EventState(SDL_JOYAXISMOTION,SDL_ENABLE);
    SDL_EventState(SDL_JOYBALLMOTION,SDL_ENABLE);
    SDL_EventState(SDL_JOYHATMOTION,SDL_ENABLE);
    SDL_EventState(SDL_JOYBUTTONDOWN,SDL_ENABLE);
    SDL_EventState(SDL_JOYBUTTONUP,SDL_ENABLE);
    SDL_JoystickEventState(SDL_ENABLE);
    
    mrboom_init("/tmp");
    
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_JOYSTICK) < 0) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't initialize SDL: %s\n", SDL_GetError());
        noVGA = SDL_TRUE;
        if (SDL_Init(SDL_INIT_JOYSTICK) < 0) {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't initialize SDL_INIT_JOYSTICK: %s\n", SDL_GetError());
            return 1;
        }
    }
    
    /* Print information about the joysticks */
    
    
    /*
    SDL_Log("There are %d joysticks attached\n", SDL_NumJoysticks());
    for (i = 0; i < SDL_NumJoysticks(); ++i) {
        addJoystick(i);
    }
    */
    
    if (noVGA == SDL_FALSE) {
        
        /* Create the window and renderer */
        window = SDL_CreateWindow(GAME_NAME,
                                  SDL_WINDOWPOS_UNDEFINED,
                                  SDL_WINDOWPOS_UNDEFINED,
                                  WIDTH, HEIGHT,
                                  SDL_WINDOW_RESIZABLE);
        if (!window) {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't set create window: %s\n", SDL_GetError());
            quit(3);
        }
        
        renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_PRESENTVSYNC);
        if (!renderer) {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't set create renderer: %s\n", SDL_GetError());
            quit(4);
        }
        
        texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, WIDTH, HEIGHT);
        if (!texture) {
            SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Couldn't set create texture: %s\n", SDL_GetError());
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

        
        /*
         //  SDL_Log("There are %d joysticks attached\n", SDL_NumJoysticks());
         for (i = 0; i < SDL_NumJoysticks(); ++i) {
         name = SDL_JoystickNameForIndex(i);
         //  SDL_Log("Joystick %d: %s\n", i, name ? name : "Unknown Joystick");
         joystick = SDL_JoystickOpen(i);
         SDL_Log("SDL_JoystickGetHat %d\n",SDL_JoystickGetHat(joystick, SDL_HAT_UP));
         
         
         }
         */
    }
#endif
    
    if (noVGA == SDL_FALSE) {
        SDL_DestroyRenderer(renderer);
    }
    
    fps();
    quit(0);
    return 0;
}


/* vi: set ts=4 sw=4 expandtab: */
