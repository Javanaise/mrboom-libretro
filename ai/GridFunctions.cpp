#include <vector>
#include <algorithm>
#include <queue>
#include "GridFunctions.hpp"
#include "common.hpp"
#include "MrboomHelper.hpp"
#include <strings.h>

#define liste_bombe_size (247)

int playerGrid[NUMBER_OF_CELLS];
bool humanPlayer[NUMBER_OF_CELLS]; // is there an human player in a cell
int victoriesGrid[NUMBER_OF_CELLS]; // biggest number of victories for players in cell
int lastPlayerGridUpdate=0;

void inline updatePlayerGrid()
{
	if ((!lastPlayerGridUpdate) || (frameNumber()!=lastPlayerGridUpdate))
	{
		for (int i=0; i<NUMBER_OF_CELLS; i++) {
			playerGrid[i]=0;
			humanPlayer[i]=false;
			victoriesGrid[i]=0;
		}
		for (int i=0; i<numberOfPlayers(); i++)
		{
			if (isAlive(i))
			{
				int cell=cellPlayer(i);
				playerGrid[cell]=teamOfPlayer(i) | playerGrid[cell];
				if (!isAIActiveForPlayer(i)) {
					humanPlayer[cell]=true;
				}
				int v=victories(i);
				if (victoriesGrid[cell]<v) victoriesGrid[cell]=v;
			}
		}
		for (int i=numberOfPlayers(); i<nb_dyna; i++)
		{
			if (isAlive(i))
			{
				int cell=cellPlayer(i);
				playerGrid[cell]=monster | playerGrid[cell];
			}
		}
		lastPlayerGridUpdate=frameNumber();
	}
}

bool monsterInCell(int x,int y)
{
	updatePlayerGrid();
	return  (playerGrid[CELLINDEX(x,y)] & monster);
}

bool playerInCell(int x,int y)
{
	updatePlayerGrid();
	return  (playerGrid[CELLINDEX(x,y)] & (player_team1 | player_team2 | player_team3 | player_team4 | player_team5 | player_team6 | player_team7 | player_team8));
}

bool playerInCell(int player,int x,int y)
{
	int xp=xPlayer(player);
	int yp=yPlayer(player);
	return ((x==xp) && (y==yp));
}

bool playerNotFromMyTeamInCell(int player,int x,int y)
{
	updatePlayerGrid();
	int notMyTeamMask=(~teamOfPlayer(player)) & (~monster);
	return notMyTeamMask & playerGrid[CELLINDEX(x,y)];
}

bool enemyAroundCell(int player,const travelCostGrid& travelGrid,int x,int y) {
	updatePlayerGrid();
	if ((x>=grid_size_x-1) || (!x) || (y>=grid_size_y-1) || (!y)) return false;
	int notMyTeamMask=~teamOfPlayer(player);
	int cell=CELLINDEX(x,y);

	int closeMonsterMask=0;

	if (travelGrid.canWalk(cell)) {
		closeMonsterMask=closeMonsterMask | playerGrid[cell];
	}
	if (travelGrid.canWalk(cell+1)) {
		closeMonsterMask=closeMonsterMask | playerGrid[cell+1];
	}
	if (travelGrid.canWalk(cell-1)) {
		closeMonsterMask=closeMonsterMask | playerGrid[cell-1];
	}
	if (travelGrid.canWalk(cell-grid_size_x)) {
		closeMonsterMask=closeMonsterMask | playerGrid[cell-grid_size_x];
	}
	if (travelGrid.canWalk(cell-grid_size_x-1)) {
		closeMonsterMask=closeMonsterMask | playerGrid[cell-grid_size_x-1];
	}
	if (travelGrid.canWalk(cell-grid_size_x+1)) {
		closeMonsterMask=closeMonsterMask | playerGrid[cell-grid_size_x+1];
	}
	if (travelGrid.canWalk(cell+grid_size_x)) {
		closeMonsterMask=closeMonsterMask | playerGrid[cell+grid_size_x];
	}
	if (travelGrid.canWalk(cell+grid_size_x-1)) {
		closeMonsterMask=closeMonsterMask | playerGrid[cell+grid_size_x-1];
	}
	if (travelGrid.canWalk(cell+grid_size_x+1)) {
		closeMonsterMask=closeMonsterMask | playerGrid[cell+grid_size_x+1];
	}
	return notMyTeamMask & closeMonsterMask;
}

