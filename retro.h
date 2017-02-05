#ifndef RETRO_H__
#define RETRO_H__



void update_vga(uint32_t *buf, unsigned stride);
void show_message(char * show_message);
size_t retro_serialize_size(void);
bool retro_serialize(void *data_, size_t size);
bool retro_unserialize(const void *data_, size_t size);

#endif
