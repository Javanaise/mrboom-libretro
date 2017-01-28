#include "common.h"
#include <minizip/unzip.h>
#include <file/file_path.h>
#include <unistd.h>
#include <string.h>
#include "mrboom.h"
#include "data.h"
#include "retro.h"
#ifdef RETRO
#include "libretro.h"
extern retro_log_printf_t log_cb;
#define log_error(...) log_cb(RETRO_LOG_ERROR,__VA_ARGS__);
#define log_debug(...) log_cb(RETRO_LOG_DEBUG,__VA_ARGS__);
#else
#define log_error(args...) printf(## __VA_ARGS__);
#define log_debug(args...) printf(## __VA_ARGS__);
#endif

#define NB_WAV 16
#define NB_VOICES 28

#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define MAX(a, b) ((a) > (b) ? (a) : (b))

static audio_chunk_t *wave[NB_WAV];
static size_t frames_left[NB_WAV];
static int ignoreForAbit[NB_WAV];
static int ignoreForAbitFlag[NB_WAV];

extern Memory m;

int rom_create(const char *path) {
    FILE * file = fopen(path, "wb");
    if (fwrite (dataRom , sizeof(char), sizeof(dataRom), file)!=sizeof(dataRom)) {
        printf("create_rom error\n");
        return -1;
    }
    fclose(file);
    return 0;
}

int rom_unzip(const char *path, const char *extraction_directory)
{
    path_mkdir(extraction_directory);
    
    unzFile *zipfile = unzOpen(path);
    if ( zipfile == NULL )
    {
        printf("%s: not found\n", path);
        return -1;
    }
    unz_global_info global_info;
    if (unzGetGlobalInfo(zipfile, &global_info) != UNZ_OK)
    {
        printf("could not read file global info\n");
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
            printf( "could not read file info\n" );
            unzClose( zipfile );
            return -1;
        }
        
        const size_t filename_length = strlen(filename);
        if (filename[filename_length-1] == '/')
        {
            printf("dir:%s\n", filename);
            char abs_path[PATH_MAX_LENGTH];
            fill_pathname_join(abs_path,
                               extraction_directory, filename, sizeof(abs_path));
            path_mkdir(abs_path);
        }
        else
        {
            printf("file:%s\n", filename);
            if (unzOpenCurrentFile(zipfile) != UNZ_OK)
            {
                printf("could not open file\n");
                unzClose(zipfile);
                return -1;
            }
            
            char abs_path[PATH_MAX_LENGTH];
            fill_pathname_join(abs_path,
                               extraction_directory, filename, sizeof(abs_path));
            FILE *out = fopen(abs_path, "wb");
            if (out == NULL)
            {
                printf("could not open destination file\n");
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
                    printf("error %d\n", error);
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
                printf("cound not read next file\n");
                unzClose(zipfile);
                return -1;
            }
        }
    }
    unzClose(zipfile);
    unlink(path);
    return 0;
}

int mrboom_init(char * save_directory) {
    char romPath[4096];
    char extractPath[4096];
    m.taille_exe_gonfle=0;
    strcpy((char *) &m.iff_file_name,"mrboom31.dat");
    
    snprintf(romPath, sizeof(romPath), "%s/mrboom.rom", save_directory);
    snprintf(extractPath, sizeof(extractPath), "%s/mrboom", save_directory);
    log_debug("romPath: %s\n", romPath);
    
    rom_create(romPath);
    rom_unzip(romPath, extractPath);
    m.path=strdup(extractPath);
    
    for (int i=0;i<NB_WAV;i++) {
        char tmp[PATH_MAX_LENGTH];
        sprintf(tmp,"%s/%d.WAV",extractPath,i);
        wave[i] = audio_mix_load_wav_file(&tmp[0], SAMPLE_RATE);
        ignoreForAbit[i]=0;
        ignoreForAbitFlag[i]=0;
        if (wave[i]==NULL) {
            log_cb(RETRO_LOG_ERROR, "cant load %s\n",tmp);
        }
        ignoreForAbitFlag[i]=5;
    }
    ignoreForAbitFlag[0]=30;
    ignoreForAbitFlag[10]=30; // kanguru jump
    ignoreForAbitFlag[13]=30;
    ignoreForAbitFlag[14]=30;
}

void mrboom_deinit() {
    /* free WAV */
    for (int i=0;i<NB_WAV;i++) {
        audio_mix_free_chunk(wave[i]);
    }
}

void play_fx() {
    static int last_voice=0;
    for (int i=0;i<NB_WAV;i++) {
        if (ignoreForAbit[i]) {
            ignoreForAbit[i]--;
        }
    }
    while (m.last_voice!=last_voice) {
        db a=READDBlW(blow_what2[last_voice/2]);
        db a2=a>>4;
        db a1=a&0xf;
        db b=READDBhW(blow_what2[last_voice/2]);
        log_debug("blow what: sample = %d / panning %d, note: %d ignoreForAbit[%d]\n",a1,a2,b,ignoreForAbit[a1]);
        last_voice=(last_voice+2)%NB_VOICES;
        if ((a1>=0) && (a1<NB_WAV) && (wave[a1]!=NULL)) {
            bool dontPlay=0;
            if (ignoreForAbit[a1]) {
                log_debug("Ignore sample id %d\n",a1);
                dontPlay=1;
            }
            if (dontPlay == 0) {
                frames_left[a1] = audio_mix_get_chunk_num_samples(wave[a1]);

                // special message on failing to start a game...
                if (a1==14) {
                    show_message("2 players are needed to start!");
                }
                ignoreForAbit[a1]=ignoreForAbitFlag[a1];
            }
        } else {
            log_error("Wrong sample id %d or NULL.",a1);
        }
    }
}

#define CLAMP_I16(x) (x > INT16_MAX ? INT16_MAX : x < INT16_MIN ? INT16_MIN : x)

void audio_callback(void)
{
   if (!audio_batch_cb)
      return;

   memset(frame_sample_buf, 0, num_samples_per_frame * 2 * sizeof(int16_t));

   for (unsigned i = 0; i < NB_WAV; i++)
   {
     if (frames_left[i])
     {
         unsigned frames_to_copy = 0;
         int16_t *samples = audio_mix_get_chunk_samples(wave[i]);
         unsigned num_frames = audio_mix_get_chunk_num_samples(wave[i]);

         frames_to_copy = MIN(frames_left[i], num_samples_per_frame);

         for (unsigned j = 0; j < frames_to_copy; j++)
         {
             unsigned chunk_size = num_frames * 2;
             unsigned sample = frames_left[i] * 2;
             frame_sample_buf[j * 2] = CLAMP_I16(frame_sample_buf[j * 2] + samples[chunk_size - sample]);
             frame_sample_buf[(j * 2) + 1] = CLAMP_I16(frame_sample_buf[(j * 2) + 1] + samples[(chunk_size - sample) + 1]);
             frames_left[i]--;
         }
     }
   }

   audio_batch_cb(frame_sample_buf, num_samples_per_frame);
}