bool shouldPlayerFearCulDeSac(int player,int x,int y) {
	enum Bonus bonus=bonusInCell(x,y);
	if ((bonus==bonus_heart) || (bonus==bonus_egg) || (bonus==bonus_bulletproofjacket)) return false;
	if (invincibility(player)) return false; //TOFIX
	if (hasKangaroo(player)) return false;
	return true;
}

bool isCellCulDeSac(int x,int y) {
	if ((x>=grid_size_x-1) || (!x) || (y>=grid_size_y-1) || (!y)) return false;
	int i=0;
	if (!(somethingThatIsNoTABombAndThatWouldStopPlayer(x,y+1) || bombInCell(x,y+1))) i++;
	if (i>1) return false;
	if (!(somethingThatIsNoTABombAndThatWouldStopPlayer(x,y-1) || bombInCell(x,y-1))) i++;
	if (i>1) return false;
	if (!(somethingThatIsNoTABombAndThatWouldStopPlayer(x-1,y) || bombInCell(x-1,y))) i++;
	if (i>1) return false;
	if (!(somethingThatIsNoTABombAndThatWouldStopPlayer(x+1,y) || bombInCell(x+1,y))) i++;
	if (i>1) return false;
	return true;
}

// TOFIX: naive...
static int distance(int x,int y,int xP,int yP) {
	return abs(x-xP)+abs(y-yP);
}

// that's shit
bool isPlayerTheClosestPlayerFromThatCell(int player, int x,int y)
{
	int xP=xPlayer(player);
	int yP=yPlayer(player);
	int myDistance=distance(x,y,xP,yP);
	for (int i=0; i<numberOfPlayers(); i++)
	{
		if (isAlive(i))
		{
			int xP2=xPlayer(i);
			int yP2=yPlayer(i);
			int hisDistance=distance(x,y,xP2,yP2);
			if (hisDistance<myDistance)
				return false;
			if ((hisDistance==myDistance) && (i<player))
				return false;
		}
	}
	return true;
}

struct bombInfo * bombsGrid[grid_size_x][grid_size_y]; // NULL if no bomb, pointer to the bomb in m.liste_bombe
int lastBombGridUpdate=0;

void iterateOnBombs(FunctionWithBombInfo f)
{
	int nbBombs=m.liste_bombe;
	int index=0;
	struct bombInfo * bombesInfoArray=(struct bombInfo *) &m.liste_bombe_array;
	while (nbBombs && index<liste_bombe_size)
	{
		if (bombesInfoArray[index].countDown!=0)
		{
			f(&bombesInfoArray[index]);
			nbBombs--;
		}
		index++;
	}
	assert(index<liste_bombe_size);
}

void drawBombFlames(int player, int cell, int flameSize, FunctionWithFlameDrawingHelpfulData f,uint32_t flameGrid[grid_size_x][grid_size_y], bool dangerGrid[grid_size_x][grid_size_y],int &score)
{
	int x=CELLX(cell);
	int y=CELLY(cell);
	f(player,x,y,0,flameGrid,dangerGrid,score);
	int xx=x;
	int yy=y;
	int fs=flameSize;
	while ((xx>0) && (fs))
	{
		xx--;
		fs--;
		f(player,xx,yy,flameSize-fs,flameGrid,dangerGrid,score);
		if (somethingThatWouldStopFlame(xx,yy))
			break;
	}
	xx=x;
	yy=y;
	fs=flameSize;
	while ((yy>0) && (fs))
	{
		yy--;
		fs--;
		f(player,xx,yy,flameSize-fs,flameGrid,dangerGrid,score);
		if (somethingThatWouldStopFlame(xx,yy))
			break;
	}
	xx=x;
	yy=y;
	fs=flameSize;
	while ((xx<grid_size_x-2) && (fs))
	{
		xx++;
		fs--;
		f(player,xx,yy,flameSize-fs,flameGrid,dangerGrid,score);
		if (somethingThatWouldStopFlame(xx,yy))
			break;
	}
	xx=x;
	yy=y;
	fs=flameSize;
	while ((yy<grid_size_y-2) && (fs))
	{
		yy++;
		fs--;
		f(player,xx,yy,flameSize-fs,flameGrid,dangerGrid,score);
		if (somethingThatWouldStopFlame(xx,yy))
			break;
	}
}

