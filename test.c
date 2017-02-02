#include "mrboom.h"
#include "common.h"
#include "retro.h"
#include "streams/file_stream.h"
#include "file/file_path.h"
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


void saveState() {
    char savePath[PATH_MAX_LENGTH];
    static void * data=NULL;
    static int stateNumber=0;
    RFILE * file;
    path_mkdir("./tests");
    size_t size=retro_serialize_size();
    if (data==NULL) data=calloc(size,1);
    snprintf(savePath, sizeof(savePath), "./tests/state%d.mem", stateNumber);
    file = filestream_open(savePath, RFILE_MODE_WRITE, size);
    if (file!=NULL) {
        if (retro_serialize(data, size)) {
            log_info("saving %s\n",savePath);
            filestream_write(file, data, size);
            snprintf(savePath, sizeof(savePath), "./tests/state%d.png", stateNumber);
            assert(frame_buf!=NULL);
            /*
            if (rpng_save_image_argb(savePath, frame_buf, WIDTH, HEIGHT, WIDTH*sizeof(uint32_t))) {
                log_info("saved %s\n",savePath);
            } else {
                log_error("rpng_save_image_argb failed on %s\n",savePath);
            }*/
        } else {
            log_error("retro_serialize returned false\n");
        }
        filestream_close(file);
    } else {
        log_error("error filestream_open %s\n",savePath);
    }
    stateNumber++;
}


int
main(int argc, char **argv)
{
    frame_buf = calloc(WIDTH * HEIGHT, sizeof(uint32_t));
    log_cb=testLogging;
    mrboom_init("./");
    clock_t begin = clock();
    int nbFrames=0;
    begin = clock();
    do {
        program();
        update_vga(frame_buf,WIDTH);
        nbFrames++;
        if (!(nbFrames%NB_FRAME_PER_WINDOW)) {
            clock_t end = clock();
            double time_spent = (double)(end - begin) / CLOCKS_PER_SEC;
            log_info("x time_spent=%f %d\n",time_spent,nbFrames);
            log_info("x fps=%f\n",nbFrames/time_spent);
            saveState();
        }
    } while((m.executionFinished==0) && (nbFrames<=NB_WINDOWS*NB_FRAME_PER_WINDOW));
}
