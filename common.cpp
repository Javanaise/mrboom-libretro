// compile with make LOAD_FROM_FILES=1 DUMP=1
// to dump Wavs
#ifdef __LIBSDL__
#define NO_NETWORK
#endif

#ifdef _WIN32
#include <direct.h>
#else
#include <unistd.h>
#endif
#include <string.h>
#include <file/file_path.h>

#ifndef NO_NETWORK
extern "C"
{
#include <net/net_http.h>
#include <net/net_compat.h>
}
#endif

#include "mrboom.h"
#include "common.hpp"
#include "MrboomHelper.hpp"
#include "BotTree.hpp"
#include <string.h>
#include "images_patching_data.h"

#define NB_WAV 21
#define NB_VOICES 28
#define keyboardCodeOffset 32
#define keyboardReturnKey 28
#define keyboardExitKey 1
#define keyboardDataSize 8
#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define MAX(a, b) ((a) > (b) ? (a) : (b))
#define keyboardExtraSelectStartKeysSize 2
#define offsetExtraKeys keyboardDataSize *nb_dyna + keyboardCodeOffset

#pragma GCC diagnostic ignored "-Woverlength-strings"
#pragma GCC diagnostic ignored "-Warray-bounds"

#define NB_CHIPTUNES 11

#ifdef __LIBSDL__
#define UNZIP_DATA
#endif

#ifdef LOAD_FROM_FILES
#include <streams/file_stream.h>
#define UNZIP_DATA
#endif

#ifdef UNZIP_DATA
#include <minizip/unzip.h>
static char romPath[PATH_MAX_LENGTH];
static char dataPath[PATH_MAX_LENGTH];
static char extractPath[PATH_MAX_LENGTH];
#endif

#ifdef __LIBRETRO__
#include <audio/audio_mixer.h>
#include <audio/conversion/float_to_s16.h>
static float *fbuf = NULL;
static int16_t *ibuf = NULL;
static audio_mixer_sound_t *musics[NB_CHIPTUNES];
#ifndef LOAD_FROM_FILES
#include "retro_data.h"
#include "retro_music_data.h"
#endif

#include "retro.hpp"

#ifdef LOAD_FROM_FILES
#include <audio/audio_mix.h>
static audio_chunk_t *wave[NB_WAV];
#endif

static size_t frames_left[NB_WAV];

#ifndef INT16_MAX
#define INT16_MAX 0x7fff
#endif

#ifndef INT16_MIN
#define INT16_MIN (-INT16_MAX - 1)
#endif

#define CLAMP_I16(x) (x > INT16_MAX ? INT16_MAX : x < INT16_MIN ? INT16_MIN \
                                                                : x)
#endif

#ifndef PLATFORM
#define PLATFORM         "unknown"
#endif


bool music = true;
static int musics_index = 0;
#ifndef PADDING_FALCON
#define PADDING_FALCON 0
#endif
const char *musics_filenames[NB_CHIPTUNES + PADDING_FALCON] = {
    "DEADFEEL.XM",  // Carter (for menu + replay)
    "WTH6.MOD",     // parsec
    "CHIPTUNE.MOD", // 4-mat
    "MATKAMIE.MOD", // heatbeat
    "CHIPMUNK.MOD", // jester
    "UNREEEAL.XM",  // rez+kenet
    "ANAR11.MOD",   // 4-mat
    "EXTERNAL.XM",  // Quazar
    "ESTRAYK.MOD",  // Estrayk
    "HAPPY.XM",     // Ultrasyd
    "ASPARTAME.MOD" // Maf
};

#ifdef __LIBSDL2__
#include <SDL.h>
#include <SDL_mixer.h>
#endif

#ifdef __LIBSDL__
#include <SDL/SDL.h>
#include <SDL/SDL_mixer.h>
#endif

#if defined(__LIBSDL2__) || defined(__LIBSDL__)

int sdl2_fx_volume = DEFAULT_SDL2_FX_VOLUME;

static Mix_Chunk *wave[NB_WAV];
static Mix_Music *musics[NB_CHIPTUNES];

#define DEFAULT_VOLUME MIX_MAX_VOLUME / 2
#define MATKAMIE_VOLUME MIX_MAX_VOLUME
#define LOWER_VOLUME MIX_MAX_VOLUME / 3

const int musics_volume[NB_CHIPTUNES] = {
    DEFAULT_VOLUME,
    MIX_MAX_VOLUME,
    DEFAULT_VOLUME,
    MATKAMIE_VOLUME,
    LOWER_VOLUME,
    DEFAULT_VOLUME,
    LOWER_VOLUME,
    DEFAULT_VOLUME,
    LOWER_VOLUME,
    DEFAULT_VOLUME,
    MIX_MAX_VOLUME};
#endif

#ifdef UNZIP_DATA
#ifdef __LIBSDL__
#include "sdl/sdl_data.h"
#else
#include "sdl2/sdl2_data.h"
#endif
#endif

static int ignoreForAbit[NB_WAV];
static int ignoreForAbitFlag[NB_WAV];
int traceMask = DEFAULT_TRACE_MAX;
static bool pic_timeExit = false; // hack in case input is too early in the intro pic

#ifdef __LIBRETRO__
#include <libretro.h>
int16_t *frame_sample_buf;
uint32_t num_samples_per_frame;
retro_audio_sample_batch_t audio_batch_cb;
#endif