bool flameInCell(int x,int y)
{
	db z=m.truc2[x+y*grid_size_x_with_padding];
	return ((z>4) && (z<54));
}

bool somethingThatWouldStopFlame(int x,int y)
{
	if (bonusInCell(x,y)!=no_bonus)
		return true;
	if (brickInCell(x,y))
		return true;
	if (mudbrickInCell(x,y))
		return true;
	return false;
}

#ifdef DEBUG
int howToGoDebug;
int howToGoDebugMax=1;
#endif
enum Button howToGo(int player, int toX,int toY,const travelCostGrid& travelGrid,bool &shouldJump)
{
	assert(toX>=0);
	assert(toX<grid_size_x);
	assert(toY>=0);
	assert(toY<grid_size_y);
	if ((xPlayer(player)==toX) && (yPlayer(player)==toY))   {
#ifdef DEBUG
		if (tracesDecisions(player)) log_debug("BOTTREEDECISIONS: player==toX %d %d\n",toX,toY);
#endif
		int adderX=getAdderX(player);
		int adderY=getAdderY(player);
		if (adderX<0) {
			return button_right;
		}
		if (adderX>0) {
			return button_left;
		}
		if (adderY>0) {
			return button_up;
		}
		if (adderY<0) {
			return button_down;
		}
	}

#ifdef DEBUG
	howToGoDebug++;
	if (howToGoDebug>howToGoDebugMax) {
		howToGoDebugMax=howToGoDebug;

		assert(howToGoDebug<100);
	}
#endif
	enum Button result=button_error;
	int cost=TRAVELCOST_CANTGO;
	int toXChosen=-1;
	int toYChosen=-1;
	int adderXChosen=0;
	int adderYChosen=0;
	int initialCost=travelGrid.cost(toX,toY);
	// look to the left
	if (toX>1)
	{
		int adderX=-1;
		int adderY=0;
		enum Button direction=button_right;
		int calculatedCost=travelGrid.cost(toX+adderX,toY+adderY,direction);
		if ((calculatedCost<cost) && (initialCost>=calculatedCost))
		{
			toXChosen=toX+adderX;
			toYChosen=toY+adderY;
			adderXChosen=adderX;
			adderYChosen=adderY;
			cost=calculatedCost;
			result=direction;
		}
	}
	// look to the right
	if (toX<grid_size_x-2)
	{
		int adderX=+1;
		int adderY=0;
		enum Button direction=button_left;
		int calculatedCost=travelGrid.cost(toX+adderX,toY+adderY,direction);
		if ((calculatedCost<cost) && (initialCost>=calculatedCost))
		{
			toXChosen=toX+adderX;
			toYChosen=toY+adderY;
			adderXChosen=adderX;
			adderYChosen=adderY;
			cost=calculatedCost;
			result=direction;
		}
	}

	// look to the north
	if (toY>1)
	{
		int adderX=0;
		int adderY=-1;
		enum Button direction=button_down;
		int calculatedCost=travelGrid.cost(toX+adderX,toY+adderY,direction);
		if ((calculatedCost<cost) && (initialCost>=calculatedCost))
		{
			toXChosen=toX+adderX;
			toYChosen=toY+adderY;
			adderXChosen=adderX;
			adderYChosen=adderY;
			cost=calculatedCost;
			result=direction;
		}
	}

