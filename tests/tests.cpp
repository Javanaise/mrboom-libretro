// ./mrboom-test.out 1000 0 5
// convert -flop -rotate 180 tests/*.bmp mrboom.gif

#include "mrboom.h"
#include "common.hpp"
#include "retro.hpp"
#include "streams/file_stream.h"
#include "file/file_path.h"
#include "formats/rbmp.h"
#include <time.h>
#include <unistd.h>
#include "MrboomHelper.hpp"
#ifndef FPS
#include "xbrz.h"
#endif

#define NB_FRAME_PER_WINDOW    1000
#define NB_WINDOWS             10

char outputDir[256];
extern retro_log_printf_t log_cb;
static uint32_t *         frame_buf;

void testLogging(enum retro_log_level level, const char *fmt, ...)
{
#ifndef FALCON
   va_list args;
   char    buf[1000];

   va_start(args, fmt);
   vsnprintf(buf, sizeof(buf), fmt, args);
   va_end(args);
   printf("%s", buf);
#endif
}

static char data[SIZE_MEM_MAX];

int xbrzFactor = 2;

void saveState(int stateNumber)
{
#ifndef FPS
   char  savePath[PATH_MAX_LENGTH];
   FILE *file;

   path_mkdir("./tests/");
   path_mkdir("./tests/statetests");
   size_t size = retro_serialize_size();
   snprintf(savePath, sizeof(savePath), "./tests/%s/state%05d.mem", outputDir, stateNumber);

   file = fopen(savePath, "wb");
   if (file != NULL)
   {
      if (retro_serialize(data, size))
      {
         log_info("saving %s\n", savePath);
         fwrite(data, 1, size, file);
         snprintf(savePath, sizeof(savePath), "./tests/%s/state%05d.raw", outputDir, stateNumber);

         FILE *file2 = fopen(savePath, "wb");

         if (file2 != NULL)
         {
            fwrite(frame_buf, 1, HEIGHT * WIDTH * sizeof(uint32_t), file2);
            log_info("saved %s\n", savePath);
            fclose(file2);
         }

         static uint32_t *trg = NULL;
         if (trg == NULL)
         {
            trg = (uint32_t *)malloc(HEIGHT * xbrzFactor * WIDTH * xbrzFactor * sizeof(uint32_t));
         }
         scale(xbrzFactor,                //valid range: 2 - 6
               (uint32_t *)frame_buf, trg, WIDTH, HEIGHT,
               xbrz::ColorFormat::RGB);

         snprintf(savePath, sizeof(savePath), "./tests/%s/state%05d.bmp", outputDir, stateNumber);
         rbmp_save_image(savePath,
                         trg,
                         WIDTH * xbrzFactor, HEIGHT * xbrzFactor,
                         sizeof(*frame_buf) * WIDTH * xbrzFactor, RBMP_SOURCE_TYPE_XRGB888);
      }
      else
      {
         log_error("retro_serialize returned false\n");
      }
      fclose(file);
   }
   else
   {
      log_error("error filestream_open %s\n", savePath);
   }
#endif
}

