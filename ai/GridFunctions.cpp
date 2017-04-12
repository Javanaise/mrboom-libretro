#include <array>
#include <vector>
#include <algorithm>
#include "GridFunctions.hpp"
#include "common.hpp"
#include "MrboomHelper.hpp"
#include <strings.h>
#define liste_bombe_size (247)

#define UPDATEPLAYERSGRID if ((!lastPlayerGridUpdate) || (frameNumber()!=lastPlayerGridUpdate)) lastPlayerGridUpdate=updatePlayerGrid();
enum playerKind {
	no_player,
	player,
	monster
};

playerKind playerGrid[grid_size_x][grid_size_y];
static int lastPlayerGridUpdate=0;

static int updatePlayerGrid() {
	for (int j=0; j<grid_size_y; j++) {
		for (int i=0; i<grid_size_x; i++) {
			playerGrid[i][j]=no_player;
		}
	}
	for (int i=0; i<numberOfPlayers(); i++) {
		if (isAlive(i)) {
			int xP=GETXPLAYER(i);
			int yP=GETYPLAYER(i);
			playerGrid[xP][yP]=player;
		}
	}
	for (int i=numberOfPlayers(); i<nb_dyna; i++) {
		if (isAlive(i)) {
			int xP=GETXPLAYER(i);
			int yP=GETYPLAYER(i);
			playerGrid[xP][yP]=monster;
		}
	}
	return frameNumber();
}

bool playerInCell(int x,int y) {
	UPDATEPLAYERSGRID
	return  (playerGrid[x][y]==player);
}

bool monsterInCell(int x,int y) {
	UPDATEPLAYERSGRID
	return  (playerGrid[x][y]==monster);
}

// naive...
#define CALCULATE_DISTANCE(x,y,xP,yP) abs(x-xP)+abs(y-yP)

// that's shit
bool isPlayerTheClosestPlayerFromThatCell(int player, int x,int y) {
	int xP=GETXPLAYER(player);
	int yP=GETYPLAYER(player);
	int myDistance=CALCULATE_DISTANCE(x,y,xP,yP);
	for (int i=0; i<numberOfPlayers(); i++) {
		if (isAlive(i)) {
			int xP2=GETXPLAYER(i);
			int yP2=GETYPLAYER(i);
			int hisDistance=CALCULATE_DISTANCE(x,y,xP2,yP2);
			if (hisDistance<myDistance) {
				return false;
			}
			if ((hisDistance==myDistance) && (i<player)) {
				return false;
			}
		}
	}
	return true;
}

#define UPDATEBOMBGRID if ((!lastBombGridUpdate) || (frameNumber()!=lastBombGridUpdate)) lastBombGridUpdate=updateBombGrid();
struct bombInfo * bombsGrid[grid_size_x][grid_size_y]; // NULL if no bomb, pointer to the bomb in m.liste_bombe
std::array<int, grid_size_x*grid_size_y> bombsArray;
static int lastBombGridUpdate=0;

void iterateOnBombs(std::function<void (struct bombInfo *)> f) {
	int nbBombs=m.liste_bombe;
	int index=0;
	struct bombInfo * bombesInfoArray=(struct bombInfo *) &m.liste_bombe_array;
	while (nbBombs && index<liste_bombe_size) {
		if (bombesInfoArray[index].countDown!=0) {
			f(&bombesInfoArray[index]);
			nbBombs--;
		}
		index++;
	}
	assert(index<liste_bombe_size);
}

void drawBombFlames(int cell, int flameSize, std::function<void (int,int,int)> f) {
	int x=CELLX(cell);
	int y=CELLY(cell);
	f(x,y,0);
	int xx=x;
	int yy=y;
	int fs=flameSize;
	while ((xx>0) && (fs)) {
		xx--;
		fs--;
		f(xx,yy,flameSize-fs);
		if (somethingThatWouldStopFlame(xx,yy)) break;
	}
	xx=x;
	yy=y;
	fs=flameSize;
	while ((yy>0) && (fs)) {
		yy--;
		fs--;
		f(xx,yy,flameSize-fs);
		if (somethingThatWouldStopFlame(xx,yy)) break;
	}
	xx=x;
	yy=y;
	fs=flameSize;
	while ((xx<grid_size_x-2) && (fs)) {
		xx++;
		fs--;
		f(xx,yy,flameSize-fs);
		if (somethingThatWouldStopFlame(xx,yy)) break;
	}
	xx=x;
	yy=y;
	fs=flameSize;
	while ((yy<grid_size_y-2) && (fs)) {
		yy++;
		fs--;
		f(xx,yy,flameSize-fs);
		if (somethingThatWouldStopFlame(xx,yy)) break;
	}
}