	// look to the south
	if (toY<grid_size_y-2)
	{
		int adderX=0;
		int adderY=+1;
		enum Button direction=button_up;
		int calculatedCost=travelGrid.cost(toX+adderX,toY+adderY,direction);
		if ((calculatedCost<cost) && (initialCost>=calculatedCost))
		{
			toXChosen=toX+adderX;
			toYChosen=toY+adderY;
			adderXChosen=adderX;
			adderYChosen=adderY;
			cost=calculatedCost;
			result=direction;
		}
	}

	if (result==button_error) return result;

	if ((xPlayer(player)==toXChosen) && (yPlayer(player)==toYChosen))   {
		return result;
	} else {
		if (travelGrid.wouldInvolveJumping(toXChosen,toYChosen, result)) {                      // to avoid trying L turns on top of jump
			toXChosen+=adderXChosen;
			toYChosen+=adderYChosen;
			if ((xPlayer(player)==toXChosen) && (yPlayer(player)==toYChosen)) {
				if (isInMiddleOfCell(player)) {
					shouldJump=true;
					return result;
				}
			}
		}

#ifdef DEBUG
		if (tracesDecisions(player)) log_debug("-> %d/%d",toXChosen,toYChosen);
#endif
		return howToGo(player, toXChosen,toYChosen,travelGrid,shouldJump);
	}
}
static bool canPlayerJump(int player,int x,int y,int inVbls, int fromDirection,const uint32_t flameGrid[grid_size_x][grid_size_y]) {
	if (hasKangaroo(player)) {
		int x2=x;
		int y2=y;
		switch (fromDirection) {
		case button_right:
			x2++;
			if (x2>grid_size_x-1) return false;
			break;
		case button_left:
			assert(x>0);
			x2--;
			if (x2<0) return false;
			break;
		case button_up:
			y2--;
			if (y2<0) return false;
			break;
		case button_down:
			y2++;
			if (y2>grid_size_x-1) return false;
			break;
		default:
			assert(0);
			break;
		}
		if (somethingThatIsNoTABombAndThatWouldStopPlayer(x2,y2)) {
			return false;
		}
		int danger=flameGrid[x2][y2]-inVbls;
		if ((danger>0) && (danger<=FLAME_DURATION))
			return false;

		return true;

	} else {
		return false;
	}

}


static bool canPlayerWalk(int player,int x,int y,int inVbls, int fromDirection,const uint32_t flameGrid[grid_size_x][grid_size_y]) {
	int danger=flameGrid[x][y]-inVbls;
	int shield=invincibility(player)-inVbls;

	if ((danger>0) && (danger<=FLAME_DURATION) && (shield<=0) && (bonusInCell(x,y)!=bonus_bulletproofjacket)) {
		return false;
	}

	if (somethingThatIsNoTABombAndThatWouldStopPlayer(x,y)) {
		return false;
	}

	if (bombInCell(x,y)) {
		if (hasPush(player)) {
			int x2=x;
			int y2=y;
			switch (fromDirection) {
			case button_right:
				assert(x<grid_size_x);
				x2++;
				break;
			case button_left:
				assert(x>0);
				x2--;
				break;
			case button_up:
				assert(y>0);
				y2--;
				break;
			case button_down:
				assert(y<grid_size_y);
				y2++;
				break;
			default:
				assert(0);
				return false;
				break;
			}
			if (bombInCell(x2,y2)) return false;
			if (somethingThatIsNoTABombAndThatWouldStopPlayer(x2,y2)) return false;
			if (bonusInCell(x2,y2)!=no_bonus) return false;
		} else {
			return false;
		}
	}
	return true;
}


