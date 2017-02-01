/* ioapi_buf.h -- IO base function header for compress/uncompress .zip
   files using zlib + zip or unzip API

   This version of ioapi is designed to buffer IO.

   Copyright (C) 1998-2003 Gilles Vollant
             (C) 2012-2014 Nathan Moinvaziri

   This program is distributed under the terms of the same license as zlib.
   See the accompanying LICENSE file for the full text of the license.
*/


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

#if defined(_WIN32)
#include <conio.h>
#endif

#include <retro_miscellaneous.h>

#include "zlib.h"
#include "ioapi.h"

#include "ioapi_buf.h"

typedef struct ourstream_s {
  char readBuffer[IOBUF_BUFFERSIZE];
  uInt readBufferLength;
  uInt readBufferPos;
  uInt readBufferHits;
  uInt readBufferMisses;
  char writeBuffer[IOBUF_BUFFERSIZE];
  uInt writeBufferLength;
  uInt writeBufferPos;
  uInt writeBufferHits;
  uInt writeBufferMisses;
  ZPOS64_T position;
  voidpf stream;
} ourstream_t;

void print_buf_internal(voidpf opaque, voidpf stream, char *format, ...)
{
    va_list arglist;
    ourstream_t *streamio = (ourstream_t *)stream;

    va_start(arglist, format);
#ifdef _WIN32
    _vcprintf(format, arglist);
#else
    vprintf(format, arglist);
#endif
    va_end(arglist);
}

voidpf fopen_buf_internal_func (opaque, stream, number_disk, mode)
   voidpf opaque;
   voidpf stream;
   int number_disk;
   int mode;
{
    ourstream_t *streamio = NULL;
    if (stream == NULL)
        return NULL;
    streamio = (ourstream_t *)malloc(sizeof(ourstream_t));
    if (streamio == NULL)
        return NULL;
    memset(streamio, 0, sizeof(ourstream_t));
    streamio->stream = stream;
    return streamio;
}

voidpf ZCALLBACK fopen_buf_func (opaque, filename, mode)
   voidpf opaque;
   const char* filename;
   int mode;
{
    ourbuffer_t *bufio = (ourbuffer_t *)opaque;
    voidpf stream = bufio->filefunc.zopen_file(bufio->filefunc.opaque, filename, mode);
    return fopen_buf_internal_func(opaque, stream, 0, mode);
}

voidpf ZCALLBACK fopen64_buf_func (opaque, filename, mode)
   voidpf opaque;
   const char* filename;
   int mode;
{
    ourbuffer_t *bufio = (ourbuffer_t *)opaque;
    voidpf stream = bufio->filefunc64.zopen64_file(bufio->filefunc64.opaque, filename, mode);
    return fopen_buf_internal_func(opaque, stream, 0, mode);
}

voidpf ZCALLBACK fopendisk_buf_func (opaque, stream_cd, number_disk, mode)
   voidpf opaque;
   voidpf stream_cd;
   int number_disk;
   int mode;
{
    ourbuffer_t *bufio = (ourbuffer_t *)opaque;
    ourstream_t *streamio = (ourstream_t *)stream_cd;
    voidpf *stream = bufio->filefunc.zopendisk_file(bufio->filefunc.opaque, streamio->stream, number_disk, mode);
    return fopen_buf_internal_func(opaque, stream, number_disk, mode);
}

voidpf ZCALLBACK fopendisk64_buf_func (opaque, stream_cd, number_disk, mode)
   voidpf opaque;
   voidpf stream_cd;
   int number_disk;
   int mode;
{
    ourbuffer_t *bufio = (ourbuffer_t *)opaque;
    ourstream_t *streamio = (ourstream_t *)stream_cd;
    voidpf stream = bufio->filefunc64.zopendisk64_file(bufio->filefunc64.opaque, streamio->stream, number_disk, mode);
    return fopen_buf_internal_func(opaque, stream, number_disk, mode);
}

