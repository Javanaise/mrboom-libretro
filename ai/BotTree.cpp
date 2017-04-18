#include "MrboomHelper.hpp"
#include "Bot.hpp"
#include "BotTree.hpp"

class ConditionNode : public bt::Node
{
public:
ConditionNode(Bot * bot) : Node(), bot(bot) {
}
void Initialize() {
}
virtual bool Condition() = 0;
bt::Status Update()
{
	if (Condition())
		return bt::Success;
	return bt::Failure;
}
protected:
Bot * bot;
};

class MoveToNode : public bt::Node
{
public:
MoveToNode(Bot * bot) : Node(), bot(bot) {
}
void Initialize() {
}
virtual int Cell() = 0;
bt::Status Update()
{
	int cell=Cell();
	if (cell==-1)
		return bt::Failure;

	if (bot->getCurrentCell()!=cell)
	{
		if (bot->walkToCell(cell))
			return bt::Running;
		return bt::Failure;
	}

	return bt::Success;
}
protected:
Bot * bot;
};

class MoveToBonus : public MoveToNode
{
public:
MoveToBonus(Bot * bot) : MoveToNode(bot) {
}
int Cell() {
	int bestCell=bot->bestBonusCell();
	if (bot->traces) log_debug("%d/%d:gotoBonus:%d current=%d\n",frameNumber(),bot->_playerIndex,bestCell,bot->getCurrentCell());
	return bestCell;
}
};

class MoveToBombBestBombCell : public MoveToNode
{
public:
MoveToBombBestBombCell(Bot * bot) : MoveToNode(bot) {
}
int Cell() {
	int bestCell=bot->bestCellToDropABomb();
	if (bot->traces) log_debug("%d/%d:goBestBombCell:%d current=%d\n",frameNumber(),bot->_playerIndex,bestCell,bot->getCurrentCell());
	return bestCell;
}
};

class MoveToSafeCell : public MoveToNode
{
public:
MoveToSafeCell(Bot * bot) : MoveToNode(bot) {
}
int Cell() {
	int bestCell=bot->bestSafeCell();
	if (bot->traces) log_debug("%d/%d l22: goto bestSafeCell:%d current=%d\n",frameNumber(),bot->_playerIndex,bestCell,bot->getCurrentCell());
	return bestCell;
}
};

class ConditionBombsLeft : public ConditionNode
{
public:
ConditionBombsLeft(Bot * bot) : ConditionNode(bot) {
}
bool Condition() {
	// condition "i have more bombs"
	int howManyBombs=bot->howManyBombsLeft();
	if (bot->traces) log_debug("%d/%d:bombLeft:%d\n",frameNumber(),bot->_playerIndex,howManyBombs);
	return (howManyBombs);
}

};

class ConditionDropBomb : public ConditionNode
{
public:
ConditionDropBomb(Bot * bot) : ConditionNode(bot) {
}
bool Condition() {
	if (bot->isSomewhatInTheMiddleOfCell()) {         // done to avoid to drop another bomb when leaving the cell.
		bot->startPushingBombDropButton();         //TOFIX ? return false or running ?
	}
	if (bot->traces) log_debug("%d/%d:dropBomb\n",frameNumber(),bot->_playerIndex);
	return true;
}

};


#if 0
template<typename T> void showtype(T foo);
#endif

BotTree::BotTree(int playerIndex) : Bot(playerIndex)
{
	tree = new bt::BehaviorTree();

	MoveToBonus * gotoBonus = new MoveToBonus(this);
	bt::Sequence * bombSeq = new bt::Sequence();

	ConditionBombsLeft * bombLeft = new ConditionBombsLeft(this);
	bombSeq->AddChild(bombLeft);

	MoveToBombBestBombCell * gotoBestBombCell = new MoveToBombBestBombCell(this);
	bombSeq->AddChild(gotoBestBombCell);

	ConditionDropBomb * dropBomb = new ConditionDropBomb(this);
	bombSeq->AddChild(dropBomb);

	MoveToSafeCell * gotoSafePlace = new MoveToSafeCell(this);
	bt::Selector * rootNode = new bt::Selector();
	rootNode->AddChild(gotoBonus);
	rootNode->AddChild(bombSeq);
	rootNode->AddChild(gotoSafePlace);
	tree->SetRoot(rootNode);
}

void BotTree::Update()
{
	updateFlameAndDangerGrids(_playerIndex,flameGrid,dangerGrid);
	updateTravelGrid(_playerIndex,travelCostGrid,flameGrid);

	if (!((frameNumber())%(2*framesToCrossACell(_playerIndex)))) { // do not update too often to avoid some rapid quivering between 2 players
		updateBestExplosionGrid(_playerIndex,bestExplosionsGrid,travelCostGrid,flameGrid,dangerGrid);
	}
	stopPushingRemoteButton();
	stopPushingBombDropButton();

	if (isInMiddleOfCell())
		stopWalking();

	tree->Update();
	if (amISafe() && (pushingDropBombButton==false) && isSomewhatInTheMiddleOfCell())
		this->startPushingRemoteButton();
}
