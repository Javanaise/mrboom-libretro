#include "MrboomHelper.hpp"
#include "Bot.hpp"
#include "BotTree.hpp"

class ConditionNode : public bt::Node
{
public:
ConditionNode(std::function<bool ()> f) : Node(),  f(f) {
}
void Initialize() { }

bt::Status Update()
{
	if (f())
		return bt::Status::Success;
	return bt::Status::Failure;
}

private:
std::function<bool ()> f;
};

class MoveToNode : public bt::Node
{
public:
MoveToNode(Bot * bot,std::function<int ()> f) : Node(), bot(bot), f(f) {
}
void Initialize() {
}

bt::Status Update()
{
	int cell=f();
	if (cell==-1)
		return bt::Status::Failure;

	if (bot->getCurrentCell()!=cell)
	{
		if (bot->walkToCell(cell))
			return bt::Status::Running;
		return bt::Status::Failure;
	}

	return bt::Status::Success;
}
private:
Bot * bot;
std::function<int ()> f;
};

static bool traceLeaves = false;

#if 0
template<typename T> void showtype(T foo);
#endif

BotTree::BotTree(int playerIndex) : Bot(playerIndex)
{
	tree = new bt::BehaviorTree();

	std::shared_ptr<MoveToNode> gotoBonus = std::make_shared<MoveToNode>(this, [this]() {
		// leaf: "move to the best bonus cell"
		int bestCell=this->bestBonusCell();
		if (traceLeaves) log_debug("%d/%d:gotoBonus:%d current=%d\n",frameNumber(),this->_playerIndex,bestCell,this->getCurrentCell());
		return bestCell;
	});


	std::shared_ptr<bt::Sequence> bombSeq = bt::MakeSequence();

	std::shared_ptr<ConditionNode> bombLeft = std::make_shared<ConditionNode>([this]() {
		// condition "i have more bombs"
		int howManyBombs=this->howManyBombsLeft();
		if (traceLeaves) log_debug("%d/%d:bombLeft:%d\n",frameNumber(),this->_playerIndex,howManyBombs);
		return (howManyBombs);
	});

	bombSeq->AddChild(bombLeft);
	std::shared_ptr<MoveToNode> gotoBestBombCell = std::make_shared<MoveToNode>(this, [this]() {
		// leaf: "move to the best place to Drop a bomb"
		int bestCell=this->bestCellToDropABomb();
		if (traceLeaves) log_debug("%d/%d:goBestBombCell:%d current=%d\n",frameNumber(),this->_playerIndex,bestCell,this->getCurrentCell());
		return bestCell;
	});
	bombSeq->AddChild(gotoBestBombCell);

	std::shared_ptr<ConditionNode> dropBomb = std::make_shared<ConditionNode>([this]() {
		if (isSomewhatInTheMiddleOfCell()) { // done to avoid to drop another bomb when leaving the cell.
		        this->startPushingBombDropButton();
		}
		if (traceLeaves) log_debug("%d/%d:dropBomb\n",frameNumber(),this->_playerIndex);
		return true;
	});
	bombSeq->AddChild(dropBomb);

	std::shared_ptr<MoveToNode> gotoSafePlace = std::make_shared<MoveToNode>(this, [this]()
	{
		int bestCell=this->bestSafeCell();
		if (traceLeaves) log_debug("%d/%d l22: goto bestSafeCell:%d current=%d\n",frameNumber(),this->_playerIndex,bestCell,this->getCurrentCell());
		return bestCell;
	});

	std::shared_ptr<bt::Selector> rootNode = std::make_shared<bt::Selector>();

	rootNode->AddChild(gotoBonus);
	rootNode->AddChild(bombSeq);
	rootNode->AddChild(gotoSafePlace);
	tree->SetRoot(rootNode);
}

void BotTree::Update()
{
	updateFlameAndDangerGrids(_playerIndex,flameGrid,dangerGrid);
	updateTravelGrid(_playerIndex,travelCostGrid,flameGrid);
	updateBestExplosionGrid(_playerIndex,bestExplosionsGrid,travelCostGrid,flameGrid,dangerGrid);
	stopPushingRemoteButton();
	stopPushingBombDropButton();

	if (isInMiddleOfCell())
		stopWalking();

	tree->Update();
	if (amISafe() && (pushingDropBombButton==false) && isSomewhatInTheMiddleOfCell())
		this->startPushingRemoteButton();
}
