#include <memalign.h>
#include "mrboom.h"
#include "common.h"
extern Memory m;

static uint32_t *frame_buf;
static struct retro_log_callback logging;
retro_log_printf_t log_cb;
static char retro_save_directory[4096];
static char retro_base_directory[4096];
static retro_video_refresh_t video_cb;
static retro_audio_sample_t audio_cb;
static retro_environment_t environ_cb;
static retro_input_poll_t input_poll_cb;
static retro_input_state_t input_state_cb;


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

void retro_init(void)
{
    num_samples_per_frame = SAMPLE_RATE / FPS_RATE;

    frame_sample_buf = (int16_t*)memalign_alloc(128, num_samples_per_frame * 2 * sizeof(int16_t));

    memset(frame_sample_buf, 0, num_samples_per_frame * 2 * sizeof(int16_t));

    log_cb(RETRO_LOG_DEBUG, "retro_init");

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

    mrboom_init(retro_save_directory);

    /* joypads Allocate descriptor values */
    for (i = 0; i < ARRAY_SIZE(descriptors); i++) {
        desc = descriptors[i];
        size = DESC_NUM_PORTS(desc) * DESC_NUM_INDICES(desc) * DESC_NUM_IDS(desc);
        descriptors[i]->value = (uint16_t*)calloc(size, sizeof(uint16_t));
    }
}

void retro_deinit(void)
{
    int i;
    free(frame_buf);
    memalign_free(frame_sample_buf);
    frame_buf = NULL;
    /* Free descriptor values */
    for (i = 0; i < ARRAY_SIZE(descriptors); i++) {
        free(descriptors[i]->value);
        descriptors[i]->value = NULL;
    }
    mrboom_deinit();
}

unsigned retro_api_version(void)
{
    return RETRO_API_VERSION;
}

void retro_set_controller_port_device(unsigned port, unsigned device)
{
    log_cb(RETRO_LOG_INFO, "%s: Plugging device %u into port %u.\n", GAME_NAME, device, port);
}

void retro_get_system_info(struct retro_system_info *info)
{
    memset(info, 0, sizeof(*info));
    info->library_name     = GAME_NAME;
    info->library_version  = GAME_VERSION;
    info->need_fullpath    = false;
    info->valid_extensions = NULL;
}



void retro_get_system_av_info(struct retro_system_av_info *info)
{
    float aspect = 5.0f / 3.0f;

    float sampling_rate = SAMPLE_RATE;

    info->timing = (struct retro_system_timing) {
        .fps = FPS_RATE,
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
            mrboom_update_input(id,port,state);
        }
    }
}

static void render_checkered(void)
{

    static uint32_t matrixPalette[NB_COLORS_PALETTE];

    mrboom_play_fx();

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

void show_message(char * message) {
return;
    struct retro_message msg;
    msg.msg = message;
    msg.frames = 80;
    environ_cb(RETRO_ENVIRONMENT_SET_MESSAGE, (void*)&msg);
}
