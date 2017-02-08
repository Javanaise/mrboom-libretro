
#include <memalign.h>
#include "mrboom.h"
#include "common.h"
#include "retro.h"

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

#if defined(_MSC_VER)
#define SWAP16 _byteswap_ushort
#define SWAP32 _byteswap_ulong
#else
#define SWAP16(x) ((uint16_t)(                  \
(((uint16_t)(x) & 0x00ff) << 8)      | \
(((uint16_t)(x) & 0xff00) >> 8)        \
))
#define SWAP32(x) ((uint32_t)(           \
(((uint32_t)(x) & 0x000000ff) << 24) | \
(((uint32_t)(x) & 0x0000ff00) <<  8) | \
(((uint32_t)(x) & 0x00ff0000) >>  8) | \
(((uint32_t)(x) & 0xff000000) >> 24)   \
))
#endif


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

void update_vga(uint32_t *buf, unsigned stride) {
    static uint32_t matrixPalette[NB_COLORS_PALETTE];
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
}

static void render_checkered(void)
{

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
    update_vga(buf,stride);
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

size_t retro_serialize_size(void)
{
    return SIZE_SER;
}

#define INITVAR_dd(a,b) \
{ \
unsigned int offset=a-offsetof(struct Mem,replayer_saver); \
uint32_t * pointer=(uint32_t *) (((char *) data)+offset); \
for (i=0;i<b;i++) { \
    pointer[i]=SWAP32(pointer[i]); \
} \
}

#define INITVAR_dw(a,b) \
{ \
unsigned int offset=a-offsetof(struct Mem,replayer_saver); \
uint16_t * pointer=(uint16_t *) (((char *) data)+offset); \
for (i=0;i<b;i++) { \
pointer[i]=SWAP16(pointer[i]); \
} \
}

void fixBigEndian(void *data) {
    int i;
    INITVAR_dd(offsetof(struct Mem,replayer_saver),1)
    INITVAR_dd(offsetof(struct Mem,replayer_saver2),1)
    INITVAR_dd(offsetof(struct Mem,replayer_saver3),1)
    INITVAR_dd(offsetof(struct Mem,replayer_saver4),1)
    INITVAR_dd(offsetof(struct Mem,attente),1)
    INITVAR_dd(offsetof(struct Mem,nuage_sympa),5)
    INITVAR_dd(offsetof(struct Mem,dummy1368),5)
    INITVAR_dd(offsetof(struct Mem,dummy1369),5)
    INITVAR_dd(offsetof(struct Mem,dummy1370),5)
    INITVAR_dd(offsetof(struct Mem,dummy1371),5)
    INITVAR_dd(offsetof(struct Mem,dummy1372),5)
    INITVAR_dd(offsetof(struct Mem,dummy1373),5)
    INITVAR_dd(offsetof(struct Mem,dummy1374),5)
    INITVAR_dd(offsetof(struct Mem,dummy1375),5)
    INITVAR_dd(offsetof(struct Mem,dummy1376),5)
    INITVAR_dd(offsetof(struct Mem,dummy1377),5)
    INITVAR_dd(offsetof(struct Mem,dummy1378),5)
    INITVAR_dd(offsetof(struct Mem,dummy1379),5)
    INITVAR_dd(offsetof(struct Mem,dummy1380),5)
    INITVAR_dd(offsetof(struct Mem,dummy1381),5)
    INITVAR_dd(offsetof(struct Mem,dummy1382),5)
    INITVAR_dd(offsetof(struct Mem,vise_de_ca_haut),8)
    INITVAR_dd(offsetof(struct Mem,vise_de_ca_haut2),8)
    INITVAR_dd(offsetof(struct Mem,adder_inser_coin),1)
    INITVAR_dd(offsetof(struct Mem,viseur_ic2),1)
    INITVAR_dd(offsetof(struct Mem,inser_coin),1)
    INITVAR_dd(offsetof(struct Mem,acceleration),1)
    INITVAR_dd(offsetof(struct Mem,attente_entre_chake_bombe),1)
    INITVAR_dd(offsetof(struct Mem,viseur__nouvelle_attente_entre_chake_bombe),1)
    INITVAR_dd(offsetof(struct Mem,liste_bombbbb2),1)
    INITVAR_dd(offsetof(struct Mem,special_nivo_6),1)
    INITVAR_dd(offsetof(struct Mem,differentesply2),1)
    INITVAR_dd(offsetof(struct Mem,temps_avant_demo),1)
    INITVAR_dd(offsetof(struct Mem,ttp),1)
    INITVAR_dd(offsetof(struct Mem,arbre),1)
    INITVAR_dd(offsetof(struct Mem,viseur_couleur),1)
    INITVAR_dd(offsetof(struct Mem,attente_nouveau_esc),1)
    INITVAR_dd(offsetof(struct Mem,scrollyf),1)
    INITVAR_dd(offsetof(struct Mem,tecte2),1)
    INITVAR_dd(offsetof(struct Mem,nombre_de_dyna_x4),1)
    INITVAR_dd(offsetof(struct Mem,changeiny),8)
    INITVAR_dd(offsetof(struct Mem,dummy1383),8)
    INITVAR_dd(offsetof(struct Mem,viseur_change_in),8)
    INITVAR_dd(offsetof(struct Mem,viseur_change_in_save),8)
    INITVAR_dd(offsetof(struct Mem,anti_bomb),2)
    INITVAR_dd(offsetof(struct Mem,dummy1384),2)
    INITVAR_dd(offsetof(struct Mem,dummy1385),2)
    INITVAR_dd(offsetof(struct Mem,dummy1386),2)
    INITVAR_dd(offsetof(struct Mem,machin2),1)
    INITVAR_dd(offsetof(struct Mem,machin3),1)
    INITVAR_dd(offsetof(struct Mem,machin),16)
    INITVAR_dd(offsetof(struct Mem,dummy1387),14)
    INITVAR_dd(offsetof(struct Mem,dummy1388),1)
    INITVAR_dd(offsetof(struct Mem,dummy1389),16)
    INITVAR_dd(offsetof(struct Mem,dummy1390),14)
    INITVAR_dd(offsetof(struct Mem,dummy1391),1)
    INITVAR_dd(offsetof(struct Mem,duree_draw),1)
    INITVAR_dd(offsetof(struct Mem,duree_med),1)
    INITVAR_dd(offsetof(struct Mem,duree_vic),1)
    INITVAR_dd(offsetof(struct Mem,affiche_raster),1)
    INITVAR_dd(offsetof(struct Mem,save_banke),1)
    INITVAR_dd(offsetof(struct Mem,attente_avant_draw),1)
    INITVAR_dd(offsetof(struct Mem,attente_avant_med),1)
    INITVAR_dd(offsetof(struct Mem,pic_time),1)
    INITVAR_dd(offsetof(struct Mem,viseur_sur_fond),1)
    INITVAR_dd(offsetof(struct Mem,viseur_sur_draw),1)
    INITVAR_dd(offsetof(struct Mem,viseur_sur_vic),1)
    INITVAR_dd(offsetof(struct Mem,compteur_nuage),1)
    INITVAR_dd(offsetof(struct Mem,changementzz),1)
    INITVAR_dd(offsetof(struct Mem,changementzz2),1)
    INITVAR_dd(offsetof(struct Mem,changement),1)
    INITVAR_dd(offsetof(struct Mem,touches),8)
    INITVAR_dd(offsetof(struct Mem,avance),8)
    INITVAR_dd(offsetof(struct Mem,avance2),8)
    INITVAR_dd(offsetof(struct Mem,touches_save),8)
    INITVAR_dd(offsetof(struct Mem,vie),8)
    INITVAR_dd(offsetof(struct Mem,victoires),8)
    INITVAR_dd(offsetof(struct Mem,latest_victory),1)
    INITVAR_dd(offsetof(struct Mem,team),8)
    INITVAR_dd(offsetof(struct Mem,nombre_minimum_de_dyna),1)
    INITVAR_dd(offsetof(struct Mem,infos_j_n),5)
    INITVAR_dd(offsetof(struct Mem,infos_m_n),40)
    INITVAR_dd(offsetof(struct Mem,last_bomb),8)
    INITVAR_dd(offsetof(struct Mem,viseur_liste_terrain),1)
    INITVAR_dd(offsetof(struct Mem,nombre_de_dyna),1)
    INITVAR_dd(offsetof(struct Mem,nombre_de_monstres),1)
    INITVAR_dd(offsetof(struct Mem,nombre_de_vbl_avant_le_droit_de_poser_bombe),1)
    INITVAR_dd(offsetof(struct Mem,j1),5)
    INITVAR_dd(offsetof(struct Mem,j2),5)
    INITVAR_dd(offsetof(struct Mem,j3),5)
    INITVAR_dd(offsetof(struct Mem,j4),5)
    INITVAR_dd(offsetof(struct Mem,j5),5)
    INITVAR_dd(offsetof(struct Mem,j6),5)
    INITVAR_dd(offsetof(struct Mem,j7),5)
    INITVAR_dd(offsetof(struct Mem,j8),5)
    INITVAR_dd(offsetof(struct Mem,liste_bombe),1)
    INITVAR_dd(offsetof(struct Mem,dummy1392),1482)
    INITVAR_dw(offsetof(struct Mem,donnee),8)
    INITVAR_dw(offsetof(struct Mem,dummy1393),8)
    INITVAR_dw(offsetof(struct Mem,dummy1394),8)
    INITVAR_dd(offsetof(struct Mem,ooo546),8)
    INITVAR_dw(offsetof(struct Mem,dummy1395),8)
    INITVAR_dw(offsetof(struct Mem,dummy1396),8)
    INITVAR_dd(offsetof(struct Mem,dummy1397),8)
    INITVAR_dd(offsetof(struct Mem,liste_couleur),8)
    INITVAR_dd(offsetof(struct Mem,nombre_de_coups),8)
    INITVAR_dd(offsetof(struct Mem,clignotement),8)
    INITVAR_dd(offsetof(struct Mem,pousseur),8)
    INITVAR_dd(offsetof(struct Mem,patineur),8)
    INITVAR_dd(offsetof(struct Mem,vitesse_monstre),8)
    INITVAR_dd(offsetof(struct Mem,tribombe2),8)
    INITVAR_dd(offsetof(struct Mem,tribombe),8)
    INITVAR_dd(offsetof(struct Mem,invinsible),8)
    INITVAR_dd(offsetof(struct Mem,blocage),8)
    INITVAR_dd(offsetof(struct Mem,lapipipino),8)
    INITVAR_dd(offsetof(struct Mem,lapipipino2),8)
    INITVAR_dd(offsetof(struct Mem,lapipipino3),8)
    INITVAR_dd(offsetof(struct Mem,lapipipino4),8)
    INITVAR_dd(offsetof(struct Mem,lapipipino5),8)
    INITVAR_dd(offsetof(struct Mem,lapipipino6),8)
    INITVAR_dd(offsetof(struct Mem,lapipipino7),8)
    INITVAR_dw(offsetof(struct Mem,adder_bdraw),1)
    INITVAR_dw(offsetof(struct Mem,temps),1)
    INITVAR_dd(offsetof(struct Mem,kel_ombre),1)
    INITVAR_dw(offsetof(struct Mem,ombres),8)
    INITVAR_dw(offsetof(struct Mem,briques),495)
    INITVAR_dw(offsetof(struct Mem,bombes),495)
    INITVAR_dd(offsetof(struct Mem,control_joueur),8)
    INITVAR_dd(offsetof(struct Mem,control_joueur2),8)
    INITVAR_dd(offsetof(struct Mem,name_joueur),8)
    INITVAR_dd(offsetof(struct Mem,temps_joueur),8)
    INITVAR_dd(offsetof(struct Mem,nb_ordy_connected),1)
    INITVAR_dd(offsetof(struct Mem,last_name),1)
    INITVAR_dd(offsetof(struct Mem,lapin_mania),2)
    INITVAR_dd(offsetof(struct Mem,dummy1567),2)
    INITVAR_dd(offsetof(struct Mem,dummy1568),2)
    INITVAR_dd(offsetof(struct Mem,dummy1569),2)
    INITVAR_dd(offsetof(struct Mem,lapin_mania_malade),2)
    INITVAR_dd(offsetof(struct Mem,dummy1570),2)
    INITVAR_dd(offsetof(struct Mem,dummy1571),2)
    INITVAR_dd(offsetof(struct Mem,dummy1572),2)
    INITVAR_dd(offsetof(struct Mem,lapin_mania1),2)
    INITVAR_dd(offsetof(struct Mem,dummy1573),2)
    INITVAR_dd(offsetof(struct Mem,dummy1574),2)
    INITVAR_dd(offsetof(struct Mem,dummy1575),2)
    INITVAR_dd(offsetof(struct Mem,lapin_mania2),2)
    INITVAR_dd(offsetof(struct Mem,dummy1576),2)
    INITVAR_dd(offsetof(struct Mem,dummy1577),2)
    INITVAR_dd(offsetof(struct Mem,dummy1578),2)
    INITVAR_dd(offsetof(struct Mem,lapin_mania3),2)
    INITVAR_dd(offsetof(struct Mem,dummy1579),2)
    INITVAR_dd(offsetof(struct Mem,dummy1580),2)
    INITVAR_dd(offsetof(struct Mem,dummy1581),2)
    INITVAR_dd(offsetof(struct Mem,lapin_mania4),2)
    INITVAR_dd(offsetof(struct Mem,dummy1582),2)
    INITVAR_dd(offsetof(struct Mem,dummy1583),2)
    INITVAR_dd(offsetof(struct Mem,dummy1584),2)
    INITVAR_dd(offsetof(struct Mem,lapin_mania5),2)
    INITVAR_dd(offsetof(struct Mem,dummy1585),2)
    INITVAR_dd(offsetof(struct Mem,dummy1586),2)
    INITVAR_dd(offsetof(struct Mem,dummy1587),2)
    INITVAR_dd(offsetof(struct Mem,dummy1588),1)
    INITVAR_dd(offsetof(struct Mem,maladie),8)
    INITVAR_dd(offsetof(struct Mem,viseur_hazard_bonus),1)
    INITVAR_dd(offsetof(struct Mem,viseur_hazard_bonus2),1)
    
}

bool retro_serialize(void *data_, size_t size)
{
    memcpy(data_, &m.FIRST_RW_VARIABLE, SIZE_SER);
    if (is_little_endian()==false) {
        fixBigEndian(data_);
    }
    return true;
}

bool retro_unserialize(const void *data_, size_t size)
{
    if (is_little_endian()==false) {
        char dataTmp[SIZE_MEM_MAX];
        memcpy(dataTmp,data_, SIZE_SER);
        fixBigEndian(dataTmp);
        memcpy(&m.FIRST_RW_VARIABLE, dataTmp, SIZE_SER);
    } else {
        memcpy(&m.FIRST_RW_VARIABLE, data_, SIZE_SER);
    }
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
