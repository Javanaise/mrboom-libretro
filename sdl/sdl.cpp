#include <SDL/SDL.h>
#include <time.h>

#include "mrboom.h"
#include "common.hpp"
#include <SDL/SDL.h>
#include <SDL/SDL_mixer.h>

#include "MrboomHelper.hpp"

static SDL_Color    colors[256];
static SDL_Surface *display;

//#define TESTING

#define DEFAULT_DEAD_ZONE    8000
int done = 0;

int joystickDeadZone = DEFAULT_DEAD_ZONE;
#define BEEING_PLAYING_BUFFER    60
int beeingPlaying = 0;

#define NB_STICKS_MAX_PER_PAD    2

int axis[NB_STICKS_MAX_PER_PAD * 2] = { 0, 0, 0, 0 };

int anySelectButtonPushedMask   = 0;
int anyButtonPushedMask         = 0;
int anyStartButtonPushedMask    = 0;
int anyStartButtonPushedCounter = 0;

static SDL_Joystick *joysticks[nb_dyna]         = { 0 };
static bool          oneButtonJoystick[nb_dyna] = { false };
static int           timerButton[nb_dyna]       = { 0 };

#define SPEED_TAP    15

void mrboom_update_input_loop()
{
   for (int i = 0; i < nb_dyna; i++)
   {
      if (oneButtonJoystick[i])
      {
         if (timerButton[i] != 0)
         {
            timerButton[i]++;
            if (timerButton[i] >= SPEED_TAP)
            {
               log_debug("press a %d (long pressed)\n", i);
               mrboom_update_input(button_a, i, 1, false);
            }
         }
         mrboom_update_input(button_b, i, 0, false);
      }
   }
}

void mrboom_update_input_j(int keyid, int input, int state, bool isIA)
{
   if (oneButtonJoystick[input])
   {
      if (state == 1)
      {
         // press
         timerButton[input] = 1;
         mrboom_update_input(button_a, input, 0, isIA);
         mrboom_update_input(button_b, input, 0, isIA);
      }
      else
      {
         // release
         if (timerButton[input] < SPEED_TAP)
         {
            // quick that was a drop
            log_debug("press b (by release) %d\n", input);
            mrboom_update_input(button_a, input, 0, isIA);
            mrboom_update_input(button_b, input, 1, isIA);
         }
         else
         {
            // long
            mrboom_update_input(button_a, input, 0, isIA);
            mrboom_update_input(button_b, input, 0, isIA);
         }
         timerButton[input] = 0;
      }
   }
   else
   {
      mrboom_update_input(keyid, input, state, isIA);
   }
}

void updatePalette()
{
   int z = 0;
   int i = 0;

   do
   {
      colors[i].r = (m.vgaPalette[z+0] << 2) | (m.vgaPalette[z+0] >> 4);
	  colors[i].g = (m.vgaPalette[z+1] << 2) | (m.vgaPalette[z+1] >> 4);
	  colors[i].b = (m.vgaPalette[z+2] << 2) | (m.vgaPalette[z+2] >> 4);
      i++;
      z += 3;
   } while (i != 256);
   SDL_SetPalette(display, SDL_LOGPAL | SDL_PHYSPAL, colors, 0, 256);
}

#define NB_CLOCKS    2
clock_t clocks[NB_CLOCKS];
bool    clocksRunning[NB_CLOCKS]  = { false };
double  timeSpentClock[NB_CLOCKS] = { 0 };

double totalTimeInClock(int clockIndex)
{
   if (clocksRunning[clockIndex])
   {
      clock_t end = clock();
      return(timeSpentClock[clockIndex] + (double)(end - clocks[clockIndex]) / CLOCKS_PER_SEC);
   }
   else
   {
      return(timeSpentClock[clockIndex]);
   }
}

void startClock(int clockIndex)
{
   clocks[clockIndex]        = clock();
   clocksRunning[clockIndex] = true;
}

void stopClock(int clockIndex)
{
   timeSpentClock[clockIndex] = totalTimeInClock(clockIndex);
   clocksRunning[clockIndex]  = false;
}

uint8_t ramdisk[20000];