static int updateBombGrid() {
	bzero(bombsGrid,sizeof(bombsGrid));
	iterateOnBombs([](struct bombInfo * bomb) {
		bombsGrid[bomb->x()][bomb->y()]=bomb;
	});
	return frameNumber();
}
bool flameInCell(int x,int y) {
	db z=m.truc2[x+y*grid_size_x_with_padding];
	return ((z>4) && (z<54));
}

Bonus bonusInCell(int x,int y) {
	/*
	   ;1 = bombe... (2,3,4) respirant... si c sup a 4; on est mort...
	   ;5 = centre de bombe. de 5 a 11
	   ;12 = ligne droite...
	   ;19 = arrondie ligne droite vers la gauche...
	   ;26 = arrondie ligne droite vers la droite
	   ;33 = ligne verti
	   ;40 arrondie verti vers le haut
	   ;47-- bas
	   ;54-- bonus bombe... de 54 a 63 (offset 144)
	   ;64-- bonus flamme... de 64 a 73 (offset 144+320*16)
	   ;74-- tete de mort  de 74 a 83
	   ;84-- bonus parre balle. de 84 a 93
	   ;94-- bonus COEUR !!!
	   ;104 -- bonus bombe retardement
	   ;114 --- bonus pousseur
	   ;124 --- patins a roulettes
	   ;134 --- HORLOGE
	         ;horloge
	         bonus_4 134
	         bonus_3 144,1,tribombe
	         bonus_6 154
	         ;oeuf
	         bonus_5 193
	 */
	db z=m.truc2[x+y*grid_size_x_with_padding];
	if ((z>=54) && (z<194)) {
		if (z<64) return bonus_bomb;
		if (z<74) return bonus_flame;
		if (z<84) return bonus_skull;
		if (z<94) return bonus_bulletproofjacket;
		if (z<104) return bonus_heart;
		if (z<114) return bonus_remote;
		if (z<124) return bonus_push;
		if (z<134) return bonus_roller;
		if (z<144) return bonus_time;
		if (z<154) return bonus_tribomb;
		if (z<164) return bonus_banana;
		return bonus_egg;
	} else {
		return no_bonus;
	}
}




bool mudbrickInCell(int x,int y) {
	db brickKind=m.truc[x+y*grid_size_x_with_padding];
	return (brickKind==2);
}

bool brickInCell(int x,int y) {
	db brickKind=m.truc[x+y*grid_size_x_with_padding];
	return (brickKind==1);
}
bool bombInCell(int x,int y) {
	UPDATEBOMBGRID
	return (bombsGrid[x][y]!=NULL);
}


bool somethingThatWouldStopFlame(int x,int y) {
	if (bonusInCell(x,y)!=no_bonus) return true;
	if (brickInCell(x,y)) return true;
	if (mudbrickInCell(x,y)) return true;
	return false;
}

bool somethingThatWouldStopPlayer(int x,int y) {
	if (brickInCell(x,y)) return true;
	if (mudbrickInCell(x,y)) return true;
	if (bombInCell(x,y)) return true;
	if (monsterInCell(x,y)) return true;
	if (bonusInCell(x,y)==bonus_skull) return true;
	return false;
}

enum Button howToGo(int player, int toX,int toY,const int travelGrid[grid_size_x][grid_size_y]) {
	enum Button result=button_error;
	int cost=TRAVELCOST_CANTGO;
	int toXChosen=-1;
	int toYChosen=-1;
	// look to the left
	if (toX>1) {
		if (travelGrid[toX-1][toY]<cost) {
			toXChosen=toX-1;
			toYChosen=toY;
			cost=travelGrid[toXChosen][toYChosen];
			result=button_right; //because we're walking backward...
		}
	}
	// look to the right
	if (toX<grid_size_x-2) {
		if (travelGrid[toX+1][toY]<cost) {
			toXChosen=toX+1;
			toYChosen=toY;
			cost=travelGrid[toXChosen][toYChosen];
			result=button_left;
		}
	}
	// look to the north
	if (toY>1) {
		if (travelGrid[toX][toY-1]<cost) {
			toXChosen=toX;
			toYChosen=toY-1;
			cost=travelGrid[toXChosen][toYChosen];
			result=button_down;
		}
	}
	// look to the south
	if (toY<grid_size_y-2) {
		if (travelGrid[toX][toY+1]<cost) {
			toXChosen=toX;
			toYChosen=toY+1;
			cost=travelGrid[toXChosen][toYChosen];
			result=button_up;
		}
	}
	if (result==button_error) {
		assert(result!=button_error);
		return result;
	}
	if (cost<framesToCrossACell(player)) {
		return result;
	} else {
		return howToGo(player, toXChosen,toYChosen,travelGrid);
	}
}

