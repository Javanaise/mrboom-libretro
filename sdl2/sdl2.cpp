#include <stdlib.h>
#include <stdio.h>
#ifdef __EMSCRIPTEN__
#include <emscripten/emscripten.h>
#endif
#include <SDL.h>
#include <time.h>
#include <unistd.h>
#include <getopt.h>
#include "mrboom.h"
#include "common.hpp"
#include "MrboomHelper.hpp"
#include "xbrz.h"

#define IFTRACES (traceMask & DEBUG_SDL2)

#ifdef DEBUG
#define XBRZ_DEFAULT_FACTOR 1
#else
#define XBRZ_DEFAULT_FACTOR 2
#endif
#ifdef __ARM_ARCH_6__
#define XBRZ_DEFAULT_FACTOR 1
#endif
#ifdef __ARM_ARCH_7__
#define XBRZ_DEFAULT_FACTOR 1
#endif

int xbrzFactor = XBRZ_DEFAULT_FACTOR;
int widthTexture = 0;
int heightTexture = 0;

#define BEEING_PLAYING_BUFFER 60
int beeingPlaying = 0;

SDL_Renderer *renderer;
SDL_Texture *texture;
SDL_bool done = SDL_FALSE;
SDL_bool noVGA = SDL_FALSE;

SDL_Joystick *joysticks[nb_dyna] = {0};
SDL_GameController *gameControllers[nb_dyna] = {0};

int joysticksInstance[nb_dyna];

static clock_t begin;
unsigned int nbFrames = 0;
int testAI = 0;
bool slowMode = false;
#define MAX_TURBO 32
int turboMode = 0;
int anyButtonPushedMask = 0;
int anyStartButtonPushedMask = 0;
int anySelectButtonPushedMask = 0;
int framesPlayed = 0;
bool checkDemoMode = false;
bool fullscreen = true;

void quit(int rc)
{
   SDL_Quit();
   exit(rc);
}

void printJoystick()
{
   int i;

   for (i = 0; i < nb_dyna; i++)
   {
      if (gameControllers[i] != 0)
      {
         log_info("Joystick instance %d: (index:%d)\n", joysticksInstance[i], i);
      }
   }
}

void removeJoystick(int instance)
{
   int i;

   if (IFTRACES)
   {
      log_info("Joystick instance %d removed.\n", (int)instance);
   }
   for (i = 0; i < nb_dyna; i++)
   {

      if (joysticksInstance[i] == instance)
      {
         if (gameControllers[i] != 0)
         {
            SDL_GameControllerClose(gameControllers[i]);
            gameControllers[i] = 0;
         }
         joysticks[i] = 0;
         if (IFTRACES)
         {
            log_info("Joystick index/player %d removed.\n", i);
         }
      }
   }
}

void updateInput(int keyid, int playerNumber, int state, bool isIA)
{
   if (!checkDemoMode)
   {
      mrboom_update_input(keyid, playerNumber, state, isIA);
   }
}

void addJoystick(int index)
{
   SDL_GameController *gc;
   SDL_Joystick *joystick = SDL_JoystickOpen(index);
   char guid[64];
   int noFreePlayer = 1;

   if (joystick == NULL)
   {
      log_error("SDL_JoystickOpen(%d) failed: %s\n", index,
                SDL_GetError());
      return;
   }
   SDL_JoystickGetGUIDString(SDL_JoystickGetGUID(joystick), guid, sizeof(guid));
   log_info("Add Joystick index %d GUID:%s JoystickName:%s\n", index, guid, SDL_JoystickNameForIndex(index));
   gc = SDL_GameControllerOpen(index);
   if (gc == NULL)
   {
      log_error("SDL_GameControllerOpen(%d) failed: %s %s\n", index,
                SDL_GetError(), SDL_JoystickNameForIndex(index));
   }
   else
   {
      log_info("SDL_GameControllerName:%s mapping:%s\n", SDL_GameControllerName(gc), SDL_GameControllerMappingForIndex(index));
   }

   for (int i = 0; i < nb_dyna; i++)
   {
      if (joysticks[i] == 0)
      {
         joysticks[i] = joystick;
         gameControllers[i] = gc;
         joysticksInstance[i] = SDL_JoystickInstanceID(joystick);
         if (IFTRACES)
         {
            log_info("Joystick instance %d added for player %d\n", joysticksInstance[i], i);
         }
         noFreePlayer = 0;
         return;
      }
   }

   if (noFreePlayer)
   {
      if (IFTRACES)
      {
         log_info("Joystick cant be added (noFreePlayer)\n");
      }
   }
}

#define NB_SCREENS_BLURRING 8

