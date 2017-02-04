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
static void * data=NULL;

void saveState(int stateNumber) {
    char savePath[PATH_MAX_LENGTH];
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
            }
             */
        } else {
            log_error("retro_serialize returned false\n");
        }
        filestream_close(file);
    } else {
        log_error("error filestream_open %s\n",savePath);
    }
}

void load_state(int stateNumber) {
    RFILE * file;
    char loadPath[PATH_MAX_LENGTH];
    size_t size=retro_serialize_size();
    snprintf(loadPath, sizeof(loadPath), "./tests/state%d.mem", stateNumber);
    //bool retro_unserialize(const void *data_, size_t size)
    file = filestream_open(loadPath, RFILE_MODE_READ, 0);
    if (file==NULL) {
        log_error("Error loading file %s\n",loadPath);
        return;
    }
    filestream_seek(file, 0, SEEK_END);
    ssize_t sizeFile=filestream_tell(file);
    filestream_seek(file, 0, SEEK_SET);
    log_info("File %s size=%d\n",loadPath,sizeFile);
    if (size!=sizeFile) {
        log_error("Size of %s is different from current retro_serialize_size() %d/%d\n",
        loadPath,sizeFile,size);
    }
    ssize_t readSize=filestream_read(file, data, size);
    if (readSize!=size) {
        log_error("Read only %d\n",readSize);
    }
    filestream_close(file);
    if (retro_unserialize(data, readSize)!=true) {
        log_error("retro_unserialize returned false\n");
    }
}

int
main(int argc, char **argv)
{
    frame_buf = calloc(WIDTH * HEIGHT, sizeof(uint32_t));
    size_t size=retro_serialize_size();    
    data=calloc(size,1);
    int nb_window=NB_WINDOWS;
    int starting_window=0;
    log_cb=testLogging;
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
    log_info("nb_window=%d starting_window=%d size=%d\n",nb_window, starting_window,size);
    
    mrboom_init("./");
    
    if (starting_window) {
        load_state(starting_window);
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
