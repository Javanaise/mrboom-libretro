#include <unistd.h>
#include <string.h>
#include <file/file_path.h>
#include <minizip/unzip.h>
#include "streams/file_stream.h"
#include "mrboom.h"
#include "data.h"
#include "wav_data.h"
#include "common.h"

#define SOUND_VOLUME 2
#define NB_WAV                16
#define NB_VOICES             28
#define keyboardCodeOffset    32
#define keyboardReturnKey     28
#define keyboardExitKey       1
#define keyboardDataSize      8
#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define MAX(a, b) ((a) > (b) ? (a) : (b))
#define keyboardExtraSelectStartKeysSize 2
#define offsetExtraKeys keyboardDataSize*nb_dyna+keyboardCodeOffset

#include "retro.h"
static size_t frames_left[NB_WAV];
#define CLAMP_I16(x) (x > INT16_MAX ? INT16_MAX : x < INT16_MIN ? INT16_MIN : x)

static int ignoreForAbit[NB_WAV];
static int ignoreForAbitFlag[NB_WAV];

extern Memory m;


int rom_unzip(const char *path, const char *extraction_directory)
{
    path_mkdir(extraction_directory);

    unzFile *zipfile = unzOpen(path);
    if ( zipfile == NULL )
    {
        log_error("%s: not found\n", path);
        return -1;
    }
    unz_global_info global_info;
    if (unzGetGlobalInfo(zipfile, &global_info) != UNZ_OK)
    {
        log_error("could not read file global info\n");
        unzClose(zipfile);
        return -1;
    }


    char read_buffer[8192];

    uLong i;
    for (i = 0; i < global_info.number_entry; ++i)
    {
        unz_file_info file_info;
        char filename[PATH_MAX_LENGTH];
        if (unzGetCurrentFileInfo(zipfile, &file_info, filename, PATH_MAX_LENGTH,
                                  NULL, 0, NULL, 0 ) != UNZ_OK)
        {
            log_error( "could not read file info\n" );
            unzClose( zipfile );
            return -1;
        }

        const size_t filename_length = strlen(filename);
        if (filename[filename_length-1] == '/')
        {
            log_debug("dir:%s\n", filename);
            char abs_path[PATH_MAX_LENGTH];
            fill_pathname_join(abs_path,
                               extraction_directory, filename, sizeof(abs_path));
            path_mkdir(abs_path);
        }
        else
        {
            log_debug("file:%s\n", filename);
            if (unzOpenCurrentFile(zipfile) != UNZ_OK)
            {
                log_error("could not open file\n");
                unzClose(zipfile);
                return -1;
            }

            char abs_path[PATH_MAX_LENGTH];
            fill_pathname_join(abs_path,
                               extraction_directory, filename, sizeof(abs_path));
            FILE *out = fopen(abs_path, "wb");
            if (out == NULL)
            {
                log_error("could not open destination file\n");
                unzCloseCurrentFile(zipfile);
                unzClose(zipfile);
                return -1;
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
                    return -1;
                }

                if (error > 0)
                    fwrite(read_buffer, error, 1, out);

            } while (error > 0);

            fclose(out);
        }

        unzCloseCurrentFile(zipfile);

        if (i + 1  < global_info.number_entry)
        {
            if (unzGoToNextFile(zipfile) != UNZ_OK)
            {
                log_error("cound not read next file\n");
                unzClose(zipfile);
                return -1;
            }
        }
    }
    unzClose(zipfile);
    unlink(path);
    return 0;
}


