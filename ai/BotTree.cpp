#include "MrboomHelper.hpp"
#include "Bot.hpp"
#include "BotTree.hpp"

#ifdef IOS
void std::__throw_out_of_range(char const*) {
}
#endif

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
	if (cell==-1) {
		if (isInMiddleOfCell(bot->_playerIndex)) {
			bot->stopWalking();
		}
		return bt::Failure;
	}

	if (((!(isInMiddleOfCell(bot->_playerIndex) && bot->getCurrentCell()==cell))) || (bot->getCurrentCell()!=cell))
	{
		if (bot->walkToCell(cell))
			return bt::Running;

		if (tracesDecisions(bot->_playerIndex)) log_debug("BOTTREEDECISIONS: %d/%d:Failed to go to %d (%d/%d)\n",frameNumber(),bot->_playerIndex,cell,CELLX(cell),CELLY(cell));
		return bt::Failure;
	}
	bot->stopWalking();
	if (tracesDecisions(bot->_playerIndex)) log_debug("BOTTREEDECISIONS: %d/%d:stopWalking arrived in %d (%d/%d)\n",frameNumber(),bot->_playerIndex,cell,CELLX(cell),CELLY(cell));
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
	if (tracesDecisions(bot->_playerIndex)) log_debug("BOTTREEDECISIONS: %d/%d:gotoBonus:%d (%d/%d) current=%d (%d/%d)\n",frameNumber(),bot->_playerIndex,bestCell,CELLX(bestCell),CELLY(bestCell),bot->getCurrentCell(),CELLX(bot->getCurrentCell()),CELLY(bot->getCurrentCell()));
	botStates[bot->_playerIndex]=goingBonus;
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
	botStates[bot->_playerIndex]=goingBomb;
	if (tracesDecisions(bot->_playerIndex)) log_debug("BOTTREEDECISIONS: %d/%d:gotoBestBombCell:%d (%d/%d) current=%d (%d/%d)\n",frameNumber(),bot->_playerIndex,bestCell,CELLX(bestCell),CELLY(bestCell),bot->getCurrentCell(),CELLX(bot->getCurrentCell()),CELLY(bot->getCurrentCell()));
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
	botStates[bot->_playerIndex]=goingSafe;
	if (tracesDecisions(bot->_playerIndex)) log_debug("BOTTREEDECISIONS: %d/%d:gotoBestSafeCell:%d (%d/%d) current=%d (%d/%d)\n",frameNumber(),bot->_playerIndex,bestCell,CELLX(bestCell),CELLY(bestCell),bot->getCurrentCell(),CELLX(bot->getCurrentCell()),CELLY(bot->getCurrentCell()));
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
	if (tracesDecisions(bot->_playerIndex)) log_debug("BOTTREEDECISIONS: %d/%d:bombLeft:%d\n",frameNumber(),bot->_playerIndex,howManyBombs);
	return (howManyBombs);
}

};

class ConditionDropBomb : public ConditionNode
{
public:
ConditionDropBomb(Bot * bot) : ConditionNode(bot) {
}
bool Condition() {
	bot->startPushingBombDropButton();                 //TOFIX ? return false or running ?
	if (tracesDecisions(bot->_playerIndex)) log_debug("BOTTREEDECISIONS: %d/%d:dropBomb\n",frameNumber(),bot->_playerIndex);
	return true;
}

};

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

void BotTree::updateGrids()
{
	updateFlameAndDangerGridsWithBombs(_playerIndex,flameGrid,dangerGrid);
	updateDangerGridWithMonstersSickPlayersAndCulDeSacs(_playerIndex,dangerGrid);
	updateDangerGridWithMonster4CellsTerritories(dangerGrid);
	updateMonsterIsComingGrid(monsterIsComingGrid);
	updateTravelGrid(_playerIndex,false,travelGrid,flameGrid,noDangerGrid);
	updateTravelGrid(_playerIndex,false,travelSafeGrid,flameGrid,dangerGrid);

#ifdef DEBUG
	printGrid();
#endif
	if (!((frameNumber()+_playerIndex)%nb_dyna))
	{
		calculatedBestCellToPickUpBonus=calculateBestCellToPickUpBonus();
	}
	updateBestExplosionGrid(_playerIndex,bestExplosionsGrid,travelGrid,flameGrid,dangerGrid);
}


void BotTree::tick() {
	stopPushingRemoteButton();
	stopPushingBombDropButton();
	stopPushingJumpButton();
	tree->Update();
	if (amISafe() && isSomewhatInTheMiddleOfCell() && frameNumber()%2 && pushingDropBombButton==false && ((howManyBombsHasPlayerLeft(_playerIndex)==0) || (botStates[_playerIndex]==goingSafe) || calculateScoreForActivatingRemote(_playerIndex) ||  someoneNotFromMyTeamAlive(_playerIndex)==false)) {
		this->startPushingRemoteButton();
	}
	if (monsterIsComingGrid[cellPlayer(_playerIndex)]) {
		startPushingBombDropButton();
	}
}

// filled by serialize...
static size_t serializeSize=0;

size_t BotTree::serialize_size(void) {
	if(serializeSize==0) {
		uint8_t tmpBuffer[MEM_STREAM_BUFFER_SIZE];
		serialize(tmpBuffer);
		log_error("HARDCODED_RETRO_SERIALIZE_SIZE=SIZE_SER+%d*8\n",serializeSize);
	}
	assert(serializeSize!=0);
	return serializeSize;
}
bool BotTree::serialize(void *data_) {
	memstream_set_buffer(buffer, MEM_STREAM_BUFFER_SIZE);
	static memstream_t * stream=memstream_open(1);
	assert(stream!=NULL);
	memstream_rewind(stream);
	assert(tree!=NULL);
	tree->serialize(stream); // write to the stream
	memstream_write(stream, &calculatedBestCellToPickUpBonus, sizeof(calculatedBestCellToPickUpBonus)); // write to the stream
	memstream_write(stream, &_direction1FrameAgo, sizeof(_direction1FrameAgo)); // write to the stream
	memstream_write(stream, &_direction2FramesAgo, sizeof(_direction2FramesAgo)); // write to the stream
	memstream_write(stream, &_shiveringCounter, sizeof(_shiveringCounter)); // write to the stream
	serializeSize=memstream_pos(stream);
	memstream_rewind(stream);
	memstream_read(stream, data_,serializeSize); // read from the stream
	return true;
}
bool BotTree::unserialize(const void *data_) {
	memstream_set_buffer(buffer, MEM_STREAM_BUFFER_SIZE);
	static memstream_t * stream=memstream_open(1);
	assert(stream!=NULL);
	memstream_rewind(stream);
	memstream_write(stream, data_, serialize_size()); // write to the stream
	memstream_rewind(stream);
	assert(tree!=NULL);
	tree->unserialize(stream);
	memstream_read(stream, &calculatedBestCellToPickUpBonus, sizeof(calculatedBestCellToPickUpBonus)); // read from the stream
	memstream_read(stream, &_direction1FrameAgo, sizeof(_direction1FrameAgo)); // write to the stream
	memstream_read(stream, &_direction2FramesAgo, sizeof(_direction2FramesAgo)); // write to the stream
	memstream_read(stream, &_shiveringCounter, sizeof(_shiveringCounter)); // write to the stream
	return true;
}

