
#include "libretro.h"
#include <SDL2/SDL.h>
#include <SDL2/SDL_mixer.h>
#include <minizip/unzip.h>
#include <file/file_path.h>
#include "mrboom.h"

#define NB_WAV 16

static uint32_t *frame_buf;
static struct retro_log_callback logging;
static retro_log_printf_t log_cb;
static Mix_Chunk * wave[NB_WAV];
static int ignoreForAbit[NB_WAV];
static int ignoreForAbitFlag[NB_WAV];
static char retro_save_directory[4096];
static char retro_base_directory[4096];
static retro_video_refresh_t video_cb;
static retro_audio_sample_t audio_cb;
static retro_audio_sample_batch_t audio_batch_cb;
static retro_environment_t environ_cb;
static retro_input_poll_t input_poll_cb;
static retro_input_state_t input_state_cb;

#include "data.h"

extern Memory m;

// joypads

#define DESC_NUM_PORTS(desc) ((desc)->port_max - (desc)->port_min + 1)
#define DESC_NUM_INDICES(desc) ((desc)->index_max - (desc)->index_min + 1)
#define DESC_NUM_IDS(desc) ((desc)->id_max - (desc)->id_min + 1)

#define DESC_OFFSET(desc, port, index, id) ( \
port * ((desc)->index_max - (desc)->index_min + 1) * ((desc)->id_max - (desc)->id_min + 1) + \
index * ((desc)->id_max - (desc)->id_min + 1) + \
id \
)

#define ARRAY_SIZE(a) (sizeof(a) / sizeof((a)[0]))
#define PATH_MAX_LENGTH 256
#define NB_COLORS_PALETTE 256
#define NB_VOICES 28
#define WIDTH 320
#define HEIGHT 200

struct descriptor {
    int device;
    int port_min;
    int port_max;
    int index_min;
    int index_max;
    int id_min;
    int id_max;
    uint16_t *value;
};

static struct descriptor joypad = {
    .device = RETRO_DEVICE_JOYPAD,
    .port_min = 0,
    .port_max = 7,
    .index_min = 0,
    .index_max = 0,
    .id_min = RETRO_DEVICE_ID_JOYPAD_B,
    .id_max = RETRO_DEVICE_ID_JOYPAD_R3
};

static struct descriptor *descriptors[] = {
    &joypad
};

static void fallback_log(enum retro_log_level level, const char *fmt, ...)
{
    (void)level;
    va_list va;
    va_start(va, fmt);
    vfprintf(stderr, fmt, va);
    va_end(va);
}