bool audio = true;
bool cheatMode = false;
static bool fxTraces = false;
BotTree *tree[nb_dyna];

#ifdef DEBUG
int walkingToCell[nb_dyna];
#endif

#ifdef UNZIP_DATA
int rom_unzip(const char *path, const char *extraction_directory)
{
#ifndef __LIBSDL__
   path_mkdir(extraction_directory);
#endif
   unzFile *zipfile = (unzFile *)unzOpen(path);
   if (zipfile == NULL)
   {
      log_error("<%s> not found\n", path);
      return (-1);
   }
   unz_global_info global_info;
   if (unzGetGlobalInfo(zipfile, &global_info) != UNZ_OK)
   {
      log_error("could not read file global info\n");
      unzClose(zipfile);
      return (-1);
   }

   char read_buffer[8192];

   uLong i;
   for (i = 0; i < global_info.number_entry; ++i)
   {
      unz_file_info file_info;
      char filename[PATH_MAX_LENGTH];
      if (unzGetCurrentFileInfo(zipfile, &file_info, filename, PATH_MAX_LENGTH,
                                NULL, 0, NULL, 0) != UNZ_OK)
      {
         log_error("could not read file info\n");
         unzClose(zipfile);
         return (-1);
      }

      const size_t filename_length = strlen(filename);
#ifndef __LIBSDL__
      if (filename[filename_length - 1] == '/')
      {
         log_debug("dir:%s\n", filename);
         char abs_path[PATH_MAX_LENGTH];
         fill_pathname_join(abs_path,
                            extraction_directory, filename, sizeof(abs_path));
         path_mkdir(abs_path);
      }
      else
#endif
      {
         log_debug("file:%s\n", filename);
         if (unzOpenCurrentFile(zipfile) != UNZ_OK)
         {
            log_error("could not open file\n");
            unzClose(zipfile);
            return (-1);
         }
#ifndef __LIBSDL__
         char abs_path[PATH_MAX_LENGTH];
         fill_pathname_join(abs_path,
                            extraction_directory, filename, sizeof(abs_path));
         FILE *out = fopen(abs_path, "wb");
#else
         FILE *out = fopen(filename, "wb");
#endif
         if (out == NULL)
         {
            log_error("could not open destination file\n");
            unzCloseCurrentFile(zipfile);
            unzClose(zipfile);
            return (-1);
         }

         int error = UNZ_OK;
         do
         {
            error = unzReadCurrentFile(zipfile, read_buffer, 8192);
            if (error < 0)
            {
               log_error("error %d\n", error);
               unzCloseCurrentFile(zipfile);
               unzClose(zipfile);
               return (-1);
            }

            if (error > 0)
            {
               fwrite(read_buffer, error, 1, out);
            }
         } while (error > 0);

         fclose(out);
      }

      unzCloseCurrentFile(zipfile);

      if (i + 1 < global_info.number_entry)
      {
         if (unzGoToNextFile(zipfile) != UNZ_OK)
         {
            log_error("cound not read next file\n");
            unzClose(zipfile);
            return (-1);
         }
      }
   }
   unzClose(zipfile);
#ifndef __LIBSDL__
   unlink(path);
#endif
   return (0);
}

#endif

bool mrboom_debug_state_failed()
{
   static db *saveState = NULL;
   unsigned int i = 0;
   bool failed = false;

   if (saveState == NULL)
   {
      saveState = (uint8_t *)calloc(SIZE_RO_SEGMENT, 1);
      memcpy(saveState, &m.FIRST_RO_VARIABLE, SIZE_RO_SEGMENT);
   }
   else
   {
      db *currentMem = &m.FIRST_RO_VARIABLE;
      for (i = 0; i < SIZE_RO_SEGMENT; i++)
      {
         if (saveState[i] != currentMem[i])
         {
            log_error("RO variable changed at %x\n", i + (unsigned int)offsetof(struct Mem, FIRST_RO_VARIABLE));
            memcpy(saveState, &m.FIRST_RO_VARIABLE, SIZE_RO_SEGMENT);
            failed = true;
         }
      }
   }
   return (failed);
}

#ifndef LOAD_FROM_FILES
static unsigned short crc16(const unsigned char *data_p, int length)
{
   unsigned char x;
   unsigned short crc = 0xFFFF;

   while (length--)
   {
      x = crc >> 8 ^ *data_p++;
      x ^= x >> 4;
      crc = (crc << 8) ^ ((unsigned short)(x << 12)) ^ ((unsigned short)(x << 5)) ^ ((unsigned short)x);
   }
   return (crc);
}
#endif

#ifdef DUMP_HEAP
void dump_heap()
{
   FILE *file;
   char path[PATH_MAX_LENGTH];
   sprintf(path, "/tmp/mrboom.heap");
   printf("fopen %s\n", path);
   file = fopen(path, "w");
   fprintf(file, "#ifndef LOAD_FROM_FILES\n{\n");
   int bytesDumped = 0;
   while (bytesDumped < HEAP_SIZE)
   {
      if (bytesDumped % 16 == 0)
      {
         fprintf(file, "   ");
      }
      fprintf(file, "0x%02X,", m.heap[bytesDumped]);
      bytesDumped++;
      if (bytesDumped % 16 == 0)
      {
         fprintf(file, "\n");
      }
   }
   fprintf(file, "},\n#else\n{0},\n#endif\n");
   fclose(file);
}
#endif