// fromDistance is the distance from the bomb center
static int scoreForBombingCell(int player,int x,int y,int fromDistance,int flameSize)
{
	int result=0;

	if (playerNotFromMyTeamInCell(player,x,y)) {
		if (humanPlayer[CELLINDEX(x,y)]) result++; // focus on humans
		result+=victoriesGrid[CELLINDEX(x,y)]; // focus on players with more victories
		result+=3;
	}



	if (monsterInCell(x,y))
	{
		int monsterScore=4*(fromDistance+1);
		result+=monsterScore;
	}
	enum Bonus bonus=bonusInCell(x,y);
	if (bonus!=no_bonus) {
		if (bonusPlayerWouldLike(player,bonus)==false) result+=2;
	}
	if (mudbrickInCell(x,y)) {
		result++;
		if ((mudbrickInCell(x+1,y)) || (brickInCell(x+1,y))) result++;
		if ((mudbrickInCell(x-1,y)) || (brickInCell(x-1,y))) result++;
		if ((mudbrickInCell(x,y-1)) || (brickInCell(x,y-1))) result++;
		if ((mudbrickInCell(x,y+1)) || (brickInCell(x,y+1))) result++;
	}
	return result;
}

static void updateScoreFunctionFunctionWithFlameDrawingHelpfulData(int player, int x,int y,int distance,uint32_t flameGrid[grid_size_x][grid_size_y], bool dangerGrid[grid_size_x][grid_size_y],int &score) {
	score+=scoreForBombingCell(player,x,y,distance,flameSize(player));
	flameGrid[x][y]=COUNTDOWN_DURATON+FLAME_DURATION;
}

void updateBestExplosionGrid(int player,
                             uint32_t bestExplosionsGrid[grid_size_x][grid_size_y],
                             const travelCostGrid& travelGrid,
                             const uint32_t flameGrid[grid_size_x][grid_size_y],
                             const bool dangerGrid[grid_size_x][grid_size_y])
{
	// calculate the best place to drop a bomb
	for (int j=0; j<grid_size_y; j++)
	{
		for (int i=0; i<grid_size_x; i++)
		{
			int score=0;

			if (
				dangerGrid[i][j]==false
				&& travelGrid.canWalk(i,j)
				&& (flameGrid[i][j]==0 || travelGrid.cost(i,j)>flameGrid[i][j])
				)
			{
				uint32_t grid[grid_size_x][grid_size_y];
				memmove(grid, flameGrid, sizeof(grid));
				bool unusedDangerGrid[grid_size_x][grid_size_y];

				drawBombFlames(player,CELLINDEX(i,j),flameSize(player),updateScoreFunctionFunctionWithFlameDrawingHelpfulData,grid,unusedDangerGrid,score);

				// check that there is still a safe place in the grid:
				bool foundSafePlace=false;
				for (int j=0; j<grid_size_y; j++)
				{
					for (int i=0; i<grid_size_x; i++)
					{
						if (     dangerGrid[i][j] == false
						         && travelGrid.canWalk(i,j)
						         && (grid[i][j]      == 0 ||
						             travelGrid.cost(i,j)>grid[i][j])
						         )
							foundSafePlace=true;
					}
				}
				if (!foundSafePlace)
					score=0;
			}
			bestExplosionsGrid[i][j]=score;
		}
	}
}

#define countDownApocalypse 64

static bool apocalyseDangerForCell(int x,int y)
{
	if (isInTheApocalypse())
	{
		db danger=m.truc_fin[x+y*grid_size_x_with_padding];
		if (danger<countDownApocalypse)
			return true;
	}

	return false;
}


