#include "mrboom.h"
#include "common.h"
#include "retro.h"
#include "streams/file_stream.h"
#include "file/file_path.h"
#include "formats/rbmp.h"
#include <time.h>

#define NB_FRAME_PER_WINDOW 10000
#define NB_WINDOWS 10

extern Memory m;
extern retro_log_printf_t log_cb;
static uint32_t *frame_buf;

void testLogging(enum retro_log_level level, const char *fmt, ...) {
    va_list args;
    char buf[1000];
    va_start(args, fmt);
    vsnprintf(buf, sizeof(buf), fmt, args );
    va_end(args);
    printf("%s",buf);
}


static char data[SIZE_MEM_MAX];

void saveState(int stateNumber) {
    char savePath[PATH_MAX_LENGTH];
    FILE * file;
    path_mkdir("./tests");
    size_t size=retro_serialize_size();
    snprintf(savePath, sizeof(savePath), "./tests/state%d.mem", stateNumber);
    
    file=fopen(savePath, "wb");
    if (file!=NULL) {
        if (retro_serialize(data, size)) {
            log_info("saving %s\n",savePath);
            fwrite (data , 1, size, file);
            //hexDump (data, 100);

            snprintf(savePath, sizeof(savePath), "./tests/state%d.raw", stateNumber);
            FILE * file2=fopen(savePath, "wb");

            if (file2!=NULL) {
                fwrite (frame_buf , 1, HEIGHT*WIDTH*sizeof(uint32_t), file2);
                log_info("saved %s\n",savePath);
                fclose(file2);
            }
            
            snprintf(savePath, sizeof(savePath), "./tests/state%d.bmp", stateNumber);
            rbmp_save_image(savePath,
                                 frame_buf,
                                  WIDTH,  HEIGHT,
                                sizeof(*frame_buf)*WIDTH, RBMP_SOURCE_TYPE_XRGB888);
            
            
            
        } else {
            log_error("retro_serialize returned false\n");
        }
        fclose(file);
    } else {
        log_error("error filestream_open %s\n",savePath);
    }
}

void load_state(int stateNumber) {
    FILE * file;
    char loadPath[PATH_MAX_LENGTH];
    size_t size=retro_serialize_size();
    snprintf(loadPath, sizeof(loadPath), "./tests/state%d.mem", stateNumber);
    
    log_info("loading %s\n",loadPath);

    
    file=fopen(loadPath, "rb");
    
    if (file==NULL) {
        log_error("Error loading file %s\n",loadPath);
        return;
    }
    fread (data , 1, size, file);
    //hexDump (data, 100);
    
    if (retro_unserialize(data, size)!=true) {
            log_error("retro_unserialize returned false\n");
            exit(1);
    }
    fclose(file);
}

int
main(int argc, char **argv)
{
    size_t size=retro_serialize_size();
   // data=calloc(size+1,1);
    //char data[60000];

    
    
    frame_buf = calloc(WIDTH * HEIGHT, sizeof(uint32_t));
    int nb_window=NB_WINDOWS;
    int starting_window=0;
    log_cb=testLogging;
    
    
    
   log_error("alocated %d\n",size);

    
    if (argc<2) {
        log_error("args: <nb windows> <starting window>\n");
        return 0;
    }
    if (argc>=2) {
        nb_window = atoi(argv[1]);
    }
    if (argc>=3) {
        starting_window = atoi(argv[2]);
    }
    log_info("nb_window=%d starting_window=%d\n",nb_window, starting_window);
    
    
    
    mrboom_init("./");


    
    clock_t begin = clock();
    int nbFrames=starting_window*NB_FRAME_PER_WINDOW;
    
    if (starting_window) {
        log_info("x fps=%f loading at frame %d\n",nbFrames);
        load_state(starting_window-1);
    }
    
    begin = clock();
    do {
        int stateNumber=nbFrames/NB_FRAME_PER_WINDOW;
        
        m.CF=0;
        m.ZF=0;
        m.SF=0;
        m.DF=0;
        READDW(es)=2;
        READDW(cs)=0;
        READDW(ds)=0;
        READDW(fs)=1;
        READDW(gs)=0;
        READDD(eax)=0;
        READDD(ebx)=0;
        READDD(ecx)=0;
        READDD(edx)=0;
        READDD(esi)=0;
        READDD(edi)=0;
        READDD(ebp)=0;
        READDD(esp)=0;
        
        nbFrames++;
        program();
        update_vga(frame_buf,WIDTH);
        if (!(nbFrames%NB_FRAME_PER_WINDOW)) {
            if (mrboom_debug_state_failed()) {
                log_error("Error mrboom_debug_state\n");
                char savePath[PATH_MAX_LENGTH];
                snprintf(savePath, sizeof(savePath), "./tests/state%d.mem", stateNumber);
                unlink(savePath);
            } else {
                clock_t end = clock();
                double time_spent = (double)(end - begin) / CLOCKS_PER_SEC;
                log_info("x time_spent=%f \n",time_spent);
                log_info("x fps=%f saving at frame %d\n",nbFrames/time_spent,nbFrames);
                saveState(stateNumber);
            }
        }
    } while((m.executionFinished==0) && (nbFrames<=nb_window*NB_FRAME_PER_WINDOW));
    unlink("./test.lock");
}
