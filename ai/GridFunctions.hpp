#pragma once
#include "mrboom.h"
#include "common.hpp"
#include "MrboomHelper.hpp"
#include <algorithm>    // std::min
#define MAX_PIXELS_PER_FRAME 8

#pragma pack(push, 1)
typedef struct bombInfo {
	dd infojoueur;
	dd countDown;
	dd offsetCell;
	dw flameSize;
	dw remote;
	dw adderX; //+1,0,-1
	dw adderY; //+1,0,-1
	dw offsetX; // 0 = middle
	dw offsetY;
	void cell(int cell) {
		offsetCell=CELLX(cell)+CELLY(cell)*grid_size_x_with_padding;
	}
	int x() {
		return CELLXWITHPADDING(offsetCell);
	};
	int y() {
		return CELLYWITHPADDING(offsetCell);
	};
	int getPlayer() {
		int bombPlayer=-1; //will return -1 on a end of level 2 bomb.
		if (offsetof(struct Mem,j1)==infojoueur) bombPlayer=0;
		if (offsetof(struct Mem,j2)==infojoueur) bombPlayer=1;
		if (offsetof(struct Mem,j3)==infojoueur) bombPlayer=2;
		if (offsetof(struct Mem,j4)==infojoueur) bombPlayer=3;
		if (offsetof(struct Mem,j5)==infojoueur) bombPlayer=4;
		if (offsetof(struct Mem,j6)==infojoueur) bombPlayer=5;
		if (offsetof(struct Mem,j7)==infojoueur) bombPlayer=6;
		if (offsetof(struct Mem,j8)==infojoueur) bombPlayer=7;
		return bombPlayer;
	}
} bombInfo;
#pragma pack(pop)

#pragma pack(push, 1)
typedef struct travelCostGrid {
	uint32_t travelCostGrid[grid_size_x][grid_size_y];  // safe to walk walking distance, TRAVELCOST_CANTGO if cant go, -7 to +8 if player is here...
	uint32_t travelCostGridJumpLeftRight[grid_size_x][grid_size_y];
	uint32_t travelCostGridJumpUpDown[grid_size_x][grid_size_y];

	uint32_t cost(int i,int j, int direction) const {
		return std::min(jumpingCost(i,j,direction),travelCostGrid[i][j]); // min: to be able to jump on a flame and come back later using the walking way. (otherwise the comeback breaks the path)
	}
	bool wouldInvolveJumping(int i,int j, int direction) const {
		return (jumpingCost(i,j,direction)<travelCostGrid[i][j]);
	}
	uint32_t cost(int i,int j) const {
		return travelCostGrid[i][j];
	}
	uint32_t cost(int cell) const {
		return cost(CELLX(cell),CELLY(cell));
	}
	void setWalkingCost(int cell,uint32_t cost) {
		travelCostGrid[CELLX(cell)][CELLY(cell)]=cost;
	}
	void printCell(int i,int j) {
		int lr=costLeftRight(i,j);
		int up=costUpDown(i,j);
		int w=cost(i,j);

		if (TRAVELCOST_CANTGO!=w) {
			log_debug("  %03d   ",w);
		} else {

			if ((lr!=TRAVELCOST_CANTGO) || (up!=TRAVELCOST_CANTGO)) {


				if (TRAVELCOST_CANTGO!=lr) {
					log_debug("%03d/",lr);
				} else {
					log_debug("---/");
				}
				if (TRAVELCOST_CANTGO!=up) {
					log_debug("%03d ",up);
				} else {
					log_debug("--- ");
				}

			} else {
				log_debug("  ---   ");
			}

		}
	}


	uint32_t jumpingCost(int i,int j,int direction) const {
		switch (direction) {
		case button_left:
			return travelCostGridJumpLeftRight[i][j];
			break;
		case button_right:
			return travelCostGridJumpLeftRight[i][j];
			break;
		case button_up:
			return travelCostGridJumpUpDown[i][j];
			break;
		case button_down:
			return travelCostGridJumpUpDown[i][j];
			break;
		default:
			assert(0);
			break;
		}
		return 0;
	}
	uint32_t jumpingCost(int cell,int direction) const {
		int i=CELLX(cell);
		int j=CELLY(cell);
		return jumpingCost(i,j,direction);
	}
	uint32_t costLeftRight(int i,int j) const {
		return jumpingCost(i,j,button_left);
	}

	uint32_t costUpDown(int i,int j) const {
		return jumpingCost(i,j,button_up);
	}

	void setJumpingCost(int i,int j,uint32_t cost,int direction) {
		switch (direction) {
		case button_left:
			travelCostGridJumpLeftRight[i][j]=cost;
			break;
		case button_right:
			travelCostGridJumpLeftRight[i][j]=cost;
			break;
		case button_up:
			travelCostGridJumpUpDown[i][j]=cost;
			break;
		case button_down:
			travelCostGridJumpUpDown[i][j]=cost;
			break;
		default:
			assert(0);
			break;
		}
	}

	void setJumpingCost(int cell,uint32_t cost,int direction) {
		int i=CELLX(cell);
		int j=CELLY(cell);
		return setJumpingCost(i,j,cost,direction);
	}

	bool canWalk(int i,int j) const {
		return (travelCostGrid[i][j]!=TRAVELCOST_CANTGO);
	}
	bool canWalk(int cell) const {
		return canWalk(CELLX(cell),CELLY(cell));
	}
	void init() {
		for (int j=0; j<grid_size_y; j++)
		{
			for (int i=0; i<grid_size_x; i++) {
				travelCostGrid[i][j]=TRAVELCOST_CANTGO;
				travelCostGridJumpLeftRight[i][j]=TRAVELCOST_CANTGO;
				travelCostGridJumpUpDown[i][j]=TRAVELCOST_CANTGO;
			}

		}
	}
	void print() {
		for (int i=0; i<grid_size_x; i++) {
			log_debug("__%03d__ ",i);
		}
		log_debug("\n");
		for (int j=0; j<grid_size_y; j++) {
			for (int i=0; i<grid_size_x; i++) {
				printCell(i,j);
			}
			log_debug("-%03d-",j);
			log_debug("\n");
		}
	}
} travelCostGrid;
#pragma pack(pop)