long fflush_buf OF((voidpf opaque, voidpf stream));
long fflush_buf (opaque, stream)
   voidpf opaque;
   voidpf stream;
{
    ourbuffer_t *bufio = (ourbuffer_t *)opaque;
    ourstream_t *streamio = (ourstream_t *)stream;
    uInt totalBytesWritten = 0;
    uInt bytesToWrite = streamio->writeBufferLength;
    uInt bytesLeftToWrite = streamio->writeBufferLength;
    long bytesWritten = 0;
    
    while (bytesLeftToWrite > 0)
    {
        if (bufio->filefunc64.zwrite_file != NULL)
            bytesWritten = bufio->filefunc64.zwrite_file(bufio->filefunc64.opaque, streamio->stream, streamio->writeBuffer + (bytesToWrite - bytesLeftToWrite), bytesLeftToWrite);
        else
            bytesWritten = bufio->filefunc.zwrite_file(bufio->filefunc.opaque, streamio->stream, streamio->writeBuffer + (bytesToWrite - bytesLeftToWrite), bytesLeftToWrite);

        streamio->writeBufferMisses += 1;

        if (bytesWritten < 0)
            return bytesWritten;

        totalBytesWritten += bytesWritten;
        bytesLeftToWrite -= bytesWritten;
        streamio->position += bytesWritten;
    }
    streamio->writeBufferLength = 0;
    streamio->writeBufferPos = 0;
    return totalBytesWritten;
}

uLong ZCALLBACK fread_buf_func (opaque, stream, buf, size)
   voidpf opaque;
   voidpf stream;
   void* buf;
   uLong size;
{
    ourbuffer_t *bufio = (ourbuffer_t *)opaque;
    ourstream_t *streamio = (ourstream_t *)stream;
    uLong bytesToRead = 0;
    uLong bufLength = 0;
    uLong bytesToCopy = 0;
    uLong bytesLeftToRead = size;
    uLong bytesRead = -1;

    while (bytesLeftToRead > 0)
    {
        if ((streamio->readBufferLength == 0) || (streamio->readBufferPos == streamio->readBufferLength))
        {
            if (streamio->readBufferLength == IOBUF_BUFFERSIZE)
            {
                streamio->readBufferPos = 0;
                streamio->readBufferLength = 0;
            }

            bytesToRead = IOBUF_BUFFERSIZE -(streamio->readBufferLength - streamio->readBufferPos);

            if (bufio->filefunc64.zread_file != NULL)
                bytesRead = bufio->filefunc64.zread_file(bufio->filefunc64.opaque, streamio->stream, streamio->readBuffer + streamio->readBufferPos, bytesToRead);
            else
                bytesRead = bufio->filefunc.zread_file(bufio->filefunc.opaque, streamio->stream, streamio->readBuffer + streamio->readBufferPos, bytesToRead);

            streamio->readBufferMisses += 1;
            streamio->readBufferLength += bytesRead;
            streamio->position += bytesRead;

            if (bytesRead == 0)
                break;
        }

        if ((streamio->readBufferLength - streamio->readBufferPos) > 0)
        {
            bytesToCopy = MIN(bytesLeftToRead, (uLong)(streamio->readBufferLength - streamio->readBufferPos));
            memcpy((char *)buf + bufLength, streamio->readBuffer + streamio->readBufferPos, bytesToCopy);

            bufLength += bytesToCopy;
            bytesLeftToRead -= bytesToCopy;

            streamio->readBufferHits += 1;
            streamio->readBufferPos += bytesToCopy;
        }
    }

    return size - bytesLeftToRead;
}

uLong ZCALLBACK fwrite_buf_func (opaque, stream, buf, size)
   voidpf opaque;
   voidpf stream;
   const void* buf;
   uLong size;
{
    ourbuffer_t *bufio = (ourbuffer_t *)opaque;
    ourstream_t *streamio = (ourstream_t *)stream;
    uLong bytesToWrite = size;
    uLong bytesLeftToWrite = size;
    uLong bytesToCopy = 0;
    uLong retVal = 0;

    if (streamio->readBufferLength > 0)
    {
        streamio->position -= streamio->readBufferLength;
        streamio->position += streamio->readBufferPos;

        streamio->readBufferLength = 0;
        streamio->readBufferPos = 0;

        if (bufio->filefunc64.zseek64_file != NULL)
            retVal = bufio->filefunc64.zseek64_file(bufio->filefunc64.opaque, streamio->stream, streamio->position, ZLIB_FILEFUNC_SEEK_SET);
        else
            retVal = bufio->filefunc.zseek_file(bufio->filefunc.opaque, streamio->stream, (uLong)streamio->position, ZLIB_FILEFUNC_SEEK_SET);

        if (retVal != 0)
            return -1;
    }

    while (bytesLeftToWrite > 0)
    {
        bytesToCopy = MIN(bytesLeftToWrite, (uLong)(IOBUF_BUFFERSIZE - MIN(streamio->writeBufferLength, streamio->writeBufferPos)));

        if (bytesToCopy == 0)
        {
            if (fflush_buf(opaque, stream) <= 0)
                return 0;

            continue;
        }
        
        memcpy(streamio->writeBuffer + streamio->writeBufferPos, (char *)buf + (bytesToWrite - bytesLeftToWrite), bytesToCopy);

        bytesLeftToWrite -= bytesToCopy;

        streamio->writeBufferPos += bytesToCopy;
        streamio->writeBufferHits += 1;
        if (streamio->writeBufferPos > streamio->writeBufferLength)
            streamio->writeBufferLength += streamio->writeBufferPos - streamio->writeBufferLength;
    }

    return size - bytesLeftToWrite;
}