void UpdateTexture(SDL_Texture *texture, bool skipRendering)
{
   static uint32_t matrixPalette[NB_COLORS_PALETTE];
   static uint32_t previousScreen[WIDTH][HEIGHT][NB_SCREENS_BLURRING];
   static int numberOfScreenToMelt = 1;

   Uint32 *dst;
   uint32_t src[WIDTH * HEIGHT];
   static uint32_t *trg = NULL;

   if (trg == NULL)
   {
      trg = (uint32_t *)malloc(widthTexture * heightTexture * sizeof(uint32_t));
   }
   int row, col;
   void *pixels;
   int pitch;

   if (SDL_LockTexture(texture, NULL, &pixels, &pitch) < 0)
   {
      log_error("Couldn't lock texture: %s\n", SDL_GetError());
      quit(5);
   }
   int z = 0;
   do
   {
      matrixPalette[z / 3] = ((m.vgaPalette[z + 0] << 2) | (m.vgaPalette[z + 0] >> 4)) << 16;
      matrixPalette[z / 3] |= ((m.vgaPalette[z + 1] << 2) | (m.vgaPalette[z + 1] >> 4)) << 8;
      matrixPalette[z / 3] |= ((m.vgaPalette[z + 2] << 2) | (m.vgaPalette[z + 2] >> 4)) << 0;
      z += 3;
   } while (z != NB_COLORS_PALETTE * 3);

   for (row = 0; row < HEIGHT; ++row)
   {
      dst = (Uint32 *)((Uint8 *)pixels + row * pitch);
      for (col = 0; col < WIDTH; ++col)
      {
         uint32_t color;
         if (m.affiche_pal != 1)
         {
            color = matrixPalette[m.buffer[col + row * WIDTH]];
            m.vgaRam[col + row * WIDTH] = m.buffer[col + row * WIDTH];
         }
         else
         {
            color = matrixPalette[m.vgaRam[col + row * WIDTH]];
         }
         previousScreen[col][row][frameNumber() % NB_SCREENS_BLURRING] = color;
         // uint32_t color = matrixPalette[m.vgaRam[col + row * WIDTH]];
         // previousScreen[col][row][frameNumber() % NB_SCREENS_BLURRING] = color;
         if (skipRendering)
         {
            uint32_t b = 0;
            uint32_t r = 0;
            uint32_t g = 0;
            for (int z = 0; z < numberOfScreenToMelt; z++)
            {
               uint32_t prevColor = previousScreen[col][row][(NB_SCREENS_BLURRING - z + frameNumber()) % NB_SCREENS_BLURRING];
               b += prevColor & 255;
               r += (prevColor >> 8) & 255;
               g += (prevColor >> 16) & 255;
            }
            b = b / (numberOfScreenToMelt);
            r = r / (numberOfScreenToMelt);
            g = g / (numberOfScreenToMelt);
            color = (g << 16) | (r << 8) | b;
            if (numberOfScreenToMelt < NB_SCREENS_BLURRING - 1)
            {
               numberOfScreenToMelt += 2;
            }
         }
         else
         {
            numberOfScreenToMelt = 1;
         }
         if (xbrzFactor != 1)
         {
            src[col + row * WIDTH] = color;
         }
         else
         {
            *dst++ = color;
         }
      }
   }

   if (xbrzFactor != 1)
   {
      scale(xbrzFactor, // valid range: 2 - 6
            (uint32_t *)src, trg, WIDTH, HEIGHT,
            xbrz::ColorFormat::RGB);

      for (row = 0; row < heightTexture; ++row)
      {
         dst = (Uint32 *)((Uint8 *)pixels + row * pitch);
         for (col = 0; col < widthTexture; ++col)
         {
            *dst++ = trg[row * widthTexture + col];
         }
      }
   }

   SDL_UnlockTexture(texture);
}

int getPlayerFromJoystickPort(int instance)
{
   int i;

   for (i = 0; i < nb_dyna; i++)
   {
      if (joysticks[i] != 0)
      {
         if (joysticksInstance[i] == instance)
         {
            return (i);
         }
      }
   }
   log_error("Error getPlayerFromJoystickPort %d\n", instance);
   return (0);
}

int getPlayerAndTypeOfJoystickFromPort(int instance, bool *isControler)
{
   int i;

   for (i = 0; i < nb_dyna; i++)
   {
      if (joysticks[i] != 0)
      {
         if (joysticksInstance[i] == instance)
         {
            *isControler = (gameControllers[i] != 0);
            return (i);
         }
      }
   }
   log_error("Error getPlayerFromJoystickPort %d\n", instance);
   return (nb_dyna);
}

void updateKeyboard(Uint8 scancode, int state)
{
   if (IFTRACES)
   {
      log_info("updateKeyboard %d\n", scancode);
   }
   if (state)
   {
      anyButtonPushedMask = anyButtonPushedMask | (1 << (scancode & 31));
   }
   else
   {
      anyButtonPushedMask = anyButtonPushedMask & ~(1 << (scancode & 31));
   }
   switch (scancode)
   {
   case SDL_SCANCODE_W:
      updateInput(button_up, nb_dyna - 2, state, false);
      break;

   case SDL_SCANCODE_S:
      updateInput(button_down, nb_dyna - 2, state, false);
      break;

   case SDL_SCANCODE_A:
      updateInput(button_left, nb_dyna - 2, state, false);
      break;

   case SDL_SCANCODE_D:
      updateInput(button_right, nb_dyna - 2, state, false);
      break;

   case SDL_SCANCODE_LALT:
      updateInput(button_a, nb_dyna - 2, state, false);
      break;

   case SDL_SCANCODE_LCTRL:
   case SDL_SCANCODE_LGUI:
      updateInput(button_b, nb_dyna - 2, state, false);
      break;

   case SDL_SCANCODE_LSHIFT:
      updateInput(button_x, nb_dyna - 2, state, false);
      break;

   case SDL_SCANCODE_SPACE:
      updateInput(button_select, nb_dyna - 2, state, false);
      break;

   case SDL_SCANCODE_RETURN:
      updateInput(button_start, nb_dyna - 2, state, false);
      updateInput(button_start, nb_dyna - 1, state, false);
      updateInput(button_a, nb_dyna - 1, state, false);
      break;

   case SDL_SCANCODE_KP_ENTER:
      updateInput(button_start, nb_dyna - 2, state, false);
      updateInput(button_start, nb_dyna - 1, state, false);
      updateInput(button_x, nb_dyna - 1, state, false); // also jump 1st player
      break;

   case SDL_SCANCODE_UP:
      updateInput(button_up, nb_dyna - 1, state, false);
      break;

   case SDL_SCANCODE_DOWN:
      updateInput(button_down, nb_dyna - 1, state, false);
      break;

   case SDL_SCANCODE_LEFT:
      updateInput(button_left, nb_dyna - 1, state, false);
      break;

   case SDL_SCANCODE_RIGHT:
      updateInput(button_right, nb_dyna - 1, state, false);
      break;
   case SDL_SCANCODE_F1:
      updateInput(button_l, nb_dyna - 1, state, false);
      break;
   case SDL_SCANCODE_F2:
      updateInput(button_r, nb_dyna - 1, state, false);
      break;
   case SDL_SCANCODE_PAGEDOWN:
   case SDL_SCANCODE_KP_PERIOD:
      updateInput(button_a, nb_dyna - 1, state, false);
      break;

   case SDL_SCANCODE_END:
   case SDL_SCANCODE_RCTRL:
   case SDL_SCANCODE_RGUI:
   case SDL_SCANCODE_KP_0:
      log_info("button_b %d i:%d\n", state, nb_dyna - 1);
      updateInput(button_b, nb_dyna - 1, state, false);
      break;

   case SDL_SCANCODE_HOME:
   case SDL_SCANCODE_RSHIFT:
      updateInput(button_x, nb_dyna - 1, state, false);
      break;

   case SDL_SCANCODE_ESCAPE:
      if (state)
      {
         if ((beeingPlaying > BEEING_PLAYING_BUFFER) || !isGameActive())
         {
            pressESC();
         }
         if (inTheMenu())
         {
            done = SDL_TRUE;
         }
      }
      break;

   case SDL_SCANCODE_PAUSE:
   case SDL_SCANCODE_P:
      if (state)
      {
         pauseGameButton();
      }
      break;

   default:
      if (IFTRACES)
      {
         log_info("updateKeyboard not handled %d %d\n", scancode, state);
      }
      break;
   }
}