#ifdef DUMP_GFX
void write_gfx(char *name, int addr)
{
   FILE *fp = fopen(name, "wb");
   fwrite(m.heap + addr, 320 * 200, 1, fp);
   fclose(fp);
}

void dump_gfx()
{
   write_gfx("/tmp/game1.pic", 0x000000);
   // fa00 = blank
   write_gfx("/tmp/game2.pic", 0x01f400);
   write_gfx("/tmp/game3.pic", 0x02ee00);
   write_gfx("/tmp/menu.pic", 0x03e800);
   write_gfx("/tmp/draw.pic", 0x04e200);
   write_gfx("/tmp/draw2.pic", 0x05dc00);
   write_gfx("/tmp/med.pic", 0x06d600);
   write_gfx("/tmp/med3.pic", 0x07d000);
   write_gfx("/tmp/sprite.pic", 0x08ca00);
   write_gfx("/tmp/sprite3.pic", 0x09c400);
   write_gfx("/tmp/vic1.pic", 0x0abe00);
   write_gfx("/tmp/vic2.pic", 0x0bb800);
   write_gfx("/tmp/vic3.pic", 0x0cb200);
   write_gfx("/tmp/vic4.pic", 0x0dac00);
   write_gfx("/tmp/pic.pic", 0x0ea600);
   write_gfx("/tmp/neige2.pic", 0x0fa000);
   write_gfx("/tmp/neige1.pic", 0x109a00);
   // 119400 = blank
   write_gfx("/tmp/micro.pic", 0x124800);
   write_gfx("/tmp/nuage1.pic", 0x134200);
   write_gfx("/tmp/nuage2.pic", 0x143c00);
   write_gfx("/tmp/foret.pic", 0x153600);
   write_gfx("/tmp/feuille.pic", 0x163000);
   write_gfx("/tmp/neige3.pic", 0x172a00);
   write_gfx("/tmp/pause.pic", 0x182400);
   write_gfx("/tmp/medc.pic", 0x191e00);
   write_gfx("/tmp/medg.pic", 0x1a1800);
   write_gfx("/tmp/crayon.pic", 0x1b1200);
   write_gfx("/tmp/crayon2.pic", 0x1c0c00);
   write_gfx("/tmp/sprite2.pic", 0x1d0600);
   // 1e0000 = blank
   write_gfx("/tmp/neige1.mrb", 0x1efa00);
   write_gfx("/tmp/micro1.mrb", 0x1ff400);
   write_gfx("/tmp/jungle1.mrb", 0x20ee00);
   write_gfx("/tmp/rose1.mrb", 0x21e800);
   write_gfx("/tmp/fete1.mrb", 0x22e200);
   write_gfx("/tmp/nuage1.mrb", 0x23dc00);
   write_gfx("/tmp/lapin1.pic", 0x24d600);
   write_gfx("/tmp/mort.pic", 0x25d000);
   write_gfx("/tmp/lapin2.pic", 0x26ca00);
   write_gfx("/tmp/lapin3.pic", 0x27c400);
   write_gfx("/tmp/lapin4.pic", 0x28be00);
   write_gfx("/tmp/foot.pic", 0x29b800);
   write_gfx("/tmp/foot1.mrb", 0x2ab200);
   write_gfx("/tmp/foot2.mrb", 0x2bac00);
   write_gfx("/tmp/fete2.mrb", 0x2ca600);
   write_gfx("/tmp/neige2.mrb", 0x2da000);
   write_gfx("/tmp/rose2.pic", 0x2e9a00);
   write_gfx("/tmp/jungle2.mrb", 0x2f9400);
   write_gfx("/tmp/micro2.mrb", 0x308e00);
   write_gfx("/tmp/nuage2.mrb", 0x318800);
   write_gfx("/tmp/mrfond.pic", 0x328200);
   write_gfx("/tmp/soucoupe.pic", 0x337c00);
   write_gfx("/tmp/soccer.pic", 0x347600);
   write_gfx("/tmp/footanim.pic", 0x357000);
   write_gfx("/tmp/lune1.mrb", 0x366a00);
   write_gfx("/tmp/lune2.mrb", 0x376400);
   // 385e00 = blank
}
#endif