enum Button howToGo(int player,int toX,int toY,const travelCostGrid& travelGrid,bool &shouldJump);
bool isPlayerFastestToCell(int player, int x,int y);
typedef void (*FunctionWithBombInfo)(struct bombInfo *);
void iterateOnBombs(FunctionWithBombInfo f);
typedef void (*FunctionWithFlameDrawingHelpfulData)(int, int, int, int, uint32_t[grid_size_x][grid_size_y],bool[grid_size_x][grid_size_y],int&);
void drawBombFlames(int player, int cell, int flameSize, FunctionWithFlameDrawingHelpfulData f, uint32_t[grid_size_x][grid_size_y],bool[grid_size_x][grid_size_y],int&);
void updateBestExplosionGrid(int player, uint32_t bestExplosionsGrid[grid_size_x][grid_size_y], const travelCostGrid& travelGrid,const uint32_t flameGrid[grid_size_x][grid_size_y],const bool dangerGrid[grid_size_x][grid_size_y]);
void updateTravelGrid(int player, bool ignoreFlames, travelCostGrid& travelGrid,const uint32_t flameGrid[grid_size_x][grid_size_y],const bool dangerGrid[grid_size_x][grid_size_y]);
void updateFlameAndDangerGridsWithBombs(int player,uint32_t flameGrid[grid_size_x][grid_size_y],bool dangerGrid[grid_size_x][grid_size_y]);
void updateDangerGridWithMonstersSickPlayersAndCulDeSacs(int player, bool dangerGrid[grid_size_x][grid_size_y]);
void updateDangerGridWithMonster4CellsTerritories(bool dangerGrid[grid_size_x][grid_size_y]);

bool flameInCell(int x,int y);
Bonus inline bonusInCell(int x,int y)
{
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
	if ((z>=54) && (z<194))
	{
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
	}

	return no_bonus;
}


bool monsterInCell(int x,int y);
bool playerInCell(int x,int y);
bool enemyInCell(int player,int x,int y);
bool enemyAroundCell(int player,int x,int y);
bool isCellCulDeSac(int x,int y);

extern int lastBombGridUpdate;
extern struct bombInfo * bombsGrid[grid_size_x][grid_size_y]; // NULL if no bomb, pointer to the bomb in m.liste_bombe

static void  updateBombGrid(struct bombInfo * bomb) {
	bombsGrid[bomb->x()][bomb->y()]=bomb;
}
int inline updateBombGrid()
{
	memset(bombsGrid, 0, sizeof(bombsGrid));
	iterateOnBombs(updateBombGrid);
	return frameNumber();
}
bool inline bombInCell(int x,int y)
{
	if ((!lastBombGridUpdate) || (frameNumber()!=lastBombGridUpdate)) lastBombGridUpdate=updateBombGrid();
	return (bombsGrid[x][y]!=NULL);
}
bool somethingThatWouldStopFlame(int x,int y);
bool inline mudbrickInCell(int x,int y)
{
	db brickKind=m.truc[x+y*grid_size_x_with_padding];
	return (brickKind==2);
}

bool inline brickInCell(int x,int y)
{
	db brickKind=m.truc[x+y*grid_size_x_with_padding];
	return ((brickKind==1) || ((brickKind>=3) && (brickKind<=11)));
}

bool inline brickOrSkullBonus(int x,int y) {
	if (brickInCell(x,y))
		return true;
	if (mudbrickInCell(x,y))
		return true;
	if (bonusInCell(x,y)==bonus_skull)
		return true;
	return false;
}

bool inline somethingThatIsNoTABombAndThatWouldStopPlayer(int x,int y) {
	if (brickOrSkullBonus(x,y))
		return true;
	if (monsterInCell(x,y))
		return true;
	return false;
}
void updateMonsterIsComingGrid(bool monsterIsComingGrid[NUMBER_OF_CELLS]);
bool canPlayerBeReachedByMonster(int player);
bool canPlayerReachEnemy(int player);
void printCellInfo(int cell);
bool shouldActivateRemote(int player);