static bool canPlayerGo(int xCell,int yCell,int inVbls,const int flameGrid[grid_size_x][grid_size_y]) {
	if (somethingThatWouldStopPlayer(xCell,yCell)) return false;
	int danger=flameGrid[xCell][yCell]-inVbls;
	if ((danger>0) && (danger<=FLAME_DURATION)) return false;
	return true;
}


static void updateTravelGridRec(int player, int x, int y, int travelGrid[grid_size_x][grid_size_y],const int flameGrid[grid_size_x][grid_size_y],int adderX,int adderY,int framesPerCell) {
	int currentCost = travelGrid[x][y];
	// west
	if (x>1) {
		if ((canPlayerGo(x-1,y,currentCost+framesPerCell,flameGrid) && (travelGrid[x-1][y]>currentCost))) {
			travelGrid[x-1][y]=currentCost+framesPerCell+adderX;
			updateTravelGridRec(player,x-1,y,travelGrid,flameGrid,0,0,framesPerCell);
		}
	}
	// east
	if (x<grid_size_x-2) {
		if ((canPlayerGo(x+1,y,currentCost+framesPerCell,flameGrid) && (travelGrid[x+1][y]>currentCost))) {
			travelGrid[x+1][y]=currentCost+framesPerCell-adderX;
			updateTravelGridRec(player,x+1,y,travelGrid,flameGrid,0,0,framesPerCell);
		}
	}
	// north
	if (y>1) {
		if (canPlayerGo(x,y-1,currentCost+framesPerCell,flameGrid) && (travelGrid[x][y-1]>currentCost)) {
			travelGrid[x][y-1]=currentCost+framesPerCell+adderY;
			updateTravelGridRec(player,x,y-1,travelGrid,flameGrid,0,0,framesPerCell);
		}
	}
	// south
	if (y<grid_size_y-2) {
		if (canPlayerGo(x,y+1,currentCost+framesPerCell,flameGrid) && (travelGrid[x][y+1]>currentCost)) {
			travelGrid[x][y+1]=currentCost+framesPerCell-adderY;
			updateTravelGridRec(player,x,y+1,travelGrid,flameGrid,0,0,framesPerCell);
		}
	}
}
// fromDistance is the distance from the bomb center
static int scoreForBombingCell(int x,int y,int fromDistance,int flameSize, int forPlayer) {
	int result=0;
	if (playerInCell(x,y)) {
		result+=4;
	}
	if (monsterInCell(x,y)) {
		int monsterScore=4*(fromDistance+1);
		/*
		   assert(0!=fromDistance);
		   if (flameSize==fromDistance) {       // to avoid to go too close from the monster
		        monsterScore=2*fromDistance;
		   }
		 */
		result+=monsterScore;
	}
	if (mudbrickInCell(x,y)) result++;
	return result;
}

void updateBestExplosionGrid(int player, int bestExplosionsGrid[grid_size_x][grid_size_y], int const travelGrid[grid_size_x][grid_size_y],const int flameGrid[grid_size_x][grid_size_y],const bool dangerGrid[grid_size_x][grid_size_y]) {
	// calcule the best place to drop a bomb
	int flame=flameSize(player);
	for (int j=0; j<grid_size_y; j++) {
		for (int i=0; i<grid_size_x; i++) {
			int score=0;
			if (dangerGrid[i][j]==false && travelGrid[i][j]!=TRAVELCOST_CANTGO && travelGrid[i][j]>flameGrid[i][j]) {
				int grid[grid_size_x][grid_size_y];
				bcopy(flameGrid,grid,sizeof(grid));
				drawBombFlames(CELLINDEX(i,j),flame,[&score,&grid,&player,&flame](int x,int y,int distance) {
					score+=scoreForBombingCell(x,y,distance,flame,player);
					grid[x][y]=COUNTDOWN_DURATON+FLAME_DURATION;
				});
				// check that there is still a safe place in the grid:
				bool foundSafePlace=false;
				for (int j=0; j<grid_size_y; j++) {
					for (int i=0; i<grid_size_x; i++) {
						if (dangerGrid[i][j]==false && travelGrid[i][j]!=TRAVELCOST_CANTGO && (grid[i][j]==0 || travelGrid[i][j]>grid[i][j]) ) {
							foundSafePlace=true;
						}
					}
				}
				if (!foundSafePlace) {
					score=0;
				}
			}
			bestExplosionsGrid[i][j]=score;
		}
	}
}