int rom_create(const char *path) {
     FILE * file = fopen(path, "wb");
    if (fwrite (dataRom , sizeof(char), sizeof(dataRom), file)!=sizeof(dataRom)) {
        log_cb(RETRO_LOG_ERROR,"create_rom error\n");
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
        log_cb(RETRO_LOG_ERROR,"%s: not found\n", path);
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
    return 0;

}

void retro_init(void)
{

    log_cb(RETRO_LOG_DEBUG, "retro_init");
    m.taille_exe_gonfle=0;
    strcpy((char *) &m.iff_file_name,"mrboom31.dat");
    struct descriptor *desc;
    int size;
    int i;

    const char *dir = NULL;
    sprintf(retro_base_directory,"/tmp");
    
    if (environ_cb(RETRO_ENVIRONMENT_GET_SYSTEM_DIRECTORY, &dir) && dir)
    {
        if (strlen(dir)) {
            snprintf(retro_base_directory, sizeof(retro_base_directory), "%s", dir);
        }
    }

    if (environ_cb(RETRO_ENVIRONMENT_GET_SAVE_DIRECTORY, &dir) && dir)
    {
        // If save directory is defined use it, otherwise use system directory
        if (strlen(dir))
            snprintf(retro_save_directory, sizeof(retro_save_directory), "%s", dir);
        else
            snprintf(retro_save_directory, sizeof(retro_save_directory), "%s", retro_base_directory);
    }
    
    frame_buf = calloc(WIDTH * HEIGHT, sizeof(uint32_t));
    // Initialize SDL.
    if (SDL_Init(SDL_INIT_AUDIO) < 0) {
        log_cb(RETRO_LOG_ERROR, "Error SDL_Init\n");
    }

    //Initialize SDL_mixer
    if( Mix_OpenAudio( 44100, MIX_DEFAULT_FORMAT, 2, 512 ) == -1 ) {
        log_cb(RETRO_LOG_ERROR, "Error Mix_OpenAudio\n");
    }

    char romPath[4096];
    char extractPath[4096];
    snprintf(romPath, sizeof(romPath), "%s/mrboom.rom", retro_save_directory);
    snprintf(extractPath, sizeof(extractPath), "%s/mrboom", retro_save_directory);

    log_cb(RETRO_LOG_DEBUG, "romPath: %s\n", romPath);
    
    rom_create(romPath);
    rom_unzip(romPath, extractPath);
    unlink(romPath);
    m.path=strdup(extractPath);

    for (i=0;i<NB_WAV;i++) {
        char tmp[PATH_MAX_LENGTH];
        sprintf(tmp,"%s/%d.WAV",extractPath,i);
        wave[i] = Mix_LoadWAV(tmp);
        ignoreForAbit[i]=0;
        ignoreForAbitFlag[i]=0;
        if (wave[i]==NULL) {
            log_cb(RETRO_LOG_ERROR, "cant load %s\n",tmp);
        }
    }
    ignoreForAbitFlag[0]=30;
    ignoreForAbitFlag[10]=30; // kanguru jump
    ignoreForAbitFlag[13]=30;
    ignoreForAbitFlag[14]=30;


    /* joypads Allocate descriptor values */
    for (i = 0; i < ARRAY_SIZE(descriptors); i++) {
        desc = descriptors[i];
        size = DESC_NUM_PORTS(desc) * DESC_NUM_INDICES(desc) * DESC_NUM_IDS(desc);
        descriptors[i]->value = (uint16_t*)calloc(size, sizeof(uint16_t));
    }
#define keyboardCodeOffset 32
#define keyboardReturnKey 28
#define keyboardExitKey 1
#define keyboardDataSize 8
#define nb_dyna 8
    for (i=0;i<keyboardDataSize*nb_dyna;i++) {
        if (!((i+1)%keyboardDataSize)) {
            m.touches_[i]=-1;
        } else {
            m.touches_[i]=i+keyboardCodeOffset;
        }

    }
}

void retro_deinit(void)
{
    int i;
    free(frame_buf);
    frame_buf = NULL;
    /* Free descriptor values */
    for (i = 0; i < ARRAY_SIZE(descriptors); i++) {
        free(descriptors[i]->value);
        descriptors[i]->value = NULL;
    }
    /* free WAV */
    for (i=0;i<NB_WAV;i++) {
        Mix_FreeChunk(wave[i]);
    }
    // quit SDL_mixer
    Mix_CloseAudio();
}

unsigned retro_api_version(void)
{
    return RETRO_API_VERSION;
}

void retro_set_controller_port_device(unsigned port, unsigned device)
{
    log_cb(RETRO_LOG_INFO, "MrBoom: Plugging device %u into port %u.\n", device, port);
}

void retro_get_system_info(struct retro_system_info *info)
{
    memset(info, 0, sizeof(*info));
    info->library_name     = "MrBoom";
    info->library_version  = "v3.1";
    info->need_fullpath    = false;
    info->valid_extensions = NULL;
}



void retro_get_system_av_info(struct retro_system_av_info *info)
{
    float aspect = 5.0f / 3.0f;

    float sampling_rate = 30000.0f;

    info->timing = (struct retro_system_timing) {
        .fps = 60.0,
        .sample_rate = sampling_rate,
    };


    info->geometry = (struct retro_game_geometry) {
        .base_width   = WIDTH,
        .base_height  = HEIGHT,
        .max_width    = WIDTH,
        .max_height   = HEIGHT,
        .aspect_ratio = aspect,
    };

}

void retro_set_environment(retro_environment_t cb)
{
    environ_cb = cb;

    bool no_content = true;

    cb(RETRO_ENVIRONMENT_SET_SUPPORT_NO_GAME, &no_content);

    if (cb(RETRO_ENVIRONMENT_GET_LOG_INTERFACE, &logging))
        log_cb = logging.log;
    else
        log_cb = fallback_log;

}

void retro_set_audio_sample(retro_audio_sample_t cb)
{
    audio_cb = cb;
}

void retro_set_audio_sample_batch(retro_audio_sample_batch_t cb)
{
    audio_batch_cb = cb;
}

void retro_set_input_poll(retro_input_poll_t cb)
{
    input_poll_cb = cb;
}

void retro_set_input_state(retro_input_state_t cb)
{
    input_state_cb = cb;
}

void retro_set_video_refresh(retro_video_refresh_t cb)
{
    video_cb = cb;
}

void retro_reset(void)
{
}

static void update_input(void)
{
    struct descriptor *desc;
    uint16_t state;
    uint16_t old;
    int offset;
    int port;
    int index;
    int id;
    int i;

    /* Poll input */
    input_poll_cb();

    /* Parse descriptors */
    for (i = 0; i < ARRAY_SIZE(descriptors); i++) {
        /* Get current descriptor */
        desc = descriptors[i];

        /* Go through range of ports/indices/IDs */
        for (port = desc->port_min; port <= desc->port_max; port++)
        for (index = desc->index_min; index <= desc->index_max; index++)
        for (id = desc->id_min; id <= desc->id_max; id++) {
            /* Compute offset into array */
            offset = DESC_OFFSET(desc, port, index, id);

            /* Get old state */
            old = desc->value[offset];

            /* Get new state */
            state = input_state_cb(port,
                                   desc->device,
                                   index,
                                   id);


            /* Continue if state is unchanged */
            if (state == old)
            continue;

            /* Update state */
            desc->value[offset] = state;
            log_cb(RETRO_LOG_DEBUG,"i=%d joypad port %d index = %d id %d: %d -> %d\n",i,port,index,id,offset,state);
            int key=-1;
            int keyAdder=keyboardCodeOffset+port*keyboardDataSize;
#define keyboardExtraSelectStartKeysSize 2
#define offsetExtraKeys keyboardDataSize*nb_dyna+keyboardCodeOffset
            switch (id) {
                case 5: //down
                    key=3+keyAdder; // DOWN
                    break;
                case 7: //right
                    key=1+keyAdder; //right
                    break;
                case 6: //left
                    key=0+keyAdder; //left
                    break;
                case 4: //up
                    key=2+keyAdder; //up
                    break;
                case 8: // bouton a
                    key=5+keyAdder; //bouton 2
                    break;
                case 2:
                    key=offsetExtraKeys+port*keyboardExtraSelectStartKeysSize; // selection;
                    break;
                case 3:
                    key=offsetExtraKeys+port*keyboardExtraSelectStartKeysSize+1; // start;
                    break;
                case 0:
                    key=4+keyAdder; //bouton 1
                    break;
                case 1: // Y
                    key=6+keyAdder; //bouton 3
                    break;
                case 9: //X
                    key=6+keyAdder; //bouton 3
                    break;
                case 10: //L
                    key=4+keyAdder; //bouton 1
                    break;
                case 11: //R
                    key=4+keyAdder; //bouton 1
                    break;
            }
            if (key!=-1) {
                log_cb(RETRO_LOG_DEBUG,"pressing %d\n",key);
                m.clavier[key]=state;
                m.une_touche_a_telle_ete_pressee=1;
                m.clavier[keyboardReturnKey]=0; // return
                m.clavier[keyboardExitKey]=0; //esc
                for (int i=0;i<nb_dyna;i++) {
                    if (m.clavier[offsetExtraKeys+i*2] && m.clavier[offsetExtraKeys+1+i*2]) {
                        // select + start -> escape
                        m.clavier[keyboardExitKey]=1;
                        log_cb(RETRO_LOG_DEBUG,"exit key pressed...\n");
                        m.sortie=1;

                    }
                    if (m.clavier[offsetExtraKeys+i*2+1]) {
                        log_cb(RETRO_LOG_DEBUG,"return key pressed...\n");
                        m.clavier[keyboardReturnKey]=1; // return
                    }
                }
            } else {
                log_cb(RETRO_LOG_DEBUG,"unknown %d\n,key",key);
            }
        }
    }
}

static void render_checkered(void)
{

    static int last_voice=0;
    static uint32_t matrixPalette[NB_COLORS_PALETTE];


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
        log_cb(RETRO_LOG_INFO, "blow what: sample = %d / panning %d, note: %d ignoreForAbit[%d]\n",a1,a2,b,ignoreForAbit[a1]);
        last_voice=(last_voice+2)%NB_VOICES;
        if ((a1>=0) && (a1<NB_WAV) && (wave[a1]!=NULL)) {
            bool dontPlay=0;

            
            if (ignoreForAbit[a1]) {
                log_cb(RETRO_LOG_DEBUG, "Ignore sample id %d\n",a1);
                dontPlay=1;
            }
            if (dontPlay == 0) {
                if ( Mix_PlayChannel(-1, wave[a1], 0) == -1 ) {
                    log_cb(RETRO_LOG_ERROR, "Error playing sample id %d.\n",a1);
                }
                
                // special message on failing to start a game...
                if (a1==14) {
                    struct retro_message msg;
                    char msg_local[512];
                    snprintf(msg_local, sizeof(msg_local), "2 players are needed to start!\n");
                    msg.msg = msg_local;
                    msg.frames = 80;
                    environ_cb(RETRO_ENVIRONMENT_SET_MESSAGE, (void*)&msg);
                }
                //
                ignoreForAbit[a1]=ignoreForAbitFlag[a1];
            }
        } else {
            log_cb(RETRO_LOG_ERROR, "Wrong sample id %d or NULL.",a1);
        }
    }

    /* Try rendering straight into VRAM if we can. */
    uint32_t *buf = NULL;
    unsigned stride = 0;
    struct retro_framebuffer fb = {0};
    fb.width = WIDTH;
    fb.height = HEIGHT;
    fb.access_flags = RETRO_MEMORY_ACCESS_WRITE;
    if (environ_cb(RETRO_ENVIRONMENT_GET_CURRENT_SOFTWARE_FRAMEBUFFER, &fb) && fb.format == RETRO_PIXEL_FORMAT_XRGB8888)
    {
        buf = fb.data;
        stride = fb.pitch >> 2;
    }
    else
    {
        buf = frame_buf;
        stride = WIDTH;
    }

    int z=0;
    do {
        matrixPalette[z/3]= ((m.vgaPalette[z]*4) << 16) | ((m.vgaPalette[z+1]*4) << 8) | (m.vgaPalette[z+2]*4);
        z+=3;
    } while (z!=NB_COLORS_PALETTE*3);


    uint32_t *line = buf;
    for (unsigned y = 0; y < HEIGHT; y++, line += stride)
    {
        for (unsigned x = 0; x < WIDTH; x++)
        {
            if (y<HEIGHT) {
                line[x] = matrixPalette[m.vgaRam[x+y*WIDTH]];
            }
        }
    }
    video_cb(buf, WIDTH, HEIGHT, stride << 2);
}