#define DEFAULT_DEAD_ZONE 8000

int joystickDeadZone = DEFAULT_DEAD_ZONE;
int anyStartButtonPushedCounter = 0;
uint32_t windowID;
static const float ASPECT_RATIO = float(WIDTH) / float(HEIGHT);

bool resizeDone = false;
SDL_Rect screen;
SDL_Window *window;
int width = 0;
int height = 0;

#define NB_STICKS_MAX_PER_PAD 2

int axis[NB_STICKS_MAX_PER_PAD * 2] = {0, 0, 0, 0};

void pollEvent()
{
   SDL_Event e;
   int player = nb_dyna;
   while (SDL_PollEvent(&e))
   {
      bool isController = false;

      switch (e.type)
      {

      case SDL_WINDOWEVENT:
         if (e.window.windowID == windowID)
         {
            switch (e.window.event)
            {
            case SDL_WINDOWEVENT_RESIZED:
            {
               width = e.window.data1;
               height = e.window.data2;
               float aspectRatio = (float)width / (float)height;
               if (abs(aspectRatio - ASPECT_RATIO) > 0.1)
               {
                  if (aspectRatio < ASPECT_RATIO)
                  {
                     height = (1.f / ASPECT_RATIO) * width;
                  }
                  else
                  {
                     width = ASPECT_RATIO * height;
                  }
                  log_debug("Setting window size to %d, %d, aspect ratio: %f\n",
                            width, height, (float)width / (float)height);
               }
               else
               {
                  log_debug("skip resize %f %f\n", aspectRatio, ASPECT_RATIO);
                  break;
               }
               screen.w = width;
               screen.h = height;
               resizeDone = true;
               break;
            }
            }
         }
         break;
      case SDL_CONTROLLERDEVICEADDED:
         log_debug("SDL_CONTROLLERDEVICEADDED %d\n", e.cdevice.which);
         break;
      case SDL_CONTROLLERDEVICEREMOVED:
         log_debug("SDL_CONTROLLERDEVICEREMOVED %d\n", e.cdevice.which);
         break;
      case SDL_JOYDEVICEADDED:
         log_debug("SDL_JOYDEVICEADDED %d\n", e.cdevice.which);
         addJoystick(e.cdevice.which);
         break;
      case SDL_JOYDEVICEREMOVED:
         log_debug("SDL_JOYDEVICEREMOVED %d\n", e.cdevice.which);
         removeJoystick(e.jdevice.which);
         break;
      case SDL_JOYAXISMOTION:
         player = getPlayerAndTypeOfJoystickFromPort(e.jaxis.which, &isController);
         if (IFTRACES)
         {
            log_info("SDL_JOYAXISMOTION\n");
         }
         if (player == nb_dyna)
         {
            log_error("player == nb_dyna\n");
            break;
         }
         if (isController)
         {
            break;
         }
         else
         {
            if (IFTRACES)
               log_info("no mapping so simulating:\n");
         }
      case SDL_CONTROLLERAXISMOTION:
         if (IFTRACES)
         {
            log_info("SDL_CONTROLLERAXISMOTION\n");
         }
         if (e.jaxis.axis >= NB_STICKS_MAX_PER_PAD * 2)
         {
            if (IFTRACES)
            {
               log_info("ignoring e.jaxis.axis=%d e.jaxis.value=%d e.caxis.value=%d player=%d\n", e.jaxis.axis, e.jaxis.value, e.caxis.value, getPlayerFromJoystickPort(e.jaxis.which));
            }
            break;
         }

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

         if (IFTRACES)
         {
            log_info("e.jaxis.axis=%d e.jaxis.value=%06d e.caxis.value=%06d player=%d ", e.jaxis.axis, e.jaxis.value, e.caxis.value, getPlayerFromJoystickPort(e.jaxis.which));
         }
         if ((e.jaxis.axis == 0) || (e.jaxis.axis == 2))
         {
            if ((axis[0] == 1) || (axis[2] == 1))
            {
               if (IFTRACES)
               {
                  log_info(" pad RIGHT\n");
               }
               updateInput(button_right, getPlayerFromJoystickPort(e.jaxis.which), 1, false);
               updateInput(button_left, getPlayerFromJoystickPort(e.jaxis.which), 0, false);
            }
            else if ((axis[0] == -1) || (axis[2] == -1))
            {
               if (IFTRACES)
               {
                  log_info(" pad LEFT\n");
               }
               updateInput(button_left, getPlayerFromJoystickPort(e.jaxis.which), 1, false);
               updateInput(button_right, getPlayerFromJoystickPort(e.jaxis.which), 0, false);
            }
            else
            {
               if (IFTRACES)
               {
                  log_info(" pad MIDDLE X\n");
               }
               updateInput(button_left, getPlayerFromJoystickPort(e.jaxis.which), 0, false);
               updateInput(button_right, getPlayerFromJoystickPort(e.jaxis.which), 0, false);
            }
         }
         if ((e.jaxis.axis == 1) || (e.jaxis.axis == 3))
         {
            if ((axis[1] == 1) || (axis[3] == 1))
            {
               if (IFTRACES)
               {
                  log_info(" pad DOWN\n");
               }
               updateInput(button_down, getPlayerFromJoystickPort(e.jaxis.which), 1, false);
               updateInput(button_up, getPlayerFromJoystickPort(e.jaxis.which), 0, false);
            }
            else if ((axis[1] == -1) || (axis[3] == -1))
            {
               if (IFTRACES)
               {
                  log_info(" pad UP\n");
               }
               updateInput(button_up, getPlayerFromJoystickPort(e.jaxis.which), 1, false);
               updateInput(button_down, getPlayerFromJoystickPort(e.jaxis.which), 0, false);
            }
            else
            {
               if (IFTRACES)
               {
                  log_info(" pad MIDDLE Y\n");
               }
               updateInput(button_up, getPlayerFromJoystickPort(e.jaxis.which), 0, false);
               updateInput(button_down, getPlayerFromJoystickPort(e.jaxis.which), 0, false);
            }
         }
         break;
      case SDL_JOYHATMOTION:
      {
         int player = getPlayerFromJoystickPort(e.jhat.which);
         if (IFTRACES)
         {
            log_info("SDL_JOYHATMOTION: .jhat=%d which=%d player=%d\n", e.jhat.value, e.jhat.which, getPlayerFromJoystickPort(e.jhat.which));
         }

         switch (e.jhat.value)
         {
         case SDL_HAT_CENTERED:
            updateInput(button_up, player, 0, false);
            updateInput(button_down, player, 0, false);
            updateInput(button_left, player, 0, false);
            updateInput(button_right, player, 0, false);
            break;

         case SDL_HAT_UP:
            updateInput(button_up, player, 1, false);
            updateInput(button_down, player, 0, false);
            updateInput(button_left, player, 0, false);
            updateInput(button_right, player, 0, false);
            break;

         case SDL_HAT_DOWN:
            updateInput(button_up, player, 0, false);
            updateInput(button_down, player, 1, false);
            updateInput(button_left, player, 0, false);
            updateInput(button_right, player, 0, false);
            break;

         case SDL_HAT_LEFT:
            updateInput(button_up, player, 0, false);
            updateInput(button_down, player, 0, false);
            updateInput(button_left, player, 1, false);
            updateInput(button_right, player, 0, false);
            break;

         case SDL_HAT_RIGHT:
            updateInput(button_up, player, 0, false);
            updateInput(button_down, player, 0, false);
            updateInput(button_left, player, 0, false);
            updateInput(button_right, player, 1, false);
            break;

         case SDL_HAT_RIGHTDOWN:
            updateInput(button_up, player, 0, false);
            updateInput(button_down, player, 1, false);
            updateInput(button_left, player, 0, false);
            updateInput(button_right, player, 1, false);
            break;

         case SDL_HAT_RIGHTUP:
            updateInput(button_up, player, 1, false);
            updateInput(button_down, player, 0, false);
            updateInput(button_left, player, 0, false);
            updateInput(button_right, player, 1, false);
            break;

         case SDL_HAT_LEFTUP:
            updateInput(button_up, player, 1, false);
            updateInput(button_down, player, 0, false);
            updateInput(button_left, player, 1, false);
            updateInput(button_right, player, 0, false);
            break;

         case SDL_HAT_LEFTDOWN:
            updateInput(button_up, player, 0, false);
            updateInput(button_down, player, 1, false);
            updateInput(button_left, player, 1, false);
            updateInput(button_right, player, 0, false);
            break;
         }
      }
      break;
      case SDL_JOYBUTTONDOWN:
         player = getPlayerAndTypeOfJoystickFromPort(e.jbutton.which, &isController);
         if (IFTRACES)
         {
            log_info("Joystick %d button %d isController %d DOWN\n", e.jbutton.which, e.jbutton.button, isController);
         }
         if (player == nb_dyna)
         {
            log_error("player == nb_dyna\n");
            break;
         }
         if (isController)
         {
            break;
         }
         else
         {
            if (IFTRACES)
               log_info("no mapping so simulating:\n");
         }
      case SDL_CONTROLLERBUTTONDOWN:
         player = getPlayerAndTypeOfJoystickFromPort(e.jbutton.which, &isController);
         if (IFTRACES)
         {
            log_info("Controller %d button %d/%d isController %d DOWN\n", e.jbutton.which, e.jbutton.button, e.cbutton.button, isController);
         }
         if (player == nb_dyna)
         {
            log_error("player == nb_dyna\n");
            break;
         }

         switch (e.cbutton.button)
         {
         case SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_A:

         
            updateInput(button_a, player, 1, false);
            if (IFTRACES)
               log_info("SDL_CONTROLLER_BUTTON_A\n");
            break;

         case SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_B:
            updateInput(button_b, player, 1, false);
            if (IFTRACES)
               log_info("SDL_CONTROLLER_BUTTON_B\n");
            break;

         case SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_X:
            if (IFTRACES)
               log_info("SDL_CONTROLLER_BUTTON_X\n");
            updateInput(button_x, player, 1, false);
            break;

         case SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_Y:
            if (IFTRACES)
               log_info("SDL_CONTROLLER_BUTTON_Y\n");
            updateInput(button_y, player, 1, false);
            break;

         case SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_LEFTSHOULDER:
            if (IFTRACES)
               log_info("SDL_CONTROLLER_BUTTON_LEFTSHOULDER\n");
            updateInput(button_l, player, 1, false);
            break;

         case SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_RIGHTSHOULDER:
            if (IFTRACES)
               log_info("SDL_CONTROLLER_BUTTON_RIGHTSHOULDER\n");
            updateInput(button_r, player, 1, false);
            break;

         case SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_BACK:
            if (IFTRACES)
               log_info("SDL_CONTROLLER_BUTTON_BACK\n");
            updateInput(button_select, player, 1, false);
            anySelectButtonPushedMask = anySelectButtonPushedMask | (1 << e.jbutton.which);
            break;
         case SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_START:
            if (IFTRACES)
               log_info("SDL_CONTROLLER_BUTTON_START\n");
            updateInput(button_start, player, 1, false);
            anyStartButtonPushedMask = anyStartButtonPushedMask | (1 << e.jbutton.which);
            break;
            /*
                     case SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_DPAD_UP:
                        if (IFTRACES) log_debug("SDL_CONTROLLER_BUTTON_DPAD_UP\n");
                        updateInput(button_up, player, 1, false);
                        anyStartButtonPushedMask = anyStartButtonPushedMask & ~(1 << e.jbutton.which);
                        break;

                     case SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_DPAD_DOWN:
                        if (IFTRACES) log_debug("SDL_CONTROLLER_BUTTON_DPAD_DOWN\n");
                        updateInput(button_down, player, 1, false);
                        anyStartButtonPushedMask = anyStartButtonPushedMask & ~(1 << e.jbutton.which);
                        break;

                     case SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_DPAD_LEFT:
                        if (IFTRACES) log_debug("SDL_CONTROLLER_BUTTON_DPAD_LEFT\n");
                        updateInput(button_left, player, 1, false);
                        anyStartButtonPushedMask = anyStartButtonPushedMask & ~(1 << e.jbutton.which);
                        break;

                     case SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_DPAD_RIGHT:
                        if (IFTRACES) log_debug("SDL_CONTROLLER_BUTTON_DPAD_RIGHT\n");
                        updateInput(button_right, player, 1, false);
                        anyStartButtonPushedMask = anyStartButtonPushedMask & ~(1 << e.jbutton.which);
                        break;
            */
         default:
            if (IFTRACES)
               log_info("unknown button\n");
            break;
         }
         anyButtonPushedMask = anyButtonPushedMask | (1 << e.jbutton.button);
         break;
      case SDL_JOYBUTTONUP:
         player = getPlayerAndTypeOfJoystickFromPort(e.jbutton.which, &isController);
         if (IFTRACES)
         {
            log_info("Joystick %d button %d isController %d UP\n", e.jbutton.which, e.jbutton.button, isController);
         }
         if (player == nb_dyna)
         {
            log_error("player == nb_dyna\n");
            break;
         }
         if (isController)
         {

            break;
         }
         else
         {
            if (IFTRACES)
               log_info("no mapping so simulating:\n");
         }
      case SDL_CONTROLLERBUTTONUP:
         player = getPlayerAndTypeOfJoystickFromPort(e.jbutton.which, &isController);
         if (IFTRACES)
         {
            log_info("Controller %d button %d isController %d UP\n", e.jbutton.which, e.jbutton.button, isController);
         }
         switch (e.jbutton.button)
         {
         case SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_A:
            if (IFTRACES)
               log_info("SDL_CONTROLLER_BUTTON_A\n");
            updateInput(button_a, player, 0, false);
            break;

         case SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_B:
            if (IFTRACES)
               log_info("SDL_CONTROLLER_BUTTON_B\n");
            updateInput(button_b, player, 0, false);
            break;

         case SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_X:
            if (IFTRACES)
               log_info("SDL_CONTROLLER_BUTTON_X\n");
            updateInput(button_x, player, 0, false);
            break;

         case SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_Y:
            if (IFTRACES)
               log_info("SDL_CONTROLLER_BUTTON_Y\n");
            updateInput(button_y, player, 0, false);
            break;

         case SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_LEFTSHOULDER:
            if (IFTRACES)
               log_info("SDL_CONTROLLER_BUTTON_LEFTSHOULDER\n");
            updateInput(button_l, player, 0, false);
            break;

         case SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_RIGHTSHOULDER:
            if (IFTRACES)
               log_info("SDL_CONTROLLER_BUTTON_RIGHTSHOULDER\n");
            updateInput(button_r, player, 0, false);
            break;

         case SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_BACK:
            if (IFTRACES)
               log_info("SDL_CONTROLLER_BUTTON_BACK\n");
            updateInput(button_select, player, 0, false);
            anySelectButtonPushedMask = anySelectButtonPushedMask & ~(1 << e.jbutton.which);
            break;

         case SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_START:
            if (IFTRACES)
               log_info("SDL_CONTROLLER_BUTTON_START\n");
            updateInput(button_start, player, 0, false);
            anyStartButtonPushedMask = anyStartButtonPushedMask & ~(1 << e.jbutton.which);
            break;
            /*
                     case SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_DPAD_UP:
                        if (IFTRACES) log_debug("SDL_CONTROLLER_BUTTON_DPAD_UP\n");
                        updateInput(button_up, player, 0, false);
                        anyStartButtonPushedMask = anyStartButtonPushedMask & ~(1 << e.jbutton.which);
                        break;

                     case SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_DPAD_DOWN:
                        if (IFTRACES) log_debug("SDL_CONTROLLER_BUTTON_DPAD_DOWN\n");
                        updateInput(button_down, player, 0, false);
                        anyStartButtonPushedMask = anyStartButtonPushedMask & ~(1 << e.jbutton.which);
                        break;

                     case SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_DPAD_LEFT:
                        if (IFTRACES) log_debug("SDL_CONTROLLER_BUTTON_DPAD_LEFT\n");
                        updateInput(button_left, player, 0, false);
                        anyStartButtonPushedMask = anyStartButtonPushedMask & ~(1 << e.jbutton.which);
                        break;

                     case SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_DPAD_RIGHT:
                        if (IFTRACES) log_debug("SDL_CONTROLLER_BUTTON_DPAD_RIGHT\n");
                        updateInput(button_right, player, 0, false);
                        anyStartButtonPushedMask = anyStartButtonPushedMask & ~(1 << e.jbutton.which);
                        break;
                     */
         default:
            if (IFTRACES)
               log_info("unknown button\n");
            break;
         }
         anyButtonPushedMask = anyButtonPushedMask & ~(1 << e.jbutton.button);
         break;

      case SDL_KEYDOWN:
         updateKeyboard(e.key.keysym.scancode, 1);
         break;

      case SDL_KEYUP:
         updateKeyboard(e.key.keysym.scancode, 0);
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
}
void loop()
{

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

   if (checkDemoMode)
   {
      static int zz = 0;
      static int frameResult[16] = {
          195663, 60551, 77663, 53283, 45147, 79144, 75015, 149583, 65639, 142559, 182999, 132883, 172439, 123599, 202267, 112111};
      static bool isActive = false;
      bool currentActive = !inTheMenu();

      if (!currentActive && isActive)
      {
         int fn = frameNumber();
         if (frameResult[zz] != fn)
         {
            log_error("Failed check on demo %d\n", zz + 1);
            exit(1);
         }
         else
         {
            log_info("Checked demo %d/16 %d:OK\n", zz + 1, fn);
         }
         zz++;
         if (zz == 16)
         {
            log_info("SUCCESS check demos\n");
            exit(0);
         }
      }
      isActive = currentActive;
      turboMode = MAX_TURBO;
   }

   pollEvent();

   mrboom_deal_with_autofire();
   mrboom_loop();

#ifdef DEBUG
   if (mrboom_debug_state_failed())
   {
      log_error("mrboom_debug_state_failed!\n");
      exit(1);
   }
#endif

   if (m.executionFinished)
   {
      done = SDL_TRUE;
   }

   mrboom_sound();

   bool skipRendering = false;
   static bool showFrame[MAX_TURBO][MAX_TURBO];
   static bool calculateShowFrame = true;
   int counter = 0;

#define INT_SCALING 100000
   if (calculateShowFrame)
   {
      for (int i = 0; i < MAX_TURBO; i++)
      {
         int delta = ((MAX_TURBO - i) * INT_SCALING) / MAX_TURBO; // between 100 and 0
         for (int j = 0; j < MAX_TURBO; j++)
         {
            counter += delta;
            if (counter >= INT_SCALING)
            {
               counter -= INT_SCALING;
               showFrame[i][j] = true;
            }
            else
            {
               showFrame[i][j] = false;
            }
         }
      }
      calculateShowFrame = false;
   }

   static int anyButtonPushedMaskSave = 0;
   bool goTurbo = false;
   if (!anyButtonPushedMask)
   {
      anyButtonPushedMaskSave = 0;
   }
   if (someHumanPlayersNotDead())
   {
      anyButtonPushedMaskSave = anyButtonPushedMask;
   }
   else
   {
      if (!isAboutToWin() && isGameActive())
      {
         if (anyButtonPushedMaskSave != anyButtonPushedMask) // to avoid speeding straight away when still holding current keys
         {
            goTurbo = true;
         }
      }
   }
   if (goTurbo)
   {
      if (!turboMode)
      {
         turboMode = 1;
      }
      if (!(frameNumber() % 32) && (turboMode < MAX_TURBO / 2))
      {
         turboMode++;
      }
   }
   else
   {
      if (!(frameNumber() % 32) && (turboMode))
      {
         turboMode--;
      }
   }

   int phaseShowFrame = turboMode ? turboMode + MAX_TURBO / 2 : 0;
   if (phaseShowFrame > MAX_TURBO - 1)
   {
      phaseShowFrame = MAX_TURBO - 1;
   }
   if (showFrame[phaseShowFrame][frameNumber() % MAX_TURBO])
   {
      skipRendering = false;
   }
   else
   {
      skipRendering = true;
   }
   static bool previousSkipRendering = false;

   if ((isGameActive() == false) || isGamePaused())
   {
      previousSkipRendering = false;
      turboMode = 0;
   }
   if (noVGA == SDL_FALSE)
   {
      UpdateTexture(texture, previousSkipRendering);
      previousSkipRendering = skipRendering;
   }
   if ((noVGA == SDL_FALSE) && skipRendering == false)
   {
      SDL_RenderClear(renderer);
      SDL_RenderCopy(renderer, texture, NULL, NULL);
      SDL_RenderPresent(renderer);
   }

#ifdef __EMSCRIPTEN__
   if (done)
   {
      emscripten_cancel_main_loop();
   }
#endif
}

static void fps()
{
   nbFrames++;
   if (!(nbFrames % 600) && (IFTRACES))
   {
      clock_t end = clock();
      double time_spent = (double)(end - begin) / CLOCKS_PER_SEC;
      log_debug("x time_spent=%f %d\n", time_spent, nbFrames);
      log_debug("x fps=%f\n", nbFrames / time_spent);
   }
}

void printKeys()
{
   log_info("Keys   Space - Add a bomberman bot\n");
   log_info("       Return - Start a game\n");
   log_info("       P or Pause/Break - Pause\n");
   log_info("       ESC - Quit\n");
   log_info("1st player\n");
   log_info("       Left - Left\n");
   log_info("       Right - Right\n");
   log_info("       Up - Up\n");
   log_info("       Down - Down\n");
#ifdef __APPLE__
   log_info("       Right Ctrl, End, Keypad 0 or Right Command - Lay bomb\n");
#else
   log_info("       Right Ctrl, End, Keypad 0 or Right GUI - Lay bomb\n");
#endif
   log_info("       Return, Keypad Dot or PageDown - Ignite bomb\n");
   log_info("       Right Shift, Keypad Enter or Home - Jump\n");
   log_info("2nd player\n");
   log_info("       A - Left\n");
   log_info("       D - Right\n");
   log_info("       W - Up\n");
   log_info("       S - Down\n");
#ifdef __APPLE__
   log_info("       Left Ctrl or Left Command - Lay bomb\n");
#else
   log_info("       Left Ctrl or Left GUI - Lay bomb\n");
#endif
   log_info("       Left Alt - Ignite bomb\n");
   log_info("       Left Shift - Jump\n\n");
   log_info("run with -h to list options\n");
}

void manageTestAI()
{
   static bool doItOnce = true;
   static bool doItOnce2 = true;

   if (isGameActive() == false)
   {
      if (numberOfPlayers() != testAI)
      {
         addOneAIPlayer();
      }
      else
      {
         if (doItOnce)
         {
            pressStart();
            doItOnce = false;
         }
      }
   }
   else
   {
      if (cheatMode && doItOnce2)
      {
         activeCheatMode();
         doItOnce2 = false;
      }
   }
}

int exitAtFrameNumber = 0;
bool exitAtFrame = false;
int main(int argc, char **argv)
{
   bool showVersion = false;
   int c;

   while (1)
   {
      static struct option long_options[] =
          {
              {"fx", required_argument, 0, 'f'},
              {"help", no_argument, 0, 'h'},
              {"level", required_argument, 0, 'l'},
              {"mapping", required_argument, 0, 'm'},
              {"sex", no_argument, 0, 's'},
              {"color", no_argument, 0, 'c'},
              {"noautofire", no_argument, 0, 'n'},
              {"version", no_argument, 0, 'v'},
              {"debugtraces", required_argument, 0, 'd'},
              {"cheat", no_argument, 0, '1'},
              {"slow", no_argument, 0, '2'},
              {"frame", required_argument, 0, '3'},
              {"exit", required_argument, 0, '4'},
              {"tracemask", required_argument, 0, 't'},
              {"aitest", required_argument, 0, 'a'},
              {"nomusic", no_argument, 0, 'z'},
              {"xbrz", required_argument, 0, 'x'},
              {"skynet", no_argument, 0, 'k'},
              {"deadzone", required_argument, 0, 'd'},
              {"checkDemoMode", no_argument, 0, 'e'},
              {0, 0, 0, 0}};
      /* getopt_long stores the option index here. */
      int option_index = 0;

      c = getopt_long(argc, argv, "hl:m:scv123:4:t:f:o:a:nzx:kd:e",
                      long_options, &option_index);

      /* Detect the end of the options. */
      if (c == -1)
      {
         break;
      }
      switch (c)
      {
      case 'h':
         log_info("Usage: mrboom [options]\n");
         log_info("Options:\n");
         log_info("  -f <x>, --fx <x>\t\tFX volume: from 0 to 10\n");
         log_info("  -h, --help     \t\tShow summary of options\n");
         log_info("  -l <x>, --level <x>\t\tStart in level 0:Candy 1:Pinguine 2:Pink\n");
         log_info("                     \t\t3:Jungle 4:Board 5:Soccer 6:Sky 7:Aliens\n");
         log_info("  -m <file>, --mapping\t\tAdd SDL gamecontroller mapping file\n");
         log_info("  -s, --sex     \t\tSex team mode\n");
         log_info("  -c, --color     \t\tColor team mode\n");
         log_info("  -k, --skynet     \t\tHumans vs. machines mode\n");
         log_info("  -d <x>, --deadzone <x>\tSet joysticks dead zone, default is %d\n", DEFAULT_DEAD_ZONE);
         log_info("  -z, --nomusic     \t\tNo music\n");
         log_info("  -v, --version  \t\tDisplay version\n");
#ifdef DEBUG
         log_info("Debugging options:\n");
         log_info("  -x <x>, --xbrz <x>\t\tSet xBRZ shader factor: from 1 to 6 (default is %d, 1 is off)\n", XBRZ_DEFAULT_FACTOR);
         log_info("  -o <x>, --output <x>\t\tDebug traces to <x> file\n");
         log_info("  -t <x>, --tracemask <x>\tDebug traces mask <x>:\n");         
         log_info("                  \t\t1 to 128 player selection bit\n");
         log_info("                  \t\t256 Grids\n");
         log_info("                  \t\t512 Bot tree decisions\n");
         log_info("                  \t\t1024 SDL2 stuff\n");

         for (int i = 0; i < nb_dyna; i++)
         {
            const char *desc[nb_dyna] = {"white male", "white female", "red male", "red female", "blue male", "blue female", "green male", "green female"};

            log_info("                  \t\t%d all traces %s (#%d)\n", 256 + 512 + (1 << i), desc[i], i);
         }
         log_info("  -1, --cheat    \t\tActivate F1/F2 and L1/L2 pad key for debugging\n");
         log_info("  -2, --slow    \t\tSlow motion for AI debugging\n");
         log_info("  -3 <x>, --frame <x>    \tSet frame for randomness debugging\n");
         log_info("  -4 <x>, --exit <x>    \tExit at frame <x> use x = -1 to exit after one game\n");
         log_info("  -a <x>, --aitest <x>    \tTest <x> AI players\n");
#endif         
         exit(0);
         break;

      case 't':
         traceMask = atoi(optarg);
         log_info("-t option given. Set tracemask to %d.\n", traceMask);
         fullscreen = false;
         break;

      case 'f':
         sdl2_fx_volume = atoi(optarg);
         if ((sdl2_fx_volume < 0) || (sdl2_fx_volume > 10))
         {
            sdl2_fx_volume = DEFAULT_SDL2_FX_VOLUME;
         }
         log_info("-f option given. Set fx volume to %d.\n", sdl2_fx_volume);
         break;

      case 'n':
         log_info("-n option given. No autofire\n");
         setAutofire(false);
         break;

      case 'v':
         log_info("%s %s\n", GAME_NAME, GAME_VERSION);
         showVersion = true;
         break;

      case 'l':
#define NB_LEVELS 8
         log_info("-l option given. choosing level %s.\n", optarg);
         chooseLevel(atoi(optarg) % NB_LEVELS);
         break;

      case 'm':
         log_info("-m option given. SDL gamecontroller mapping file file: %s\n", optarg);
         if (SDL_GameControllerAddMappingsFromFile(optarg) == -1)
         {
            log_error("Warning: Failed to load game controller mappings");
         }
         break;

      case 'o':
         log_info("logging to file %s\n", optarg);
         logDebug = fopen(optarg, "w");
         break;

      case '1':
         log_info("-1 option given. Activate F1/F2 and L1/L2 pad key for debugging.\n");
         cheatMode = true;
         break;

      case '3':
         log_info("-3 option given. Set frame to %s.\n", optarg);
         setFrameNumber(atoi(optarg));
         break;

      case '4':
         log_info("-4 option given. Exit at frame %s.\n", optarg);
         exitAtFrameNumber = atoi(optarg);
         exitAtFrame = true;
         break;

      case 'a':
         log_info("-a option given. Test mode for %s AI players.\n", optarg);
         testAI = atoi(optarg);
         break;

      case 'c':
         setTeamMode(1);
         log_info("-c option given. Color team mode.\n");
         break;

      case 's':
         setTeamMode(2);
         log_info("-s option given. Sex team mode.\n");
         break;

      case 'k':
         setTeamMode(4);
         log_info("-k option given. Skynet team mode.\n");
         break;

      case '2':
         log_info("-2 option given. Slow motion for AI debugging.\n");
         slowMode = true;
         break;

      case 'z':
         music = false;
         break;

      case 'x':
         log_info("-x xBRZ shader factor to %s.\n", optarg);
         xbrzFactor = atoi(optarg);
         if (xbrzFactor < 1)
         {
            xbrzFactor = 1;
         }
         if (xbrzFactor > 6)
         {
            xbrzFactor = 6;
         }
         break;

      case 'd':
         joystickDeadZone = atoi(optarg);
         log_info("-d Joystick deadzone to %d.\n", joystickDeadZone);
         break;
      case 'e':
         log_info("-e Check Demo Mode.\n");
         checkDemoMode = true;
         // m.temps_avant_demo = 10;
         break;

      default:
         exit(1);
      }
   }
#if 0
   logDebug = fopen("/tmp/mrboom.log", "w");
#endif
   /* Enable standard application logging */
   SDL_LogSetPriority(SDL_LOG_CATEGORY_APPLICATION, SDL_LOG_PRIORITY_INFO);
   SDL_EventState(SDL_JOYAXISMOTION, SDL_ENABLE);
   SDL_EventState(SDL_JOYBALLMOTION, SDL_ENABLE);
   SDL_EventState(SDL_JOYHATMOTION, SDL_ENABLE);
   SDL_EventState(SDL_JOYBUTTONDOWN, SDL_ENABLE);
   SDL_EventState(SDL_JOYBUTTONUP, SDL_ENABLE);

   SDL_JoystickEventState(SDL_ENABLE);

   if ((exitAtFrame) && (exitAtFrameNumber == -1))
   {
      log_info("No VGA\n");
      noVGA = SDL_TRUE;
   }

   if ((noVGA == SDL_FALSE) && (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_GAMECONTROLLER) < 0))
   {
      log_error("Couldn't initialize SDL: %s\n", SDL_GetError());
      noVGA = SDL_TRUE;
      if (SDL_Init(SDL_INIT_GAMECONTROLLER) < 0)
      {
         log_error("Couldn't initialize SDL_INIT_GAMECONTROLLER: %s\n", SDL_GetError());
         return (1);
      }
   }

   if (!mrboom_init())
   {
      log_error("Error in init.\n");
      quit(1);
   }
   if (showVersion)
   {
      quit(0);
   }
   printKeys();

   /*
#ifdef DEBUG
#define RESIZABLE
#else
#define FULLSCREEN
#endif
*/
   if (noVGA == SDL_FALSE)
   {
      /* Create the window and renderer */
//#ifndef FULLSCREEN
if (!fullscreen) {
      window = SDL_CreateWindow(GAME_NAME,
                                SDL_WINDOWPOS_UNDEFINED,
                                SDL_WINDOWPOS_UNDEFINED,
                                WIDTH * 3, HEIGHT * 3,
                                SDL_WINDOW_RESIZABLE);
      windowID = SDL_GetWindowID(window);
/*
#else
      SDL_DisplayMode DM;
      SDL_GetCurrentDisplayMode(0, &DM);
      int displayWidth = DM.w;
      int displayHeight = DM.h;

      float aspectRatio = (float)displayWidth / (float)displayHeight;
      float height;
      float width;
      if (aspectRatio < ASPECT_RATIO)
      {
         width = displayWidth;
         height = (1.f / ASPECT_RATIO) * displayWidth;
      }
      else
      {
         width = ASPECT_RATIO * displayHeight;
         height = displayHeight;
      }

      window = SDL_CreateWindow(GAME_NAME,
                                SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                                width, height,
                                SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN);
#endif
*/
} else {
      // FULLSCREEN
      window = SDL_CreateWindow(GAME_NAME,
                                SDL_WINDOWPOS_CENTERED,
                                SDL_WINDOWPOS_CENTERED,
                                WIDTH, HEIGHT,
                                SDL_WINDOW_FULLSCREEN | SDL_WINDOW_SHOWN | SDL_WINDOW_BORDERLESS | SDL_WINDOW_INPUT_GRABBED);
      SDL_ShowCursor(SDL_DISABLE);
}

      if (!window)
      {
         log_error("Couldn't set create window: %s\n", SDL_GetError());
         quit(3);
      }
      SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "best");

      renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_PRESENTVSYNC);
      if (!renderer)
      {
         log_error("Couldn't set create renderer: %s\n", SDL_GetError());
         quit(4);
      }

      widthTexture = WIDTH * xbrzFactor;
      heightTexture = HEIGHT * xbrzFactor;
      texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, widthTexture, heightTexture);
      if (!texture)
      {
         log_error("Couldn't set create texture: %s\n", SDL_GetError());
         quit(5);
      }
   }

   /* Loop, waiting for QUIT or the escape key */

