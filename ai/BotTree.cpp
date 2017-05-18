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

	if (((!(bot->isInMiddleOfCell() && bot->getCurrentCell()==cell))) || (bot->getCurrentCell()!=cell))
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
	//if (bot->isSomewhatInTheMiddleOfCell()) {         // done to avoid to drop another bomb when leaving the cell.
	bot->startPushingBombDropButton();                 //TOFIX ? return false or running ?
	//}
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

void BotTree::Update()
{
	updateFlameAndDangerGrids(_playerIndex,flameGrid,dangerGrid);
	updateTravelGrid(_playerIndex,travelGrid,flameGrid);

	//  do not update too often to avoid some rapid quivering between 2 players
	if (!((frameNumber()+_playerIndex*3)%24))
	{
		updateBestExplosionGrid(_playerIndex,bestExplosionsGrid,travelGrid,flameGrid,dangerGrid);
	}
	stopPushingRemoteButton();
	stopPushingBombDropButton();
	stopPushingJumpButton();
	//if (isInMiddleOfCell())
	//

	tree->Update();
	if (amISafe() && (pushingDropBombButton==false) && (isSomewhatInTheMiddleOfCell()))
		this->startPushingRemoteButton();
}

// filled by serialize...
static size_t serializeSize=0;

size_t BotTree::serialize_size(void) {
	if(serializeSize==0) {
		uint8_t tmpBuffer[MEM_STREAM_BUFFER_SIZE];
		serialize(tmpBuffer);
		log_debug("HARDCODED_RETRO_SERIALIZE_SIZE=SIZE_SER+%d*8\n",serializeSize);
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
	if (is_little_endian()==false) {
		uint32_t bestExplosionsGridSave[grid_size_x][grid_size_y];
		memcpy(bestExplosionsGridSave, bestExplosionsGrid,  sizeof(bestExplosionsGridSave));
		for (int j=0; j<grid_size_y; j++) {
			for (int i=0; i<grid_size_x; i++) {
				bestExplosionsGridSave[i][j]=SWAP32(bestExplosionsGridSave[i][j]);
			}
		}
		memstream_write(stream, bestExplosionsGridSave, sizeof(bestExplosionsGridSave)); // write to the stream
	} else {
		memstream_write(stream, bestExplosionsGrid, sizeof(bestExplosionsGrid)); // write to the stream
	}
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
	memstream_read(stream, bestExplosionsGrid, sizeof(bestExplosionsGrid)); // read from the stream
	if (is_little_endian()==false) {
		for (int j=0; j<grid_size_y; j++) {
			for (int i=0; i<grid_size_x; i++) {
				bestExplosionsGrid[i][j]=SWAP32(bestExplosionsGrid[i][j]);
			}
		}
	}
	return true;
}