bool mrboom_load()
{
#ifdef FALCON
   audio = 1;
   music = false;
#endif

#ifdef UNZIP_DATA
   char tmpDir[PATH_MAX_LENGTH];
#ifndef __LIBSDL__
   snprintf(tmpDir, sizeof(tmpDir), "%s", "/tmp");
#ifndef __APPLE__
   if (getenv("HOME") != NULL)
   {
      snprintf(tmpDir, sizeof(tmpDir), "%s", getenv("HOME"));
   }
#endif
   if (getenv("TMP") != NULL)
   {
      snprintf(tmpDir, sizeof(tmpDir), "%s", getenv("TMP"));
   }
   if (getenv("TEMP") != NULL)
   {
      snprintf(tmpDir, sizeof(tmpDir), "%s", getenv("TEMP"));
   }
   snprintf(romPath, sizeof(romPath), "%s/mrboom.rom", tmpDir);
   snprintf(extractPath, sizeof(extractPath), "%s/mrboom", tmpDir);

   // log_debug("romPath: %s\n", romPath);
   if (filestream_write_file(romPath, dataRom, sizeof(dataRom)) == false)
   {
      log_error("Error writing %s\n", romPath);
      return (false);
   }
#else
   sprintf(romPath, "C:\\ROM.DAT");
   sprintf(extractPath, "");
   FILE *fp;
   fp = fopen(romPath, "wb");
   fwrite(dataRom, 1, sizeof(dataRom), fp);
   fclose(fp);
#endif
   log_debug("romPath: %s\n", romPath);
   log_debug("extractPath: %s\n", extractPath);
   rom_unzip(romPath, extractPath);
   unlink(romPath);
#ifdef LOAD_FROM_FILES
   m.path = strdup(extractPath);
#endif
   char filePath[PATH_MAX_LENGTH];
#endif
   for (int i = 0; i < NB_WAV; i++)
   {
#ifdef UNZIP_DATA
#ifdef __LIBSDL__
      snprintf(filePath, sizeof(filePath), "%d.WAV", i);
#else
      snprintf(filePath, sizeof(filePath), "%s/%d.WAV", extractPath, i);
#endif
#ifdef __LIBRETRO__
      wave[i] = audio_mix_load_wav_file(&filePath[0], SAMPLE_RATE);
#endif

#if defined __LIBSDL2__ || defined(__LIBSDL__)
      if (audio)
      {
         wave[i] = Mix_LoadWAV(filePath);
         if (wave[i] == NULL)
         {
            log_error("Couldn't load %s\n", filePath);
            // TOFIX exit(1);
         }
         else
         {
            Mix_VolumeChunk(wave[i], MIX_MAX_VOLUME * sdl2_fx_volume / 10);
         }
         if (wave[i] == NULL)
         {
            log_error("cant load %s\n", filePath);
         }
      }
      unlink(filePath);
#endif
#endif
      ignoreForAbit[i] = 0;
      ignoreForAbitFlag[i] = 5;
   }
#if defined(__LIBSDL2__) || defined(__LIBSDL__)
   for (int i = 0; i < NB_CHIPTUNES; i++)
   {
#ifdef __LIBSDL__
      snprintf(filePath, sizeof(filePath), "%s", musics_filenames[i]);
#else
      snprintf(filePath, sizeof(filePath), "%s/%s", extractPath, musics_filenames[i]);
#endif
      if (audio)
      {
         musics[i] = Mix_LoadMUS(filePath);
         if (!musics[i])
         {
            log_error("Mix_LoadMUS(\"%s\"): %s: please check SDL2_mixer is compiled --with-libmodplug\n", musics_filenames[i], Mix_GetError());
            // return(false);
         }
      }
      unlink(filePath);
   }
#endif
#ifdef __LIBRETRO__
#ifdef LOAD_FROM_FILES
   for (int i = 0; i < NB_CHIPTUNES; i++)
   {
      sprintf(filePath, "%s/%s", extractPath, musics_filenames[i]);
      int64_t len = 0;
      void *buf = NULL;
      if (!filestream_read_file(filePath, &buf, &len))
      {
         log_error("Could not load %s\n", filePath);
         musics[i] = NULL;
      }
      else
      {
         musics[i] = audio_mixer_load_mod(buf, len);
      }
   }
#else
   musics[0] = audio_mixer_load_mod(SOUND_DEADFEEL_XM, SOUND_DEADFEEL_XM_len);
   musics[1] = audio_mixer_load_mod(SOUND_WTH6_MOD, SOUND_WTH6_MOD_len);
   musics[2] = audio_mixer_load_mod(SOUND_CHIPTUNE_MOD, SOUND_CHIPTUNE_MOD_len);
   musics[3] = audio_mixer_load_mod(SOUND_MATKAMIE_MOD, SOUND_MATKAMIE_MOD_len);
   musics[4] = audio_mixer_load_mod(SOUND_CHIPMUNK_MOD, SOUND_CHIPMUNK_MOD_len);
   musics[5] = audio_mixer_load_mod(SOUND_UNREEEAL_XM, SOUND_UNREEEAL_XM_len);
   musics[6] = audio_mixer_load_mod(SOUND_ANAR11_MOD, SOUND_ANAR11_MOD_len);
   musics[7] = audio_mixer_load_mod(SOUND_EXTERNAL_XM, SOUND_EXTERNAL_XM_len);
   musics[8] = audio_mixer_load_mod(SOUND_ESTRAYK_MOD, SOUND_ESTRAYK_MOD_len);
   musics[9] = audio_mixer_load_mod(SOUND_HAPPY_XM, SOUND_HAPPY_XM_len);
#endif
#endif

   return (true);
}

bool mrboom_init()
{
   asm2C_init();
   //
   if (m.isLittle)
   {
      m.isbigendian = 0;
   }
   else
   {
      m.isbigendian = 1;
   }
   m.differentesply2 = 4; // sky is for the first demo

   strcpy((char *)&m.iff_file_name, "mrboom.dat");
   m.taille_exe_gonfle = 0;
#ifdef __LIBRETRO__
   fbuf = (float *)malloc(num_samples_per_frame * 2 * sizeof(float));
   ibuf = (int16_t *)malloc(num_samples_per_frame * 2 * sizeof(int16_t));
#endif
#ifdef __LIBSDL2__
   /* Initialize SDL. */
   if (SDL_Init(SDL_INIT_AUDIO) < 0)
   {
      log_error("Error SDL_Init\n");
   }

   /* Initialize SDL_mixer */
   if (Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 512) == -1)
   {
      log_error("Error Mix_OpenAudio\n");
      audio = false;
   }