ZPOS64_T ftell_buf_internal_func (opaque, stream, position)
   voidpf opaque;
   voidpf stream;
   ZPOS64_T position;
{
    ourstream_t *streamio = (ourstream_t *)stream;
    streamio->position = position;
    if (streamio->readBufferLength > 0)
        position -= (streamio->readBufferLength - streamio->readBufferPos);
    if (streamio->writeBufferLength > 0)
        position += streamio->writeBufferPos;
    return position;
}

long ZCALLBACK ftell_buf_func (opaque, stream)
   voidpf opaque;
   voidpf stream;
{
    ourbuffer_t *bufio = (ourbuffer_t *)opaque;
    ourstream_t *streamio = (ourstream_t *)stream;
    ZPOS64_T position = bufio->filefunc.ztell_file(bufio->filefunc.opaque, streamio->stream);
    return (long)ftell_buf_internal_func(opaque, stream, position);
}

ZPOS64_T ZCALLBACK ftell64_buf_func (opaque, stream)
   voidpf opaque;
   voidpf stream;
{
    ourbuffer_t *bufio = (ourbuffer_t *)opaque;
    ourstream_t *streamio = (ourstream_t *)stream;
    ZPOS64_T position = bufio->filefunc64.ztell64_file(bufio->filefunc64.opaque, streamio->stream);
    return ftell_buf_internal_func(opaque, stream, position);
}

int fseek_buf_internal_func (opaque, stream, offset, origin)
   voidpf opaque;
   voidpf stream;
   ZPOS64_T offset;
   int origin;
{
    ourstream_t *streamio = (ourstream_t *)stream;

    switch (origin)
    {
        case ZLIB_FILEFUNC_SEEK_SET:

            if (streamio->writeBufferLength > 0)
            {
                if ((offset >= streamio->position) && (offset <= streamio->position + streamio->writeBufferLength))
                {
                    streamio->writeBufferPos = (uInt)(offset - streamio->position);
                    return 0;
                }
            }
            if ((streamio->readBufferLength > 0) && (offset < streamio->position) && (offset >= streamio->position - streamio->readBufferLength))
            {
                streamio->readBufferPos = (uInt)(offset - (streamio->position - streamio->readBufferLength));
                return 0;
            }
            if (fflush_buf(opaque, stream) < 0)
                return -1;
            streamio->position = offset;
            break;

        case ZLIB_FILEFUNC_SEEK_CUR:

            if (streamio->readBufferLength > 0)
            {
                if (offset <= (streamio->readBufferLength - streamio->readBufferPos))
                {
                    streamio->readBufferPos += (uLong)offset;
                    return 0;
                } 
                offset -= (streamio->readBufferLength - streamio->readBufferPos);
                streamio->position += offset;
            }
            if (streamio->writeBufferLength > 0)
            {
                if (offset <= (streamio->writeBufferLength - streamio->writeBufferPos))
                {
                    streamio->writeBufferPos += (uLong)offset;
                    return 0;
                }
                offset -= (streamio->writeBufferLength - streamio->writeBufferPos);
            }

            if (fflush_buf(opaque, stream) < 0)
                return -1;

            break;

        case ZLIB_FILEFUNC_SEEK_END:

            if (streamio->writeBufferLength > 0)
            {
                streamio->writeBufferPos = streamio->writeBufferLength;
                return 0;
            }
            break;
    }

    streamio->readBufferLength = 0;
    streamio->readBufferPos = 0;
    streamio->writeBufferLength = 0;
    streamio->writeBufferPos = 0;
    return 1;
}

