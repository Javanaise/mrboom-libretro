#ifndef RETRO_H__
#define RETRO_H__
#ifdef __cplusplus
extern "C" {
#endif
#define SIZE_MEM_MAX    30000
void update_vga(uint32_t *buf, unsigned stride);
void show_message(const char *show_message);
size_t retro_serialize_size(void);
bool retro_serialize(void *data_, size_t size);
bool retro_unserialize(const void *data_, size_t size);

#ifdef __cplusplus
}
#endif
#endif