#endif
   m.tected[20] = GAME_VERSION[0];
   m.tected[21] = GAME_VERSION[1];
   m.tected[22] = GAME_VERSION[2];

#ifndef LOAD_FROM_FILES
   m.dataloaded = 1;
   log_debug("Mrboom: Crc16 heap: %d\n", crc16(m.heap, HEAP_SIZE));
#else
   m.dataloaded = 0;
#endif

#ifndef FALCON
   mrboom_load();
#endif

   ignoreForAbitFlag[0] = 30;
   ignoreForAbitFlag[10] = 30; // Kangaroo jump
   ignoreForAbitFlag[13] = 30;
   ignoreForAbitFlag[14] = 30;

   for (int i = 0; i < keyboardDataSize * nb_dyna; i++)
   {
      if (!((i + 1) % keyboardDataSize))
      {
         m.touches_[i] = -1;
      }
      else
      {
         m.touches_[i] = i + keyboardCodeOffset;
      }
   }
   program();

#ifdef DUMP_HEAP
   dump_heap();
#endif

#ifdef DUMP_GFX
   dump_gfx();
#endif

   m.nosetjmp = 1; // will go to menu, except if state loaded after

#ifdef LOAD_FROM_FILES
   snprintf(dataPath, sizeof(dataPath), "%s/mrboom.dat", extractPath);
   log_debug("dataPath = %s \n", dataPath);
   unlink(dataPath);
   log_debug("extractPath = %s \n", extractPath);
   rmdir(extractPath);
#endif

#ifdef DEBUG
   asm2C_printOffsets(offsetof(struct Mem, FIRST_RW_VARIABLE));
#endif
   for (int i = 0; i < nb_dyna; i++)
   {
      tree[i] = new BotTree(i);
   }

#ifndef NO_NETWORK
   network_init();
#endif
   return (true);
}

void mrboom_deinit()
{
#ifdef __LIBRETRO__
   for (int i = 0; i < NB_CHIPTUNES; i++)
   {
#ifdef LOAD_FROM_FILES
      audio_mixer_destroy(musics[i]);
#else
      free(musics[i]);
#endif
   }
#endif
#ifdef LOAD_FROM_FILES
   /* free WAV */
   for (int i = 0; i < NB_WAV; i++)
   {
#ifdef __LIBRETRO__
      audio_mix_free_chunk(wave[i]);
#endif
#ifdef __LIBSDL2__
      Mix_FreeChunk(wave[i]);
#endif
   }
#endif
#ifdef __LIBRETRO__
   free(fbuf);
   free(ibuf);
   audio_mixer_done();
#endif
}

static void mrboom_api()
{
#ifndef NO_NETWORK
   static struct http_connection_t *conn = NULL;
   static struct http_t *http = NULL;
   static int api_state = 0;
   static int say_hello = 1;

   if ((!say_hello) && (!api_state))
   {
      return;
   }
   switch (api_state)
   {
   case 0:
   {
      char body[1024];
#ifdef __LIBRETRO__
      sprintf(body, "{\n\"platform\":\"");
#else 
      snprintf(body, sizeof(body), "{\n\"platform\":\"");
#endif      
      strcat(body,  PLATFORM);
#ifdef __LIBSDL2__
      strcat(body, "\",\n\"version\":\"SDL2 ");
#else
      strcat(body, "\",\n\"version\":\"libretro ");
#endif
      strcat(body, GAME_VERSION);
      strcat(body, GIT_VERSION);
      strcat(body, "\"\n}\n");

      log_debug("body:%s\n",body);
      api_state = 1;
      say_hello = 0;
#ifdef DEBUG
      conn = net_http_connection_new("http://localhost:4004/hello", "POST", body);
#else 
      conn = net_http_connection_new("http://api.mumblecore.org/hello", "POST", body);
#endif
      break;
   }
   case 1:
      if (net_http_connection_iterate(conn))
      {
         if (net_http_connection_done(conn))
         {
            api_state = 2;
            http = net_http_new(conn);
         }
         else
         {
            net_http_connection_free(conn);
            conn = NULL;
            api_state = 0;
         }
      }
      break;

   case 2:
      if (net_http_update(http, NULL, NULL))
      {
         net_http_connection_free(conn);
         conn = NULL;
         net_http_delete(http);
         http = NULL;
         api_state = 0;
      }
      break;
   }
#endif
}

#if defined __LIBSDL2__ || __LIBSDL__
#define play(b) Mix_PlayChannel(-1, wave[b], 0)
#else
#ifdef LOAD_FROM_FILES
#define play(b)                                                  \
   if (wave[b] != NULL)                                          \
   {                                                             \
      frames_left[b] = audio_mix_get_chunk_num_samples(wave[b]); \
   }
#else
#define play(b)                             \
   if (wave[b].samples != NULL)             \
   {                                        \
      frames_left[b] = wave[b].num_samples; \
   }
