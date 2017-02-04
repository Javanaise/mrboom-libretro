#include "mrboom.h"
#include "common.h"
#include "retro.h"
#include "streams/file_stream.h"
#include "file/file_path.h"
#include "formats/rpng.h"
#include <time.h>

#define NB_FRAME_PER_WINDOW 1000
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
static char data[100000];

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

            snprintf(savePath, sizeof(savePath), "./tests/state%d.png", stateNumber);
            /*
            if (rpng_save_image_argb(savePath, frame_buf, WIDTH, HEIGHT, WIDTH*sizeof(uint32_t))) {
                log_info("saved %s\n",savePath);
            } else {
                log_error("rpng_save_image_argb failed on %s\n",savePath);
            }
             */
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
    asm2C_printOffsets(offsetof(struct Mem,FIRST_VARIABLE));

    mrboom_init("./");

    if (starting_window) {
        load_state(starting_window-1);
    }
    
    clock_t begin = clock();
    int nbFrames=starting_window*NB_FRAME_PER_WINDOW;
    begin = clock();
    do {
        int stateNumber=nbFrames/NB_FRAME_PER_WINDOW;
        program();
        update_vga(frame_buf,WIDTH);
        nbFrames++;
        if (!(nbFrames%NB_FRAME_PER_WINDOW)) {
            clock_t end = clock();
            double time_spent = (double)(end - begin) / CLOCKS_PER_SEC;
            log_info("x time_spent=%f %d\n",time_spent,nbFrames);
            log_info("x fps=%f\n",nbFrames/time_spent);
            saveState(stateNumber);
        }
    } while((m.executionFinished==0) && (nbFrames<=nb_window*NB_FRAME_PER_WINDOW));
    unlink("./test.lock");
}