bool mrboom_debug_state_failed() {
    static db * saveState=NULL;
   // static db * saveState2=NULL;
   // static unsigned int offsetBegSecondRO=offsetof(struct Mem,heap);
   // unsigned int sizeSecondRO=HEAP_SIZE;
    unsigned int i=0;
    bool failed=false;
    if (saveState==NULL) {
        saveState=calloc(SIZE_RO_SEGMENT,1);
        memcpy(saveState, &m.FIRST_RO_VARIABLE ,  SIZE_RO_SEGMENT);
      //  saveState2=calloc(sizeSecondRO,1);
      //  memcpy(saveState2, &m.heap , sizeSecondRO);
    } else {
        db * currentMem=&m.FIRST_RO_VARIABLE;
        for (i=0;i<SIZE_RO_SEGMENT;i++) {
            if (saveState[i]!=currentMem[i]) {
                log_error("RO variable changed at %x\n",i+(unsigned int) offsetof(struct Mem,FIRST_RO_VARIABLE));
                memcpy(saveState, &m.FIRST_RO_VARIABLE ,  SIZE_RO_SEGMENT);
                failed=true;
            }
        }
        /*
        for (i=0;i<sizeSecondRO;i++) {
            if (saveState2[i]!=m.heap[i]) {
                log_error("x Second RO variable changed at %x/%d %d/%d\n",&m.heap[i],i,saveState2[i],m.heap[i]);
                memcpy(saveState2, &m.heap , sizeSecondRO);
                failed=true;
            }
        }
         */
    }
    return failed;
}

int mrboom_init(char * save_directory) {
    int i;
    char romPath[PATH_MAX_LENGTH];
    char dataPath[PATH_MAX_LENGTH];
    char extractPath[PATH_MAX_LENGTH];
    asm2C_init();
    if (!m.isLittle) {
        m.isbigendian=1;
    }
    m.taille_exe_gonfle=0;
    strcpy((char *) &m.iff_file_name,"mrboom.dat");

    snprintf(romPath, sizeof(romPath), "%s/mrboom.rom", save_directory);
    snprintf(extractPath, sizeof(extractPath), "%s/mrboom", save_directory);
    log_info("romPath: %s\n", romPath);
    if (filestream_write_file(romPath, dataRom, sizeof(dataRom))==false) {
        log_error("Writing %s\n",romPath);
        return 0;
    }
    
    rom_unzip(romPath, extractPath);
    m.path=strdup(extractPath);
    for (i=0;i<NB_WAV;i++) {
        ignoreForAbit[i]=0;
        ignoreForAbitFlag[i]=5;
    }
    ignoreForAbitFlag[0]=30;
    ignoreForAbitFlag[10]=30; // kanguru jump
    ignoreForAbitFlag[13]=30;
    ignoreForAbitFlag[14]=30;

    for (i=0;i<keyboardDataSize*nb_dyna;i++) {
        if (!((i+1)%keyboardDataSize)) {
            m.touches_[i]=-1;
        } else {
            m.touches_[i]=i+keyboardCodeOffset;
        }
    }
    program();
    m.nosetjmp=1; //will go to menu, except if state loaded after
    
    log_debug("dataPath = %s \n",dataPath);
    snprintf(dataPath, sizeof(dataPath), "%s/mrboom.dat", save_directory);
    unlink(dataPath);
    
#ifdef DEBUG
    asm2C_printOffsets(offsetof(struct Mem,FIRST_RW_VARIABLE));
#endif
    return 0;
}

void mrboom_deinit() {
}

void mrboom_play_fx(void)
{
   int i;
   static int last_voice=0;
   for (i=0;i<NB_WAV;i++)
   {
      if (ignoreForAbit[i])
         ignoreForAbit[i]--;
   }

   while (m.last_voice!=last_voice)
   {
      db a=*(((db *) &m.blow_what2[last_voice/2]));
      db a1=a&0xf;
      log_debug("blow what: sample = %d / panning %d, note: %d ignoreForAbit[%d]\n",a1,(db) a>>4,(db)(*(((db *) &m.blow_what2[last_voice/2])+1)),ignoreForAbit[a1]);
      last_voice=(last_voice+2)%NB_VOICES;
      if ((a1>=0) && (a1<NB_WAV))
      {
         bool dontPlay=0;

         if (ignoreForAbit[a1])
         {
            log_debug("Ignore sample id %d\n",a1);
            dontPlay=1;
         }

         if (dontPlay == 0)
         {
            frames_left[a1] = wave[a1].num_samples;

#ifdef __LIBRETRO__
            // special message on failing to start a game...
            if (a1==14)
            {
               show_message("2 players are needed to start!");
            }
#endif
            ignoreForAbit[a1]=ignoreForAbitFlag[a1];
         }
      }
      else
      {
         log_error("Wrong sample id %d or NULL.",a1);
      }
   }
}

