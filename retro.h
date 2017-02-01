#ifndef RETRO_H__
#define RETRO_H__

void show_message(char * show_message);
size_t retro_get_memory_size(unsigned id);
bool retro_serialize(void *data_, size_t size);
bool retro_unserialize(const void *data_, size_t size);

#endif