void load_state(int stateNumber)
{
#ifndef FPS
   FILE * file;
   char   loadPath[PATH_MAX_LENGTH];
   size_t size = retro_serialize_size();

   snprintf(loadPath, sizeof(loadPath), "./tests/%s/state%05d.mem", outputDir, stateNumber);

   log_info("loading %s\n", loadPath);


   file = fopen(loadPath, "rb");

   if (file == NULL)
   {
      log_error("Error loading file %s\n", loadPath);
      return;
   }
   fread(data, 1, size, file);
   //hexDump (data, 100);

   if (retro_unserialize(data, size) != true)
   {
      log_error("retro_unserialize returned false\n");
      exit(1);
   }
   fclose(file);
#endif
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

int
main(int argc, char **argv)
{
   int i;

   printf("hello??!?\n");

   frame_buf = (uint32_t *)calloc(WIDTH * HEIGHT, sizeof(uint32_t));
   int nb_window           = NB_WINDOWS;
   int starting_window     = 0;
   int nb_frame_per_window = NB_FRAME_PER_WINDOW;
#ifdef __LIBRETRO__
#ifndef FALCON
   log_cb = testLogging;
#endif
#endif


#ifdef FPS
      strcpy(outputDir, "okokko");

nb_window =1;
starting_window =0;
nb_frame_per_window = 60*60*5;
#else

   if (argc < 2)
   {
      log_error("args: <outputDir> <nb windows> <starting window> <nb frame per window>\n");
      return(0);
   }
   if (argc >= 2)
   {
      strcpy(outputDir, argv[1]);
   }

   if (argc >= 3)
   {
      nb_window = atoi(argv[2]);
   }
   if (argc >= 4)
   {
      starting_window = atoi(argv[3]);
   }
   if (argc >= 5)
   {
      nb_frame_per_window = atoi(argv[4]);
   }
#endif

   mrboom_init();
   if (argc >= 6)
   {
      chooseLevel(atoi(argv[5]));
   }
   int nbFrames         = starting_window * nb_frame_per_window;
   int finishingFrameNb = nbFrames + nb_window * nb_frame_per_window;

   log_info("nb_window=%d starting_window=%d nb_frame_per_window=%d starting=%d finishing=%d\n", nb_window, starting_window, nb_frame_per_window, nbFrames, finishingFrameNb);

   int startingFrame = nbFrames;

   if (starting_window)
   {
      log_info("x loading at frame %d\n", nbFrames);
      load_state(starting_window - 1);
   }
   else
   {
   #ifdef SCREENSHOTS
      addXAIPlayers(6);
   #endif
   #ifdef STATETESTS
      addXAIPlayers(6);
   #endif
#ifndef FPS
      for (i = 0; i < 10; i++)
      {
         program();
      }
      pressStart();
#endif
   }
//	#ifdef SCREENSHOTS
//	pressStart();
//	#endif
   startClock(0);
   do
   {
      int stateNumber = nbFrames / nb_frame_per_window;
      m.CF        = 0;
      m.ZF        = 0;
      m.SF        = 0;
      m.DF        = 0;
      READDW(es)  = 2;
      READDW(cs)  = 0;
      READDW(ds)  = 0;
      READDW(fs)  = 1;
      READDW(gs)  = 0;
      READDD(eax) = 0;
      READDD(ebx) = 0;
      READDD(ecx) = 0;
      READDD(edx) = 0;
      READDD(esi) = 0;
      READDD(edi) = 0;
      READDD(ebp) = 0;
      READDD(esp) = 0;
      nbFrames++;
      program();
      mrboom_tick_ai();
#ifdef SCREENSHOTS
      if (isGameActive() == false)
      {
         log_info("exit screenshot");
         break;
      }
#endif
      startClock(1);
#ifndef FPS
      update_vga(frame_buf, WIDTH);
#endif
      stopClock(1);

   if (!(nbFrames % 60)) {

         printf("hello!!\n");

                  log_info("x time_spent=%f in updateVga=%f (%f)\n", totalTimeInClock(0), totalTimeInClock(1), totalTimeInClock(1) * 100 / totalTimeInClock(0));
                  log_info("x fps=%f saving at frame %d m=%d little=%d\n", (nbFrames - startingFrame) / totalTimeInClock(0), nbFrames,  replay(), is_little_endian());
   }

      if (!(nbFrames % nb_frame_per_window))
      {
         if (mrboom_debug_state_failed())
         {
            #ifndef FALCON
            log_error("Error mrboom_debug_state\n");
            char savePath[PATH_MAX_LENGTH];
            snprintf(savePath, sizeof(savePath), "./tests/%s/state%05d.mem", outputDir, stateNumber);
            unlink(savePath);
            #endif
         }
         else
         {
            log_info("x time_spent=%f in updateVga=%f (%f)\n", totalTimeInClock(0), totalTimeInClock(1), totalTimeInClock(1) * 100 / totalTimeInClock(0));
            log_info("x fps=%f saving at frame %d\n", (nbFrames - startingFrame) / totalTimeInClock(0), nbFrames);
            saveState(stateNumber);
         }
      }
   } while ((m.executionFinished == 0) && (nbFrames <= finishingFrameNb));
 #ifndef FPS
   unlink("./test.lock");
#endif
}