static void visitCell(int player, int currentCell,
                      const uint32_t flameGrid[grid_size_x][grid_size_y],
                      int adderX,int adderY,int framesPerCell, int direction,travelCostGrid& travelGrid, std::priority_queue<std::pair<int,int> > &queue, bool visited[NUMBER_OF_CELLS]) {
	int nextCell;
	uint32_t nextCost=travelGrid.cost(currentCell)+framesPerCell;
	int adderCell;
	switch (direction) {
	case button_right:
		nextCost+=-adderX+abs(adderY);
		adderCell=1;
		break;
	case button_left:
		nextCost+=adderX+abs(adderY);
		adderCell=-1;
		break;
	case button_up:
		nextCost+=adderY+abs(adderX);
		adderCell=-grid_size_x;
		break;
	case button_down:
		nextCost+=-adderY+abs(adderX);
		adderCell=grid_size_x;
		break;
	default:
		assert(0);
		break;
	}
	nextCell=currentCell+adderCell;
	int nextCell2=nextCell+adderCell;
	uint32_t nextCost2=nextCost+framesPerCell;
	if (!visited[nextCell]) {

		if (canPlayerWalk(player,CELLX(nextCell),CELLY(nextCell),nextCost,direction,flameGrid))
		{
			if (nextCost<travelGrid.cost(nextCell)) {
				travelGrid.setWalkingCost(nextCell,nextCost);
				queue.push(std::pair <int,int>(-nextCost, nextCell));
			}
		} else if (canPlayerJump(player,CELLX(nextCell),CELLY(nextCell),nextCost2,direction,flameGrid)) {
			if ((travelGrid.jumpingCost(nextCell,direction)>=nextCost) && (travelGrid.cost(nextCell2)>=nextCost2)) {
				travelGrid.setJumpingCost(nextCell,nextCost,direction);
				travelGrid.setWalkingCost(nextCell2,nextCost2);
				queue.push(std::pair <int,int>(-nextCost2, nextCell2));
			}
		}
	}
}

void updateTravelGrid(int player,
                      travelCostGrid& travelGrid,
                      const uint32_t flameGrid[grid_size_x][grid_size_y])
{
	bool visited[NUMBER_OF_CELLS];
	std::priority_queue<std::pair<int,int> > queue;
	std::pair <int,int> pair;
	travelGrid.init();
	int adderX=getAdderX(player);
	int adderY=getAdderY(player);
	int playerCell=cellPlayer(player);
	int currentCell=playerCell;
	int framesPerCell=framesToCrossACell(player);

	travelGrid.setWalkingCost(currentCell,0);

	for (int i=0; i<NUMBER_OF_CELLS; i++) {
		visited[i]=false;
		if (CELLX(i)==0 || CELLX(i)==grid_size_x-1 || CELLY(i)==0 || CELLY(i)==grid_size_y-1 ) visited[i]=true;
	}
	travelGrid.setWalkingCost(currentCell,0);
	queue.push(std::pair <int,int> (0, currentCell));
	while(!queue.empty()) {
		pair = queue.top();
		queue.pop();
		currentCell = pair.second;
		if (!visited[currentCell]) {
			visited[currentCell] = true;
			visitCell(player,currentCell,flameGrid,adderX, adderY, framesPerCell,button_right,travelGrid,queue,visited);
			visitCell(player,currentCell,flameGrid,adderX, adderY, framesPerCell,button_left,travelGrid,queue,visited);
			visitCell(player,currentCell,flameGrid,adderX, adderY, framesPerCell,button_up,travelGrid,queue,visited);
			visitCell(player,currentCell,flameGrid,adderX, adderY, framesPerCell,button_down,travelGrid,queue,visited);
			adderX=0;
			adderY=0;
		}
	}
	travelGrid.setWalkingCost(playerCell,abs(getAdderX(player))+abs(getAdderY(player)));
}

static void updateFlameAndDangerGridsFunctionFunctionWithThreeInts(int player, int x,int y,int distance,uint32_t flameGrid[grid_size_x][grid_size_y], bool dangerGrid[grid_size_x][grid_size_y],int &countDown) {
	flameGrid[x][y]=flameGrid[x][y] ? std::min(flameGrid[x][y],uint32_t(countDown)) : countDown;
	dangerGrid[x][y]=true;
}
static std::vector < struct bombInfo * > vec;
static void addBombsIntoVector(struct bombInfo * bomb)
{
	vec.push_back(bomb);
}

