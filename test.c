#include "mrboom.h"
#include "common.h"
#include <time.h>
#define NB_FRAME_PER_WINDOW 100
#define NB_WINDOWS 10

extern Memory m;
extern retro_log_printf_t log_cb;

void testLogging(enum retro_log_level level, const char *fmt, ...) {
    va_list args;
    char buf[1000];
    va_start(args, fmt);
    vsnprintf(buf, sizeof(buf), fmt, args );
    va_end(args);
    printf("%s",buf);
}

int
main(int argc, char **argv)
{
    log_cb=testLogging;
    size_t sizeSaveState=retro_get_memory_size(0);
    log_info("sizeSaveState=%d\n",sizeSaveState);
    mrboom_init("./");
    clock_t begin = clock();
    int nbFrames=0;
    do {
        program();
        nbFrames++;
        if (!(nbFrames%NB_FRAME_PER_WINDOW)) {
            clock_t end = clock();
            double time_spent = (double)(end - begin) / CLOCKS_PER_SEC;
            log_info("time_spent=%f %d\n",time_spent,nbFrames);
            log_info("fps=%f\n",nbFrames/time_spent);
        }
    } while(m.executionFinished==0);
}
