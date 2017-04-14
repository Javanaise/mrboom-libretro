#include "MrboomHelper.hpp"
#include "Bot.hpp"
#include "BotTree.hpp"

class ConditionNode : public bt::Node
{
public:
ConditionNode(std::function<bool ()> f) : Node(),  f(f) {
}
void Initialize() override
{
}
Status Update() override
{
	if (f())
		return Node::Status::Success;
   return Node::Status::Failure;
}
private:
std::function<bool ()> f;
};

class MoveToNode : public bt::Node
{
   public:
      MoveToNode(Bot * bot,std::function<int ()> f) : Node(), bot(bot), f(f) { }
      void Initialize() override { }

      Status Update() override
      {
         int cell=f();
         if (cell==-1)
            return Node::Status::Failure;

         if (bot->getCurrentCell()!=cell)
         {
            if (bot->walkToCell(cell))
               return Node::Status::Running;
            return Node::Status::Failure;
         }

         return Node::Status::Success;
      }
   private:
      Bot * bot;
      std::function<int ()> f;
};

static bool traceLeaves = false;

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

   auto bombLeft = std::make_shared<ConditionNode>([this]() {
         // condition "i have more bombs"
         int howManyBombs=this->howManyBombsLeft();
         if (traceLeaves) log_debug("%d/%d:bombLeft:%d\n",frameNumber(),this->_playerIndex,howManyBombs);
         return (howManyBombs);
         });


   bombSeq->AddChild(bombLeft);
   auto gotoBestBombCell = std::make_shared<MoveToNode>(this, [this]() {
         // leaf: "move to the best place to Drop a bomb"
         int bestCell=this->bestCellToDropABomb();
         if (traceLeaves) log_debug("%d/%d:goBestBombCell:%d current=%d\n",frameNumber(),this->_playerIndex,bestCell,this->getCurrentCell());
         return bestCell;
         });
   bombSeq->AddChild(gotoBestBombCell);
   auto dropBomb = std::make_shared<ConditionNode>([this]() {
         if (isSomewhatInTheMiddleOfCell()) { // done to avoid to drop another bomb when leaving the cell.
         this->startPushingBombDropButton();
         }
         if (traceLeaves) log_debug("%d/%d:dropBomb\n",frameNumber(),this->_playerIndex);
         return true;
         });
   bombSeq->AddChild(dropBomb);

   auto gotoSafePlace = std::make_shared<MoveToNode>(this, [this]()
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