#ifdef __EMSCRIPTEN__
   emscripten_set_main_loop(loop, 0, 1);
#else
   begin = clock();
   while (!done)
   {
      if (resizeDone)
      {
         SDL_SetWindowSize(window, width, height);
         resizeDone = false;
      }
      loop();
#ifdef DEBUG
      fps();
      if (testAI)
      {
         manageTestAI();
      }
      if (slowMode)
      {
         usleep(100000);
      }
      if ((exitAtFrame) && (frameNumber() == exitAtFrameNumber))
      {
         log_info("Exit at frame\n");
         exit(0);
      }
      if ((exitAtFrame) && (exitAtFrameNumber == -1))
      {
         static bool first = false;
         if (isGameActive() == true)
         {
            first = true;
         }
         else
         {
            if (first)
            {
               log_info("Exit at frame\n");
               for (int i = 0; i < nb_dyna; i++)
               {
                  if (victories(i))
                  {
                     log_info("team %d won\n", teamOfPlayer(i));
                     exit(i);
                  }
               }
               log_info("draw game\n");
               exit(nb_dyna);
            }
         }
      }
#endif
   }
#endif

   if (noVGA == SDL_FALSE)
   {
      SDL_DestroyRenderer(renderer);
   }
   fps();
   log_debug("quit(0)\n");
   quit(0);
   return 0;
}