static void check_variables(void)
{
}

static void audio_callback(void)
{
    audio_cb(0, 0);
}

void retro_run(void)
{
    update_input();
    render_checkered();
    audio_callback();
    program();

    if (m.executionFinished) {
        log_cb(RETRO_LOG_INFO, "Exit.\n");
        environ_cb(RETRO_ENVIRONMENT_SHUTDOWN, NULL);
    }

    bool updated = false;
    if (environ_cb(RETRO_ENVIRONMENT_GET_VARIABLE_UPDATE, &updated) && updated)
        check_variables();
}


bool retro_load_game(const struct retro_game_info *info)
{
    enum retro_pixel_format fmt = RETRO_PIXEL_FORMAT_XRGB8888;
    if (!environ_cb(RETRO_ENVIRONMENT_SET_PIXEL_FORMAT, &fmt))
    {
        log_cb(RETRO_LOG_INFO, "XRGB8888 is not supported.\n");
        return false;
    }

    check_variables();

    (void)info;
    return true;
}

void retro_unload_game(void)
{
}

unsigned retro_get_region(void)
{
    return RETRO_REGION_NTSC;
}

bool retro_load_game_special(unsigned type, const struct retro_game_info *info, size_t num)
{
    return retro_load_game(NULL);
}
#define SIZE_SER offsetof(struct Mem,heapPointer)-offsetof(struct Mem,winhdle)

size_t retro_serialize_size(void)
{
    return SIZE_SER;
}

bool retro_serialize(void *data_, size_t size)
{
    memcpy(data_, &m.winhdle, SIZE_SER);
    return true;
}

bool retro_unserialize(const void *data_, size_t size)
{
    memcpy(&m.winhdle, data_, SIZE_SER);
    return true;
}

void *retro_get_memory_data(unsigned id)
{
    (void)id;
    return NULL;
}

size_t retro_get_memory_size(unsigned id)
{
    (void)id;
    return 0;
}

void retro_cheat_reset(void)
{}

void retro_cheat_set(unsigned index, bool enabled, const char *code)
{
    (void)index;
    (void)enabled;
    (void)code;
}