long ZCALLBACK fseek_buf_func (opaque, stream, offset, origin)
   voidpf opaque;
   voidpf stream;
   uLong offset;
   int origin;
{
    ourbuffer_t *bufio = (ourbuffer_t *)opaque;
    ourstream_t *streamio = (ourstream_t *)stream;
    long retVal = -1;
    if (bufio->filefunc.zseek_file == NULL)
        return retVal;
    retVal = fseek_buf_internal_func(opaque, stream, offset, origin);
    if (retVal == 1)
        retVal = bufio->filefunc.zseek_file(bufio->filefunc.opaque, streamio->stream, offset, origin);
    return retVal;
}

long ZCALLBACK fseek64_buf_func (opaque, stream, offset, origin)
   voidpf opaque;
   voidpf stream;
   ZPOS64_T offset;
   int origin;
{
    ourbuffer_t *bufio = (ourbuffer_t *)opaque;
    ourstream_t *streamio = (ourstream_t *)stream;
    long retVal = -1;
    if (bufio->filefunc64.zseek64_file == NULL)
        return retVal;
    retVal = fseek_buf_internal_func(opaque, stream, offset, origin);
    if (retVal == 1)
        retVal = bufio->filefunc64.zseek64_file(bufio->filefunc64.opaque, streamio->stream, offset, origin);
    return retVal;
}

int ZCALLBACK fclose_buf_func (opaque, stream)
   voidpf opaque;
   voidpf stream;
{
    ourbuffer_t *bufio = (ourbuffer_t *)opaque;
    ourstream_t *streamio = (ourstream_t *)stream;
    int retVal = 0;
    fflush_buf(opaque, stream);
    if (bufio->filefunc64.zclose_file != NULL)
        retVal = bufio->filefunc64.zclose_file(bufio->filefunc64.opaque, streamio->stream);
    else 
        retVal = bufio->filefunc.zclose_file(bufio->filefunc.opaque, streamio->stream);
    free(streamio);
    return retVal;
}

int ZCALLBACK ferror_buf_func (opaque, stream)
   voidpf opaque;
   voidpf stream;
{
    ourbuffer_t *bufio = (ourbuffer_t *)opaque;
    ourstream_t *streamio = (ourstream_t *)stream;
    if (bufio->filefunc64.zerror_file != NULL)
        return bufio->filefunc64.zerror_file(bufio->filefunc64.opaque, streamio->stream);
    return bufio->filefunc.zerror_file(bufio->filefunc.opaque, streamio->stream);
}


void fill_buffer_filefunc (pzlib_filefunc_def, ourbuf)
   zlib_filefunc_def* pzlib_filefunc_def;
   ourbuffer_t *ourbuf;
{
    pzlib_filefunc_def->zopen_file = fopen_buf_func;
    pzlib_filefunc_def->zopendisk_file = fopendisk_buf_func;
    pzlib_filefunc_def->zread_file = fread_buf_func;
    pzlib_filefunc_def->zwrite_file = fwrite_buf_func;
    pzlib_filefunc_def->ztell_file = ftell_buf_func;
    pzlib_filefunc_def->zseek_file = fseek_buf_func;
    pzlib_filefunc_def->zclose_file = fclose_buf_func;
    pzlib_filefunc_def->zerror_file = ferror_buf_func;
    pzlib_filefunc_def->opaque = ourbuf;
}

void fill_buffer_filefunc64 (pzlib_filefunc_def, ourbuf)
   zlib_filefunc64_def* pzlib_filefunc_def;
   ourbuffer_t *ourbuf;
{
    pzlib_filefunc_def->zopen64_file = fopen64_buf_func;
    pzlib_filefunc_def->zopendisk64_file = fopendisk64_buf_func;
    pzlib_filefunc_def->zread_file = fread_buf_func;
    pzlib_filefunc_def->zwrite_file = fwrite_buf_func;
    pzlib_filefunc_def->ztell64_file = ftell64_buf_func;
    pzlib_filefunc_def->zseek64_file = fseek64_buf_func;
    pzlib_filefunc_def->zclose_file = fclose_buf_func;
    pzlib_filefunc_def->zerror_file = ferror_buf_func;
    pzlib_filefunc_def->opaque = ourbuf;
}