#endif
#endif

#define fxSound(a, b)                   \
   static bool a##b = false;            \
   if (a() && !a##b)                    \
   {                                    \
      a##b = true;                      \
      play(b);                          \
      if (fxTraces)                     \
      {                                 \
         log_debug("fxSound " #a "\n"); \
      }                                 \
   }                                    \
   a##b = a();

void mrboom_sound(void)
{
   if (!audio)
   {
      return;
   }
   fxSound(isDrawGame, 16)
       fxSound(won, 17)
           fxSound(isApocalypseSoon, 18)
               fxSound(isGamePaused, 19)
                   fxSound(isGameUnPaused, 5)
                       fxSound(playerGotDisease, 20)

#ifdef __LIBRETRO__
                           static audio_mixer_voice_t *voice = NULL;
   static bool mixer_init = false;

   if (mixer_init == false)
   {
      audio_mixer_init(SAMPLE_RATE);
      mixer_init = true;
   }
#endif

   static int last_voice = 0;
   for (int i = 0; i < NB_WAV; i++)
   {
      if (ignoreForAbit[i])
      {
         ignoreForAbit[i]--;
      }
   }

#ifdef DUMP
   static bool play_once = true;
   if (play_once)
   {
      play(16);
      play(17);
      play(18);
      play(20);
      play_once = false;
   }
#endif

   while (m.last_voice != (unsigned)last_voice)
   {
      db a = *(((db *)&m.blow_what2[last_voice / 2]));
      db a1 = a & 0xf;
      if (fxTraces)
      {
         log_debug("blow what: sample = %d / panning %d, note: %d ignoreForAbit[%d]\n", a1, (db)a >> 4, (db)(*(((db *)&m.blow_what2[last_voice / 2]) + 1)), ignoreForAbit[a1]);
      }
      last_voice = (last_voice + 2) % NB_VOICES;
#if defined LOAD_FROM_FILES
      if ((a1 >= 0) && (a1 < NB_WAV) && (wave[a1] != NULL))
#else
      if ((a1 >= 0) && (a1 < NB_WAV) && (wave[a1].samples != NULL))
#endif
      {
         bool dontPlay = 0;

         if (ignoreForAbit[a1])
         {
            if (fxTraces)
            {
               log_debug("Ignore sample id %d\n", a1);
            }
            dontPlay = 1;
         }
         if (dontPlay == 0)
         {
#ifdef __LIBRETRO__
#ifdef LOAD_FROM_FILES
            frames_left[a1] = audio_mix_get_chunk_num_samples(wave[a1]);
#else
            frames_left[a1] = wave[a1].num_samples;
#endif
#endif
#if defined __LIBSDL2__ || __LIBSDL__
            if (Mix_PlayChannel(-1, wave[a1], 0) == -1)
            {
               if (fxTraces)
               {
                  log_error("Error playing sample id %d.<%s> Mix_AllocateChannels=%d\n", a1, Mix_GetError(), Mix_AllocateChannels(-1));
               }
            }
#endif
            ignoreForAbit[a1] = ignoreForAbitFlag[a1];
         }
      }
      else
      {
         log_error("Wrong sample id %d or NULL.\n", a1);
      }
   }
   if (music)
   {
      static int currentLevel = -2;
#ifdef __LIBRETRO__
      if (voice)
      {
         audio_mixer_voice_set_volume(voice, libretro_music_volume);
      }
#endif
      if (level() != currentLevel)
      {
         int index = 0; // default menu song
         currentLevel = level();
         if (currentLevel == -1)
         {
            if (isXmasPeriod())
            {
               index = 1;
            }
         }
         else
         {
            musics_index = (musics_index + 1) % (NB_CHIPTUNES);
            if (musics_index < 2)
            {
               musics_index = 2;
            }
            index = musics_index;
         }
#if defined __LIBSDL2__ || __LIBSDL__
         Mix_VolumeMusic(musics_volume[index]);
         log_debug("Playing %s volume:%d\n", musics_filenames[index], Mix_VolumeMusic(-1));
         if (Mix_PlayMusic(musics[index], -1) == -1)
         {
            log_error("error playing music %d\n", musics[0]);
         }
#else
         if (voice)
         {
            audio_mixer_stop(voice);
         }
         voice = audio_mixer_play(musics[index], true, libretro_music_volume, NULL, RESAMPLER_QUALITY_DONTCARE, NULL);
#endif
      }
   }
}

#ifdef __LIBRETRO__
void stop_cb(audio_mixer_sound_t *sound, unsigned reason)
{
}

#endif

void mrboom_reset_special_keys()
{
   db *keys = m.total_t;

   for (int i = 0; i < nb_dyna; i++)
   {
      int pointeurSelect = 64 + 5 + i * 7;
      *(keys + pointeurSelect) = 0;
   }
   *(keys + 8 * 7) = 0;
   *(keys + 8 * 7 + 1) = 0;
   *(keys + 8 * 7 + 2) = 0; // une_touche_a_telle_ete_pressee
   if ((pic_timeExit) && (m.pic_time))
   {
      *(keys + 8 * 7 + 2) = 1;
   }
}

#ifdef __LIBSDL__
int lastDirection[nb_dyna];

void mrboom_autopilot_1_button_joysticks(int player)
{
   int input = getInputForPlayer(player);

   int x = xPlayer(player);
   int addX = 0;
   int y = yPlayer(player);
   int addY = 0;

   mrboom_update_input(button_x, input, 0, false); // also jump 1st player

   if (isInMiddleOfCell(player))
   {
      switch (lastDirection[input])
      {
      case button_down:
         addY = 1;
         if (y >= grid_size_y - 2)
         {
            addY = 0;
         }
         break;

      case button_right:
         addX = 1;
         break;

      case button_left:
         addX = -1;
         break;

      case button_up:
         addY = -1;
         if (y < 2)
         {
            addY = 0;
         }
         break;

      default:
         break;
      }
      if ((addX != 0) || (addY != 0))
      {
         x += addX;
         y += addY;
         if (brickOrSkullBonus(x, y))
         {
            x += addX;
            y += addY;
            if (!brickOrSkullBonus(x, y))
            {
               mrboom_update_input(button_x, input, 1, false); // also jump 1st player
            }
         }
      }
   }
}

#endif

void mrboom_update_input(int keyid, int playerNumber, int state, bool isIA)
{
   static int selectPressed = 0;
   static int selectPressedPlayerNumber = 0;

#ifdef __LIBRETRO__
   static int startPressed = 0;
#endif

   db *keys = m.total_t;
   if (isIA)
   {
      keys += 64;
   }

   switch (keyid)
   {
   case button_down:
#ifdef __LIBSDL__
      if (state)
      {
         lastDirection[playerNumber] = button_down;
      }
#endif
      *(keys + 3 + playerNumber * 7) = state;
      break;

   case button_right:
#ifdef __LIBSDL__
      if (state)
      {
         lastDirection[playerNumber] = button_right;
      }
#endif
      *(keys + 1 + playerNumber * 7) = state;
      break;

   case button_left:
#ifdef __LIBSDL__
      if (state)
      {
         lastDirection[playerNumber] = button_left;
      }
#endif
      *(keys + 2 + playerNumber * 7) = state;
      break;

   case button_up:
#ifdef __LIBSDL__
      if (state)
      {
         lastDirection[playerNumber] = button_up;
      }
#endif
      *(keys + playerNumber * 7) = state;
      break;

   case button_a:
      *(keys + 5 + playerNumber * 7) = state;
      break;

   case button_select:
      if (selectPressed != 1)
      {
         if (state)
         {
            addOneAIPlayer();
         }
         selectPressedPlayerNumber = playerNumber;
      }
      if (selectPressedPlayerNumber == playerNumber)
      {
         selectPressed = state;
      }
      break;

   case button_start:
      if (state)
      {
         *(keys + 8 * 7) = state;
      }
#ifdef __LIBRETRO__
      startPressed = state;
#endif
      break;

   case button_b:
      *(keys + 4 + playerNumber * 7) = state;
      break;

   case button_x:
      *(keys + 6 + playerNumber * 7) = state;
      break;

   case button_l:
      *(keys + 6 + playerNumber * 7) = state; // X
      if (cheatMode)
      {
         if (state)
         {
            activeCheatMode();
         }
      }
      break;

   case button_r:
      *(keys + 5 + playerNumber * 7) = state; // A
      if (cheatMode)
      {
         if (state)
         {
            activeApocalypse();
         }
      }
      break;
   }

   if (state)
   {
      *(keys + 8 * 7 + 2) = 1; // une_touche_a_telle_ete_pressee
      if (m.pic_time)
      {
         pic_timeExit = true;
      }
   }

#ifdef __LIBRETRO__
   if (startPressed && selectPressed)
   {
      pressESC();
      if (inTheMenu())
      {
         m.executionFinished = true;
      }
   }

#endif
}

#ifdef __LIBRETRO__

void audio_callback(void)
{
   unsigned i;

#ifdef DUMP
   static bool dump = true;
   static bool dumped[NB_WAV];

   if (dump)
   {
      for (i = 0; i < NB_WAV; i++)
      {
         dumped[i] = true;
      }
      dump = false;
   }
#endif

   if (!audio_batch_cb)
   {
      return;
   }

   memset(frame_sample_buf, 0, num_samples_per_frame * 2 * sizeof(int16_t));

   for (i = 0; i < NB_WAV; i++)
   {
      if (frames_left[i])
      {
         unsigned j;
         unsigned frames_to_copy = 0;
#ifdef LOAD_FROM_FILES
         int16_t *samples = audio_mix_get_chunk_samples(wave[i]);
         unsigned num_frames = audio_mix_get_chunk_num_samples(wave[i]);
#ifdef DUMP
         FILE *file;
         if (dumped[i])
         {
            char path[PATH_MAX_LENGTH];
            sprintf(path, "/tmp/audio-%d.c", i);
            printf("fopen %s\n", path);
            file = fopen(path, "w");
            fprintf(file, "static const uint32_t wav%d_data [%u] = {\n", i, num_frames);
            int nbIntsDumped = 0;
            while (nbIntsDumped < num_frames * 2)
            {
               if (nbIntsDumped % 16 == 0)
               {
                  fprintf(fp, "   ");
               }
               fprintf(fp, "0x%04X%04X, ", samples[nbIntsDumped + 1] & 0xffff, samples[nbIntsDumped + 0] & 0xffff);
               nbIntsDumped++;
               nbIntsDumped++;
               if (nbIntsDumped % 16 == 0)
               {
                  fprintf(file, "\n");
               }
            }
            fprintf(file, "\n};\n");
            fclose(file);
            dumped[i] = false;
         }
#endif
#else
         const int16_t *samples = wave[i].samples;
         unsigned num_frames = wave[i].num_samples;
#endif
         frames_to_copy = MIN(frames_left[i], num_samples_per_frame);

         for (j = 0; j < frames_to_copy; j++)
         {
            unsigned chunk_size = num_frames * 2;
            unsigned sample = frames_left[i] * 2;
            frame_sample_buf[j * 2] = CLAMP_I16(frame_sample_buf[j * 2] + (samples[chunk_size - sample] * libretro_sfx_volume / 100));
            frame_sample_buf[(j * 2) + 1] = CLAMP_I16(frame_sample_buf[(j * 2) + 1] + (samples[(chunk_size - sample) + 1] * libretro_sfx_volume / 100));
            frames_left[i]--;
         }
      }
   }

   memset(fbuf, 0, num_samples_per_frame * 2 * sizeof(float));
   audio_mixer_mix(fbuf, num_samples_per_frame, 1, false);
   convert_float_to_s16(ibuf, fbuf, num_samples_per_frame * 2);

   for (i = 0; i < num_samples_per_frame; i++)
   {
      frame_sample_buf[i * 2] = CLAMP_I16(frame_sample_buf[i * 2] + ibuf[i * 2]);
      frame_sample_buf[(i * 2) + 1] = CLAMP_I16(frame_sample_buf[(i * 2) + 1] + ibuf[(i * 2) + 1]);
   }

   i = 0;
   while (i < num_samples_per_frame)
   {
      i += audio_batch_cb(frame_sample_buf + (i * 2), num_samples_per_frame - i);
   }
}

#endif

void mrboom_deal_with_autofire()
{
   if (autofire() == false)
   {
      if (isGameActive())
      {
         for (int i = 0; i < numberOfPlayers(); i++)
         {
            if (isAIActiveForPlayer(i) == false)
            {
               if (bombInCell(xPlayer(i), yPlayer(i)))
               {
                  log_debug("autofire p:%d i:%d ", i, getInputForPlayer(i));
                  mrboom_update_input(button_b, getInputForPlayer(i), 0, false);
               }
            }
         }
      }
   }
}

#ifdef DEBUG
BotState botStates[nb_dyna];
#endif

static void mrboom_deal_with_skynet_team_mode()
{
   if (!replay() && teamMode() == 4)
   {
      static bool active = false;
      if ((!active) && isGameActive())
      {
         int nbHumans = 0;
         int nbRobots = 0;
         for (int i = 0; i < nb_dyna; i++)
         {
            m.team[i] = 0;
         }
         for (int i = 0; i < numberOfPlayers(); i++)
         {
            if (isAIActiveForPlayer(i))
            {
               nbRobots++;
               m.team[i] = 1;
            }
            else
            {
               nbHumans++;
               m.team[i] = 0;
            }
         }
         if ((!nbHumans) || (!nbRobots))
         {
            log_error("skynet_team_mode without robots or humans: switching to normal team mode.\n");
            for (int i = 0; i < nb_dyna; i++)
            {
               m.team[i] = i;
            }
         }
      }
      active = isGameActive();
   }
}

void mrboom_tick_ai()
{
#ifdef __LIBSDL__
   static int selectedPlayer = -1;
   selectedPlayer++;
   if (selectedPlayer >= numberOfPlayers())
   {
      selectedPlayer = 0;
   }
   for (int i = 0; i < 8; i++)
   {
      selectedPlayer = (selectedPlayer + i) % 8;
      if (isAIActiveForPlayer(selectedPlayer) && isAlive(selectedPlayer))
      {
         break;
      }
   }
#endif
   for (int i = 0; i < numberOfPlayers(); i++)
   {
      if (isGameActive())
      {
#ifdef DEBUG
         walkingToCell[i] = 0;
         botStates[i] = goingNowhere;
#endif
#ifdef __LIBSDL__
         if (selectedPlayer == i && isAIActiveForPlayer(i) && isAlive(i))
#else
         if (isAIActiveForPlayer(i) && isAlive(i))
#endif
         {
            tree[i]->updateGrids();
            tree[i]->tick();
         }
      }
      else
      {
         if (isAIActiveForPlayer(i))
         {
            mrboom_update_input(button_a, i, frameNumber() % 4, true); // to press A inside the menu...
            tree[i]->initBot();
         }
      }
   }
}

static void mrboom_hotpatch()
{
   static bool init = false;
   if (init)
   {
      return;
   }
   init = true;

   if (isXmasPeriod())
   {
      memcpy(m.pal, Menu_christmas, 256 * 3);
      memcpy(m.heap + 0x3e800, Menu_christmas + 256 * 3, 320 * 200);
   }
}

void mrboom_loop()
{
   program();
   mrboom_reset_special_keys();
   mrboom_deal_with_skynet_team_mode();
   mrboom_tick_ai();
   mrboom_api();
   mrboom_hotpatch();
}

bool debugTracesPlayer(int player)
{
   return ((1 << player) & traceMask);
}
