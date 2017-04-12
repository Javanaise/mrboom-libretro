#include "bt.hpp"
#include "Bot.hpp"
class BotTree : public Bot {
public:
BotTree(int playerIndex);
void Update();
private:
bt::BehaviorTree * tree;
};