void mrboom_update_input(int keyid, int playerNumber,int state)
{
   int key=-1;
   int keyAdder=keyboardCodeOffset+playerNumber*keyboardDataSize;
   switch (keyid)
   {
      case button_down:
         key=3+keyAdder; // DOWN
         break;
      case button_right:
         key=1+keyAdder; //right
         break;
      case button_left:
         key=0+keyAdder; //left
         break;
      case button_up:
         key=2+keyAdder; //up
         break;
      case button_a:
         key=5+keyAdder; //bouton 2
         break;
      case button_select:
         key=offsetExtraKeys+playerNumber*keyboardExtraSelectStartKeysSize; // selection;
         break;
      case button_start:
         key=offsetExtraKeys+playerNumber*keyboardExtraSelectStartKeysSize+1; // start;
         break;
      case button_b:
         key=4+keyAdder; //bouton 1
         break;
      case button_x:
         key=6+keyAdder; //bouton 3
         break;

   }

   if (key!=-1)
   {
      int i;
      if (m.clavier[key]!=state)
      {
         m.une_touche_a_telle_ete_pressee=1;
         log_debug("Player %d, pressing %d->%d\n",playerNumber, keyid, key);
      }

      m.clavier[key]=state;
      m.clavier[keyboardReturnKey]=0; // return
      m.clavier[keyboardExitKey]=0; //esc

      for (i=0;i<nb_dyna;i++)
      {
         if (m.clavier[offsetExtraKeys+i*2] && m.clavier[offsetExtraKeys+1+i*2])
         {
            // select + start -> escape
            m.clavier[keyboardExitKey]=1;
            log_debug("Player %d exit key pressed... %d+%d->%d\n",playerNumber,offsetExtraKeys+i*2,offsetExtraKeys+i*2+1, keyboardExitKey);
            m.sortie=1;

         }

         if (m.clavier[offsetExtraKeys+i*2+1])
         {
            log_debug("Player %d return key pressed... %d->%d\n",playerNumber, offsetExtraKeys+i*2+1, keyboardReturnKey);
            m.clavier[keyboardReturnKey]=1; // return
         }
      }
   }
   else
   {
      log_debug("unknown %d\n,key",key);
   }
}

#ifdef __LIBRETRO__
void audio_callback(void)
{
   unsigned i;
   if (!audio_batch_cb)
      return;

   memset(frame_sample_buf, 0, num_samples_per_frame * 2 * sizeof(int16_t));

   for (i = 0; i < NB_WAV; i++)
   {
     if (frames_left[i])
     {
        unsigned j;
        unsigned frames_to_copy = 0;
        int16_t        *samples = wave[i].samples;
        unsigned     num_frames = wave[i].num_samples;

        frames_to_copy = MIN(frames_left[i], num_samples_per_frame);

        for (j = 0; j < frames_to_copy; j++)
        {
           unsigned chunk_size = num_frames * 2;
           unsigned sample = frames_left[i] * 2;
           frame_sample_buf[j * 2] = CLAMP_I16(frame_sample_buf[j * 2] + (samples[chunk_size - sample] >> SOUND_VOLUME));
           frame_sample_buf[(j * 2) + 1] = CLAMP_I16(frame_sample_buf[(j * 2) + 1] + (samples[(chunk_size - sample) + 1] >> SOUND_VOLUME));
           frames_left[i]--;
        }
     }
   }

   audio_batch_cb(frame_sample_buf, num_samples_per_frame);
}
#endif