static bool apocalyseDangerForCell(int x,int y) {
	if (isInTheApocalypse()) {
	#define countDownApocalypse 64
		db danger=m.truc_fin[x+y*grid_size_x_with_padding];
		if (danger<countDownApocalypse) {
			return true;
		} else {
			return false;
		}
	} else {
		return false;
	}
}

void updateTravelGrid(int player, int travelGrid[grid_size_x][grid_size_y],const int flameGrid[grid_size_x][grid_size_y]) {
	int x=GETXPLAYER(player);
	int y=GETYPLAYER(player);

	for (int j=0; j<grid_size_y; j++) {
		for (int i=0; i<grid_size_x; i++) {
			travelGrid[i][j]=TRAVELCOST_CANTGO;
		}
	}
	int adderX=GETXPIXELSTOCENTEROFCELL(player)*framesToCrossACell(player)/CELLPIXELSSIZE;;
	int adderY=GETYPIXELSTOCENTEROFCELL(player)*framesToCrossACell(player)/CELLPIXELSSIZE;;
	if (adderY) {
		if (adderX!=0)
			printf("warning adderX=%d adderY=%d\n",adderX,adderY);
	}
	if (adderX) {
		if (adderY!=0)
			printf("x warning adderX=%d adderY=%d\n",adderX,adderY);
	}
	travelGrid[x][y]=0;
	updateTravelGridRec(player,x,y,travelGrid,flameGrid,adderX,adderY,framesToCrossACell(player));
//	travelGrid[x][y]=framesToGetToCenterOfTheCell(player);
	if (adderX) {
		travelGrid[x][y]=abs(adderX);
	} else {
		travelGrid[x][y]=abs(adderY);
	}
}
void updateFlameAndDangerGrids(int player,int flameGrid[grid_size_x][grid_size_y],bool dangerGrid[grid_size_x][grid_size_y]) {
	for (int j=0; j<grid_size_y; j++) {
		for (int i=0; i<grid_size_x; i++) {
			flameGrid[i][j]=0;
			dangerGrid[i][j]=false;
		}
	}
	std::vector < struct bombInfo * > vec;
	iterateOnBombs([&vec](struct bombInfo * bomb) {
		vec.push_back(bomb);
	});
	std::sort(vec.begin(), vec.end(),
	          [] (const bombInfo* struct1, const bombInfo* struct2)
	{
		return (struct1->countDown < struct2->countDown);
	}
	          );
	for (auto bomb : vec) {
		int countDown=(int) bomb->countDown+FLAME_DURATION;
		if (bomb->remote) countDown=0;
		int i=bomb->x();
		int j=bomb->y();
		if (flameGrid[i][j]) countDown=std::min(flameGrid[i][j],countDown);         //this enable bomb explosions chains
		drawBombFlames(CELLINDEX(bomb->x(),bomb->y()),bomb->flameSize,[=](int x,int y,int distance) {
			flameGrid[x][y]=flameGrid[x][y] ? std::min(flameGrid[x][y],countDown) : countDown;
			dangerGrid[x][y]=true;
		});
	}
	for (int j=0; j<grid_size_y; j++) {
		for (int i=0; i<grid_size_x; i++) {
			if (flameInCell(i,j)) flameGrid[i][j]=FLAME_DURATION; //TODO be more precise.
			dangerGrid[i][j]=(apocalyseDangerForCell(i,j) || dangerGrid[i][j]);
		}
	}
}

void printCellInfo(int cell) {
	log_debug("printCellInfo %d: mudbrickInCell=%d brickInCell=%d  bombInCell=%d bonusInCell=%d sTWStopB=%d\n", cell,mudbrickInCell(CELLX(cell),CELLY(cell)),brickInCell(CELLX(cell),CELLY(cell)),bombInCell(CELLX(cell),CELLY(cell)),bonusInCell(CELLX(cell),CELLY(cell)),somethingThatWouldStopPlayer(CELLX(cell),CELLY(cell)));
}
