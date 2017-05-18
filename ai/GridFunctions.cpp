#include <vector>
#include <algorithm>
#include "GridFunctions.hpp"
#include "common.hpp"
#include "MrboomHelper.hpp"
#include <strings.h>
#define liste_bombe_size (247)


playerKind playerGrid[grid_size_x][grid_size_y];
int lastPlayerGridUpdate=0;

static int getAdderX(int player) {
	return GETXPIXELSTOCENTEROFCELL(player)*framesToCrossACell(player)/CELLPIXELSSIZE;
}
static int getAdderY(int player) {
	return GETYPIXELSTOCENTEROFCELL(player)*framesToCrossACell(player)/CELLPIXELSSIZE;
}




bool playerInCell(int x,int y)
{
	updatePlayerGrid();
	return  (playerGrid[x][y]<=player_team8);
}

bool playerInCell(int player,int x,int y)
{
	int xp=xPlayer(player);
	int yp=yPlayer(player);
	return ((x==xp) && (y==yp));
}

bool playerNotFromMyTeamInCell(int player,int x,int y)
{
	if (playerInCell(x,y))
		return teamOfPlayer(player)!=playerGrid[x][y];
	return false;
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

void drawBombFlames(int cell, int flameSize, FunctionWithThreeInts f)
{
	int x=CELLX(cell);
	int y=CELLY(cell);
	f(x,y,0);
	int xx=x;
	int yy=y;
	int fs=flameSize;
	while ((xx>0) && (fs))
	{
		xx--;
		fs--;
		f(xx,yy,flameSize-fs);
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
		f(xx,yy,flameSize-fs);
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
		f(xx,yy,flameSize-fs);
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
		f(xx,yy,flameSize-fs);
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
enum Button howToGo(int player, int toX,int toY,const travelCostGrid& travelGrid)
{
	assert(toX>=0);
	assert(toX<grid_size_x);
	assert(toY>=0);
	assert(toY<grid_size_y);
	if ((xPlayer(player)==toX) && (yPlayer(player)==toY))   {
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
				return result;
			}
		}
		return howToGo(player, toXChosen,toYChosen,travelGrid);
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
	if ((danger>0) && (danger<=FLAME_DURATION))
		return false;

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

static void updateTravelGridRec(int player, int x, int y,
                                struct travelCostGrid& travelGrid,
                                const uint32_t flameGrid[grid_size_x][grid_size_y],
                                int adderX,int adderY,int framesPerCell);

static void updateTravelGridRec2(int player, int x, int y,
                                 struct travelCostGrid& travelGrid,
                                 const uint32_t flameGrid[grid_size_x][grid_size_y],
                                 int adderX,int adderY,int framesPerCell, int currentCost, int direction, int adderX2,int adderY2)
{
	int nextCost=currentCost+framesPerCell;
	switch (direction) {
	case button_right:
		nextCost+=-adderX+abs(adderY);
		break;
	case button_left:
		nextCost+=adderX+abs(adderY);
		break;
	case button_up:
		nextCost+=adderY+abs(adderX);
		break;
	case button_down:
		nextCost+=-adderY+abs(adderX);
		break;
	default:
		assert(0);
		break;
	}
	int newX=x+adderX2;
	int newY=y+adderY2;
	if (canPlayerWalk(player,newX,newY,nextCost,direction,flameGrid))
	{
		if (travelGrid.cost(newX,newY)>=nextCost) {
			travelGrid.setWalkingCost(newX,newY,nextCost);
			updateTravelGridRec(player,newX,newY,travelGrid,flameGrid,0,0,framesPerCell);
		}
		#ifdef DEBUG
	} else if (canPlayerJump(player,newX,newY,nextCost,direction,flameGrid)) {
		int newX2=newX+adderX2;
		int newY2=newY+adderY2;
		int nextCost2=nextCost+framesPerCell;
		if ((travelGrid.jumpingCost(newX,newY,direction)>=nextCost) && (travelGrid.cost(newX2,newY2)>=nextCost2)) {
			travelGrid.setJumpingCost(newX,newY,nextCost,direction);
			travelGrid.setWalkingCost(newX2,newY2,nextCost2);
			updateTravelGridRec(player,newX2,newY2,travelGrid,flameGrid,0,0,framesPerCell);
		}
		#endif
	}
}

static void updateTravelGridRec(int player, int x, int y,
                                struct travelCostGrid& travelGrid,
                                const uint32_t flameGrid[grid_size_x][grid_size_y],
                                int adderX,int adderY,int framesPerCell)
{
	int currentCost = travelGrid.cost(x,y);
	// west
	if (x>1)
	{
		updateTravelGridRec2(player,x,y,travelGrid,flameGrid,adderX,adderY,framesPerCell,currentCost,button_left,-1,0);
	}
	// east
	if (x<grid_size_x-2)
	{
		updateTravelGridRec2(player,x,y,travelGrid,flameGrid,adderX,adderY,framesPerCell,currentCost,button_right,1,0);
	}
	// north
	if (y>1)
	{
		updateTravelGridRec2(player,x,y,travelGrid,flameGrid,adderX,adderY,framesPerCell,currentCost,button_up,0,-1);
	}
	// south
	if (y<grid_size_y-2)
	{
		updateTravelGridRec2(player,x,y,travelGrid,flameGrid,adderX,adderY,framesPerCell,currentCost,button_down,0,1);
	}
}

// fromDistance is the distance from the bomb center
static int scoreForBombingCell(int player,int x,int y,int fromDistance,int flameSize)
{
	int result=0;

	if (playerNotFromMyTeamInCell(player,x,y))
		result+=3;

	if (monsterInCell(x,y))
	{
		int monsterScore=4*(fromDistance+1);
		result+=monsterScore;
	}
	enum Bonus bonus=bonusInCell(x,y);
	if (bonus!=no_bonus) {
		if (bonusPlayerWouldLike(player,bonus)==false) result+=2;
	}
	if (mudbrickInCell(x,y))
		result++;
	return result;
}

// used by increaseScoreAndUpdateGrid and updateBestExplosionGrid
static uint32_t grid[grid_size_x][grid_size_y];
static int score;
static int playerSave;
static int flame;

static void updateScoreFunctionFunctionWithThreeInts(int x,int y,int distance) {
	score+=scoreForBombingCell(playerSave,x,y,distance,flame);
	grid[x][y]=COUNTDOWN_DURATON+FLAME_DURATION;
}

void updateBestExplosionGrid(int player,
                             uint32_t bestExplosionsGrid[grid_size_x][grid_size_y],
                             const travelCostGrid& travelGrid,
                             const uint32_t flameGrid[grid_size_x][grid_size_y],
                             const bool dangerGrid[grid_size_x][grid_size_y])
{
	// calculate the best place to drop a bomb
	playerSave=player;
	flame=flameSize(player);
	for (int j=0; j<grid_size_y; j++)
	{
		for (int i=0; i<grid_size_x; i++)
		{
			score=0;

			if (
				dangerGrid[i][j]==false
				&& travelGrid.canWalk(i,j)
				&& (flameGrid[i][j]==0 || travelGrid.cost(i,j)>flameGrid[i][j])
				)
			{
				memmove(grid, flameGrid, sizeof(grid));

				drawBombFlames(CELLINDEX(i,j),flame,updateScoreFunctionFunctionWithThreeInts);

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



void updateTravelGrid(int player,
                      travelCostGrid& travelGrid,
                      const uint32_t flameGrid[grid_size_x][grid_size_y])
{
	int x=xPlayer(player);
	int y=yPlayer(player);
	travelGrid.init();
	int adderX=getAdderX(player);
	int adderY=getAdderY(player);

#ifdef DEBUG
	if (adderY)
	{
		if (adderX!=0) {
			log_debug("Error ? adderX!=0\n");
		}
	}
	if (adderX)
	{
		if (adderY!=0) {
			log_debug("Error ? adderY!=0\n");
		}
	}
#endif

	//if (debugTracesPlayer(player)) log_debug("player %d adderX:%d adderY:%d\n",player,adderX,adderY);
	travelGrid.setWalkingCost(x,y,0);
	updateTravelGridRec(player,x,y,travelGrid,flameGrid,adderX,adderY,framesToCrossACell(player));
	travelGrid.setWalkingCost(x,y,abs(adderX)+abs(adderY));
}


// used by increaseScoreAndUpdateGrid and updateBestExplosionGrid
static bool dangerGrid_save[grid_size_x][grid_size_y];
static uint32_t flameGrid_save[grid_size_x][grid_size_y];
static uint32_t countDown;

static void updateFlameAndDangerGridsFunctionFunctionWithThreeInts(int x,int y,int distance) {
	flameGrid_save[x][y]=flameGrid_save[x][y] ? std::min(flameGrid_save[x][y],countDown) : countDown;
	dangerGrid_save[x][y]=true;
}
static std::vector < struct bombInfo * > vec;
static void addBombsIntoVector(struct bombInfo * bomb)
{
	vec.push_back(bomb);
}

void updateFlameAndDangerGrids(int player,uint32_t flameGrid[grid_size_x][grid_size_y],bool dangerGrid[grid_size_x][grid_size_y])
{
	for (int j=0; j<grid_size_y; j++)
	{
		for (int i=0; i<grid_size_x; i++)
		{
			flameGrid_save[i][j]=0;
			dangerGrid_save[i][j]=false;
		}
	}
	vec.clear();
	iterateOnBombs(addBombsIntoVector);

	for (std::vector<struct bombInfo *>::iterator it = vec.begin(); it != vec.end(); ++it) {
		struct bombInfo * bomb=*it;

		countDown=(int)
		           bomb->countDown+FLAME_DURATION;
		if (bomb->remote)
			countDown=0;
		int i=bomb->x();
		int j=bomb->y();
		if (flameGrid_save[i][j])
			countDown=std::min(flameGrid_save[i][j],countDown); //this enable bomb explosions chains

		drawBombFlames(CELLINDEX(bomb->x(),bomb->y()),bomb->flameSize,updateFlameAndDangerGridsFunctionFunctionWithThreeInts);
	}
	memmove(dangerGrid, dangerGrid_save,  sizeof(dangerGrid_save));
	memmove(flameGrid, flameGrid_save,  sizeof(flameGrid_save));

	for (int j=0; j<grid_size_y; j++)
	{
		for (int i=0; i<grid_size_x; i++)
		{
			if (flameInCell(i,j))
				flameGrid[i][j]=FLAME_DURATION; //TODO be more precise.
			dangerGrid[i][j]=(apocalyseDangerForCell(i,j) || dangerGrid[i][j]);
		}
	}
}

void printCellInfo(int cell,int player)
{
	log_debug("printCellInfo %d: mudbrickInCell=%d brickInCell=%d  bombInCell=%d bonusInCell=%d\n", cell,mudbrickInCell(CELLX(cell),CELLY(cell)),brickInCell(CELLX(cell),CELLY(cell)),bombInCell(CELLX(cell),CELLY(cell)),bonusInCell(CELLX(cell),CELLY(cell)));
}