void updateFlameAndDangerGridsWithBombs(int player,uint32_t flameGrid[grid_size_x][grid_size_y],bool dangerGrid[grid_size_x][grid_size_y])
{
	struct bombInfo possibleShieldRemoteBombsUnderPlayer[nb_dyna];
	for (int j=0; j<grid_size_y; j++)
	{
		for (int i=0; i<grid_size_x; i++)
		{
			flameGrid[i][j]=0;
			dangerGrid[i][j]=false;
		}
	}
	vec.clear();
	iterateOnBombs(addBombsIntoVector);
// add "virtual bombs" under other players that have remote + shields
	for (int i=0; i<numberOfPlayers(); i++)
	{
		if (player!=i && isAlive(i) && hasRemote(i) && invincibility(i))
		{
			possibleShieldRemoteBombsUnderPlayer[i].remote=1;
			possibleShieldRemoteBombsUnderPlayer[i].cell(cellPlayer(i));
			possibleShieldRemoteBombsUnderPlayer[i].countDown=0;
			possibleShieldRemoteBombsUnderPlayer[i].flameSize=flameSize(i);
			vec.push_back(&possibleShieldRemoteBombsUnderPlayer[i]);
		}
	}
//
	for (std::vector<struct bombInfo *>::iterator it = vec.begin(); it != vec.end(); ++it) {
		struct bombInfo * bomb=*it;

		int countDown=(int)
		               bomb->countDown+FLAME_DURATION;
		if (bomb->remote)
			countDown=0;
		int i=bomb->x();
		int j=bomb->y();
		if (flameGrid[i][j])
			countDown=std::min(flameGrid[i][j],uint32_t(countDown)); //this enable bomb explosions chains

		drawBombFlames(player,CELLINDEX(bomb->x(),bomb->y()),bomb->flameSize,updateFlameAndDangerGridsFunctionFunctionWithThreeInts,flameGrid,dangerGrid,countDown);
	}
	for (int j=0; j<grid_size_y; j++)
	{
		for (int i=0; i<grid_size_x; i++)
		{
			if (flameInCell(i,j))
				flameGrid[i][j]=FLAME_DURATION; //TODO be more precise.
		}
	}
}

void updateDangerGridWithMonstersAndCulDeSacs(int player, const travelCostGrid& travelGrid,bool dangerGrid[grid_size_x][grid_size_y])
{

	for (int i=numberOfPlayers(); i<nb_dyna; i++)
	{
		if (isAlive(i))
		{
			int cell=cellPlayer(i);
			dangerGrid[CELLX(cell)][CELLY(cell)]=true;
		}
	}

	for (int j=0; j<grid_size_y; j++)
	{
		for (int i=0; i<grid_size_x; i++)
		{
			if (apocalyseDangerForCell(i,j)) {
				dangerGrid[i][j]=true;
			} else {
				if (invincibility(player)>FLAME_DURATION) {
					dangerGrid[i][j]=false;
				} else {
					if ((enemyAroundCell(player,travelGrid, i,j)) && (isCellCulDeSac(i,j)) && shouldPlayerFearCulDeSac(player,i,j)) {
						dangerGrid[i][j]=true;
					}
				}
			}
		}
	}
}

void updateMonsterIsComingGrid(bool monsterIsComingGrid[NUMBER_OF_CELLS]) {

	for (int i=0; i<NUMBER_OF_CELLS; i++)
	{
		monsterIsComingGrid[i]=false;
	}
	for (int i=numberOfPlayers(); i<nb_dyna; i++)
	{
		if (isAlive(i))
		{
			monsterIsComingGrid[dangerousCellForMonster(i)]=true;
		}
	}
}

void printCellInfo(int cell,int player)
{
	log_debug("printCellInfo %d: mudbrickInCell=%d brickInCell=%d  bombInCell=%d bonusInCell=%d\n", cell,mudbrickInCell(CELLX(cell),CELLY(cell)),brickInCell(CELLX(cell),CELLY(cell)),bombInCell(CELLX(cell),CELLY(cell)),bonusInCell(CELLX(cell),CELLY(cell)));
}