void sdl_init()
{
   SDL_Init(SDL_INIT_EVERYTHING);

   log_info("     _________   _________     _________   _________   _________   _________\n");
   log_info("  ___\\______ /___\\____   /_____\\____   /___\\_____  /___\\_____  /___\\______ /___\n");
   log_info("  \\_   |   |   _     |_____/\\_   ____    _     |/    _     |/    _   |   |   _/\n");
   log_info("   |___|___|___|_____|  sns  |___________|___________|___________|___|___|___|\n");
   log_info(" ==[mr.boom]======================================================[est. 1997]==\n");

   if (Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 1024) == -1)
   {
      log_info("Mix_OpenAudio: %s\n", Mix_GetError());
      exit(2);
   }

   int flags   = 0; //MIX_INIT_OGG | MIX_INIT_MOD;
   int initted = Mix_Init(flags);
   if (initted)
   {
      log_error("Mix_Init: %s\n", Mix_GetError());
      exit(2);
   }
   else
   {
      log_debug("Mix init ok\n");
   }

   SDL_Joystick *joy;

   int nbs = SDL_NumJoysticks();

   for (int i = 0; i < nbs && i < nb_dyna; i++)
   {
      joy = SDL_JoystickOpen(i);

      if (joy)
      {
         if (SDL_JoystickNumButtons(joy) == 1)
         {
            oneButtonJoystick[i] = true;
            log_info("Joystick %d has 1 button\n", i);
         }
         else
         {
            log_info("Joystick %d has %d buttons\n", i, SDL_JoystickNumButtons(joy));
#ifdef TESTING
            oneButtonJoystick[i] = true;
#endif
         }
         joysticks[i] = joy;
      }
      else
      {
         printf("Couldn't open Joystick 0\n");
      }
   }
   union
   {
      void *ptr;
      int   i;
   };
   ptr = &m;

   if ((i % 4) != 0)
   {
      printf("adress m %d %d WRONG? need to check on real machine, seems there was performance issue with wrong alignement (?)\n.\n", i, (i) % 4);
      done = 1;
   }
   ptr = &m.buffer;
   if ((i % 4) != 0)
   {
      printf("adress buffer WRONG? %d %d\n.\n", i, (i) % 4);
      done = 1;
   }
}

void  updateKeyboard(SDLKey key, int state)
{
   if (state)
   {
      anyButtonPushedMask = anyButtonPushedMask | (1 << (key & 31));
   }
   else
   {
      anyButtonPushedMask = anyButtonPushedMask & ~(1 << (key & 31));
   }
   switch (key)
   {
   case SDLK_w:
      mrboom_update_input(button_up, nb_dyna - 2, state, false);
      break;

   case SDLK_s:
      mrboom_update_input(button_down, nb_dyna - 2, state, false);
      break;

   case SDLK_a:
      mrboom_update_input(button_left, nb_dyna - 2, state, false);
      break;

   case SDLK_d:
      mrboom_update_input(button_right, nb_dyna - 2, state, false);
      break;

   case SDLK_LALT:
      mrboom_update_input(button_a, nb_dyna - 2, state, false);
      break;

   case SDLK_LCTRL:
      mrboom_update_input(button_b, nb_dyna - 2, state, false);
      break;

   case SDLK_LSHIFT:
      mrboom_update_input(button_x, nb_dyna - 2, state, false);
      break;

   case SDLK_SPACE:
      mrboom_update_input(button_select, nb_dyna - 2, state, false);
#ifdef TESTING
      activeCheatMode();
      log_info("cheate mode active");
#endif
      break;

   case SDLK_RETURN:
      mrboom_update_input(button_start, nb_dyna - 2, state, false);
      mrboom_update_input(button_start, nb_dyna - 1, state, false);
      break;

   case SDLK_KP_ENTER:
      mrboom_update_input(button_start, nb_dyna - 2, state, false);
      mrboom_update_input(button_start, nb_dyna - 1, state, false);
      mrboom_update_input(button_x, nb_dyna - 1, state, false);      // also jump 1st player
      break;

   case SDLK_UP:
      mrboom_update_input(button_up, nb_dyna - 1, state, false);
      break;

   case SDLK_DOWN:
      mrboom_update_input(button_down, nb_dyna - 1, state, false);
      break;

   case SDLK_LEFT:
      mrboom_update_input(button_left, nb_dyna - 1, state, false);
      break;

   case SDLK_RIGHT:
      mrboom_update_input(button_right, nb_dyna - 1, state, false);
      break;

   case SDLK_PAGEDOWN:
   case SDLK_RALT:
   case SDLK_KP_PERIOD:
      mrboom_update_input(button_a, nb_dyna - 1, state, false);
      break;

   case SDLK_END:
   case SDLK_RCTRL:
   //  case SDLK_RGUI:
   case SDLK_KP0:
      mrboom_update_input(button_b, nb_dyna - 1, state, false);
      break;

   case SDLK_HOME:
   case SDLK_RSHIFT:
      mrboom_update_input(button_x, nb_dyna - 1, state, false);
      break;

   case SDLK_ESCAPE:
      if (state)
      {
         if ((beeingPlaying > BEEING_PLAYING_BUFFER) || !isGameActive())
         {
            pressESC();
         }
         if (inTheMenu())
         {
            done = 1;
         }
      }
      break;

   case SDLK_PAUSE:
   case SDLK_p:
      if (state)
      {
         pauseGameButton();
      }
      break;

   default:
      break;
   }
}

