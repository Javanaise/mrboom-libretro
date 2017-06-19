#include "bt.hpp"
#include "Bot.hpp"
#define MEM_STREAM_BUFFER_SIZE 64000
class BotTree : public Bot {
public:
BotTree(int playerIndex);
size_t serialize_size(void);
bool serialize(void *data_);
bool unserialize(const void *data_);
void updateGrids();
void tick();
private:
bt::BehaviorTree * tree;
uint8_t buffer[MEM_STREAM_BUFFER_SIZE];
};