int main(int argc, char **argv)
{
   void *saveDisplay;

   sdl_init();

   mrboom_init();

   display = SDL_SetVideoMode(320, 200, 8, SDL_HWSURFACE | SDL_RESIZABLE);

   updatePalette();

   extern bool audio;
   audio = 0;

   SDL_WM_SetCaption("Mrboom", NULL);

   saveDisplay = display->pixels;

   startClock(0);
   int nbFrames = 0;
#ifdef FALCON
   m.slowcpu = 1;
#endif

   m.temps_avant_demo = 60 * 30;
#ifdef DEMO
   m.temps_avant_demo = 10;
#endif

   if (done)
   {
      mrboom_load(); //to avoid temporary files remaining
   }

   while (!done)
   {
      if (nbFrames == 10)
      {
         mrboom_load();
      }

#ifdef DEMO
      if (nbFrames == 60 * 10)
      {
         done = 1;
      }
#endif
      nbFrames++;
      SDL_LockSurface(display);

#ifdef FALCON
      m.last_sucker = 1;
      program();
      mrboom_update_input_loop();
      mrboom_sound();
      mrboom_tick_ai();
      m.last_sucker = 0;
#else
      if (nbFrames % 2)
      {
         mrboom_tick_ai();
      }
#endif
      program();
      mrboom_update_input_loop();
      mrboom_sound();
      mrboom_reset_special_keys();

      for (int i = 0; i < nb_dyna; i++)
      {
         if (oneButtonJoystick[i])
         {
            mrboom_autopilot_1_button_joysticks(i);
         }
      }
      if (m.ramVideoPointer != NULL)
      {
         display->pixels = m.ramVideoPointer;
      }
      SDL_UnlockSurface(display);

      if (m.vgaPaletteModified)
      {
         updatePalette();
         m.vgaPaletteModified = 0;
      }

      startClock(1);
      if (m.affiche_pal != 1)
      {
         SDL_UpdateRect(display, 0, 0, 320, 200);
      }
      stopClock(1);

      SDL_Event e;

      if (isGameActive())
      {
         beeingPlaying++;
         if (beeingPlaying > BEEING_PLAYING_BUFFER)
         {
            if (anyStartButtonPushedMask && anySelectButtonPushedMask)
            {
               pressESC();
            }
            else
            {
               if (anyStartButtonPushedMask)
               {
                  anyStartButtonPushedCounter++;
                  if (anyStartButtonPushedCounter == 1)
                  {
                     pauseGameButton();
                  }
               }
               else
               {
                  anyStartButtonPushedCounter = 0;
               }
            }
         }
      }
      else
      {
         beeingPlaying = 0;
      }

      while (SDL_PollEvent(&e))
      {
         switch (e.type)
         {
         case SDL_JOYAXISMOTION:
            if (e.jaxis.value < -joystickDeadZone)
            {
               axis[e.jaxis.axis] = -1;
            }
            else if (e.jaxis.value > joystickDeadZone)
            {
               axis[e.jaxis.axis] = 1;
            }
            else
            {
               axis[e.jaxis.axis] = 0;
            }
            if ((e.jaxis.axis == 0) || (e.jaxis.axis == 2))
            {
               if ((axis[0] == 1) || (axis[2] == 1))
               {
                  mrboom_update_input(button_right, e.jaxis.which, 1, false);
                  mrboom_update_input(button_left, e.jaxis.which, 0, false);
               }
               else if ((axis[0] == -1) || (axis[2] == -1))
               {
                  mrboom_update_input(button_left, e.jaxis.which, 1, false);
                  mrboom_update_input(button_right, e.jaxis.which, 0, false);
               }
               else
               {
                  mrboom_update_input(button_left, e.jaxis.which, 0, false);
                  mrboom_update_input(button_right, e.jaxis.which, 0, false);
               }
            }
            if ((e.jaxis.axis == 1) || (e.jaxis.axis == 3))
            {
               if ((axis[1] == 1) || (axis[3] == 1))
               {
                  mrboom_update_input(button_down, e.jaxis.which, 1, false);
                  mrboom_update_input(button_up, e.jaxis.which, 0, false);
               }
               else if ((axis[1] == -1) || (axis[3] == -1))
               {
                  mrboom_update_input(button_up, e.jaxis.which, 1, false);
                  mrboom_update_input(button_down, e.jaxis.which, 0, false);
               }
               else
               {
                  mrboom_update_input(button_up, e.jaxis.which, 0, false);
                  mrboom_update_input(button_down, e.jaxis.which, 0, false);
               }
            }
            break;

         case SDL_JOYHATMOTION:
         {
            int player = e.jhat.which;

            switch (e.jhat.value)
            {
            case SDL_HAT_CENTERED:
               mrboom_update_input(button_up, player, 0, false);
               mrboom_update_input(button_down, player, 0, false);
               mrboom_update_input(button_left, player, 0, false);
               mrboom_update_input(button_right, player, 0, false);
               break;

            case SDL_HAT_UP:
               mrboom_update_input(button_up, player, 1, false);
               mrboom_update_input(button_down, player, 0, false);
               mrboom_update_input(button_left, player, 0, false);
               mrboom_update_input(button_right, player, 0, false);
               break;

            case SDL_HAT_DOWN:
               mrboom_update_input(button_up, player, 0, false);
               mrboom_update_input(button_down, player, 1, false);
               mrboom_update_input(button_left, player, 0, false);
               mrboom_update_input(button_right, player, 0, false);
               break;

            case SDL_HAT_LEFT:
               mrboom_update_input(button_up, player, 0, false);
               mrboom_update_input(button_down, player, 0, false);
               mrboom_update_input(button_left, player, 1, false);
               mrboom_update_input(button_right, player, 0, false);
               break;

            case SDL_HAT_RIGHT:
               mrboom_update_input(button_up, player, 0, false);
               mrboom_update_input(button_down, player, 0, false);
               mrboom_update_input(button_left, player, 0, false);
               mrboom_update_input(button_right, player, 1, false);
               break;

            case SDL_HAT_RIGHTDOWN:
               mrboom_update_input(button_up, player, 0, false);
               mrboom_update_input(button_down, player, 1, false);
               mrboom_update_input(button_left, player, 0, false);
               mrboom_update_input(button_right, player, 1, false);
               break;

            case SDL_HAT_RIGHTUP:
               mrboom_update_input(button_up, player, 1, false);
               mrboom_update_input(button_down, player, 0, false);
               mrboom_update_input(button_left, player, 0, false);
               mrboom_update_input(button_right, player, 1, false);
               break;

            case SDL_HAT_LEFTUP:
               mrboom_update_input(button_up, player, 1, false);
               mrboom_update_input(button_down, player, 0, false);
               mrboom_update_input(button_left, player, 1, false);
               mrboom_update_input(button_right, player, 0, false);
               break;

            case SDL_HAT_LEFTDOWN:
               mrboom_update_input(button_up, player, 0, false);
               mrboom_update_input(button_down, player, 1, false);
               mrboom_update_input(button_left, player, 1, false);
               mrboom_update_input(button_right, player, 0, false);
               break;
            }
         }
         break;

         case SDL_JOYBUTTONDOWN:

            switch (e.jbutton.button)
            {
            case 0:
               mrboom_update_input_j(button_a, e.jaxis.which, 1, false);
               break;

            case 1:
               mrboom_update_input(button_b, e.jaxis.which, 1, false);
               break;

            case 2:
               mrboom_update_input(button_x, e.jaxis.which, 1, false);
               break;

            case 3:
               mrboom_update_input(button_y, e.jaxis.which, 1, false);
               break;

            case 4:
               mrboom_update_input(button_l, e.jaxis.which, 1, false);
               break;

            case 5:
               mrboom_update_input(button_r, e.jaxis.which, 1, false);
               break;

            case 6:
            case 8:
               mrboom_update_input(button_select, e.jaxis.which, 1, false);
               anySelectButtonPushedMask = anySelectButtonPushedMask | (1 << e.jbutton.which);
               break;

            case 7:
            case 9:
               mrboom_update_input(button_start, e.jaxis.which, 1, false);
               anyStartButtonPushedMask = anyStartButtonPushedMask | (1 << e.jbutton.which);
               break;

            case 10:
               mrboom_update_input(button_up, e.jaxis.which, 1, false);
               anyStartButtonPushedMask = anyStartButtonPushedMask & ~(1 << e.jbutton.which);
               break;

            case 11:
               mrboom_update_input(button_down, e.jaxis.which, 1, false);
               anyStartButtonPushedMask = anyStartButtonPushedMask & ~(1 << e.jbutton.which);
               break;

            case 12:
               mrboom_update_input(button_left, e.jaxis.which, 1, false);
               anyStartButtonPushedMask = anyStartButtonPushedMask & ~(1 << e.jbutton.which);
               break;

            case 13:
               mrboom_update_input(button_right, e.jaxis.which, 1, false);
               anyStartButtonPushedMask = anyStartButtonPushedMask & ~(1 << e.jbutton.which);
               break;
            }
            anyButtonPushedMask = anyButtonPushedMask | (1 << e.jbutton.button);
            break;

         case SDL_JOYBUTTONUP:

            switch (e.jbutton.button)
            {
            case 0:
               mrboom_update_input_j(button_a, e.jaxis.which, 0, false);
               break;

            case 1:
               mrboom_update_input(button_b, e.jaxis.which, 0, false);
               break;

            case 2:
               mrboom_update_input(button_x, e.jaxis.which, 0, false);
               break;

            case 3:
               mrboom_update_input(button_y, e.jaxis.which, 0, false);
               break;

            case 4:
               mrboom_update_input(button_l, e.jaxis.which, 0, false);
               break;

            case 5:
               mrboom_update_input(button_r, e.jaxis.which, 0, false);
               break;

            case 6:
            case 8:
               mrboom_update_input(button_select, e.jaxis.which, 0, false);
               anySelectButtonPushedMask = anySelectButtonPushedMask & ~(1 << e.jbutton.which);
               break;

            case 7:
            case 9:
               mrboom_update_input(button_start, e.jaxis.which, 0, false);
               anyStartButtonPushedMask = anyStartButtonPushedMask & ~(1 << e.jbutton.which);
               break;

            case 10:
               mrboom_update_input(button_up, e.jaxis.which, 0, false);
               anyStartButtonPushedMask = anyStartButtonPushedMask & ~(1 << e.jbutton.which);
               break;

            case 11:
               mrboom_update_input(button_down, e.jaxis.which, 0, false);
               anyStartButtonPushedMask = anyStartButtonPushedMask & ~(1 << e.jbutton.which);
               break;

            case 12:
               mrboom_update_input(button_left, e.jaxis.which, 0, false);
               anyStartButtonPushedMask = anyStartButtonPushedMask & ~(1 << e.jbutton.which);
               break;

            case 13:
               mrboom_update_input(button_right, e.jaxis.which, 0, false);
               anyStartButtonPushedMask = anyStartButtonPushedMask & ~(1 << e.jbutton.which);
               break;
            }
            anyButtonPushedMask = anyButtonPushedMask & ~(1 << e.jbutton.button);
            break;

         case SDL_KEYDOWN:
            updateKeyboard(e.key.keysym.sym, 1);
            break;

         case SDL_KEYUP:
            updateKeyboard(e.key.keysym.sym, 0);
            break;

         case SDL_MOUSEBUTTONDOWN:
            break;

         case SDL_QUIT:
            done = 1;
            break;

         default:
            break;
         }
      }
   }

   display->pixels = saveDisplay;
   SDL_Quit();

#ifdef FALCON
#ifdef DEMO
   printf("x fps=%f frames %d\n", (nbFrames) / totalTimeInClock(0), nbFrames);
   printf("x time_spent=%f in updateVga=%f (%f)\n", totalTimeInClock(0), totalTimeInClock(1), totalTimeInClock(1) * 100 / totalTimeInClock(0));
#endif
   char in;
   scanf("%c", &in);
#endif
   return(0);
}
