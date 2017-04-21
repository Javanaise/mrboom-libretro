#include "Bot.hpp"
#include "common.hpp"
#include "mrboom.h"
#include "GridFunctions.hpp"
#include <algorithm>

Bot::Bot(int playerIndex) {
	_playerIndex=playerIndex;
	traces=false;
	for (int j=0; j<grid_size_y; j++) {
		for (int i=0; i<grid_size_x; i++) {
			bestExplosionsGrid[i][j]=0;
		}
	}
}

int Bot::bestBonusCell() {
	int bestCell=-1;
	int bestScore=0;
	for (int j=0; j<grid_size_y; j++) {
		for (int i=0; i<grid_size_x; i++) {
			Bonus bonus=bonusInCell(i,j);
			if (bonusPlayerWouldLike(_playerIndex,bonus)) {
				int score=TRAVELCOST_CANTGO-travelCostGrid[i][j];
				if ((score>bestScore) && (travelCostGrid[i][j])<100) { // 💔
					int cellIndex=CELLINDEX(i,j);
					bestCell=cellIndex;
					bestScore=score;
				}
			}
		}
	}
	return bestCell;
}

int Bot::bestCellToDropABomb() {
	int bestCell=-1;
	int bestScore=0;
	int bestTravelCost=TRAVELCOST_CANTGO;
	for (int j=0; j<grid_size_y; j++) {
		for (int i=0; i<grid_size_x; i++) {
			int score=bestExplosionsGrid[i][j];
			int travelCost=travelCostGrid[i][j];
			if ((score>bestScore) || (score==bestScore && score && travelCost<bestTravelCost))  {
				int cellIndex=CELLINDEX(i,j);
				bestCell=cellIndex;
				bestScore=score;
				bestTravelCost=travelCost;
			}
		}
	}
	return bestCell;
}
int Bot::bestSafeCell() {
	int bestCell=-1;
	int bestScore=0;
	for (int j=0; j<grid_size_y; j++) {
		for (int i=0; i<grid_size_x; i++) {
			int score=TRAVELCOST_CANTGO-travelCostGrid[i][j];
			if ((score>bestScore) && (dangerGrid[i][j]==false)) {
				int cellIndex=CELLINDEX(i,j);
				bestCell=cellIndex;
				bestScore=score;
			}
		}
	}
	return bestCell;
}

#define MAX_PIXELS_PER_FRAME 8

bool Bot::isInMiddleOfCell()
{
	int step=pixelsPerFrame(_playerIndex);
	assert(step<=MAX_PIXELS_PER_FRAME);
	int x=GETXPIXELSTOCENTEROFCELL(_playerIndex);
	int y=GETYPIXELSTOCENTEROFCELL(_playerIndex);
	if (step<1)
		return ((!x) && (!y));
	return ((x>=-step/2) && (x<=step/2) && (y<=step/2) && (y>=-step/2));
}

bool Bot::isSomewhatInTheMiddleOfCell() {
	int x=GETXPIXELSTOCENTEROFCELL(_playerIndex);
	int y=GETYPIXELSTOCENTEROFCELL(_playerIndex);
	return ((x>-MAX_PIXELS_PER_FRAME) && (x<MAX_PIXELS_PER_FRAME) && (y<MAX_PIXELS_PER_FRAME) && (y>-MAX_PIXELS_PER_FRAME));
}

bool Bot::amISafe() {
	int x=GETXPLAYER(_playerIndex);
	int y=GETYPLAYER(_playerIndex);
	return (dangerGrid[x][y]==false);
}

bool Bot::isThereABombUnderMe() {
	int x=GETXPLAYER(_playerIndex);
	int y=GETYPLAYER(_playerIndex);
	return bombInCell(x,y);
}

int Bot::howManyBombsLeft() {
	return howManyBombsHasPlayerLeft(_playerIndex);
}



void Bot::printGrid()
{
	for (int j=0; j<grid_size_y; j++) {
		for (int i=0; i<grid_size_x; i++) {
			db brickKind=m.truc[i+j*grid_size_x_with_padding];
			if (monsterInCell(i,j) || playerInCell(i,j)) {
				if (monsterInCell(i,j)) {
					log_debug("  8( ");
				} else {
					log_debug("  8) ");
				}
			} else {
				switch (brickKind) {
				case 1:
					log_debug(" [X] ");
					break;
				case 2:
					log_debug(" ( ) ");
					break;
				default:
					if (no_bonus!=bonusInCell(i,j)) {
						log_debug(" (%d) ",bonusInCell(i,j));
					} else {
						log_debug("     ");
					}
					break;
				}
			}
		}
		log_debug("\n");
	}
	log_debug("bestExplosionsGrid player %d\n",_playerIndex);
	for (int j=0; j<grid_size_y; j++) {
		for (int i=0; i<grid_size_x; i++) {
			log_debug("%04d",bestExplosionsGrid[i][j]);
			if (dangerGrid[i][j]) {
				log_debug("x");
			} else {
				log_debug("_");
			}
		}
		log_debug("\n");
	}
	log_debug("travelCostGrid player %d\n",_playerIndex);
	for (int j=0; j<grid_size_y; j++) {
		for (int i=0; i<grid_size_x; i++) {
			log_debug("%04d ",travelCostGrid[i][j]);
		}
		log_debug("\n");
	}
	log_debug("%d dangerZone player %d\n",m.changement,_playerIndex);
	for (int j=0; j<grid_size_y; j++) {
		for (int i=0; i<grid_size_x; i++) {
			log_debug("%04d ",flameGrid[i][j]);
		}
		log_debug("\n");
	}
	log_debug("flamesize:%d lapipipino:%d lapipipino5:%d\n",flameSize(_playerIndex),m.lapipipino[_playerIndex],m.lapipipino5[_playerIndex]);
}

void Bot::stopWalking() {
	mrboom_update_input(button_up,_playerIndex,0,true);
	mrboom_update_input(button_down,_playerIndex,0,true);
	mrboom_update_input(button_left,_playerIndex,0,true);
	mrboom_update_input(button_right,_playerIndex,0,true);
}

void Bot::startPushingRemoteButton() {
	mrboom_update_input(button_a,_playerIndex,1,true);
}


void Bot::stopPushingRemoteButton() {
	mrboom_update_input(button_a,_playerIndex,0,true);
}

void Bot::startPushingBombDropButton() {
	pushingDropBombButton=true;
	mrboom_update_input(button_b,_playerIndex,1,true);
}

void Bot::stopPushingBombDropButton() {
	pushingDropBombButton=false;
	mrboom_update_input(button_b,_playerIndex,0,true);
}

bool Bot::walkToCell(int cell) {
	enum Button direction = howToGo(_playerIndex,CELLX(cell), CELLY(cell), travelCostGrid);
	stopWalking();
	if (hasInvertedDisease(_playerIndex)) {
		switch (direction) {
		case button_up:
			direction=button_down;
			break;
		case button_down:
			direction=button_up;
			break;
		case button_left:
			direction=button_right;
			break;
		case button_right:
			direction=button_left;
			break;
		default:
			break;
		}
	}
	mrboom_update_input(direction,_playerIndex,1,true);
	return (direction!=button_error);
}

int Bot::getCurrentCell() {
	int x=GETXPLAYER(_playerIndex);
	int y=GETYPLAYER(_playerIndex);
	return CELLINDEX(x,y);
}

void Bot::printCellInfo(int cell) {
	log_debug("printCellInfoBot Cell:%d Bot:%d: travelCostGrid=%d bestExplosionsGrid=%d  flameGrid=%d dangerGrid=%d\n", cell,_playerIndex,travelCostGrid[CELLX(cell)][CELLY(cell)],bestExplosionsGrid[CELLX(cell)][CELLY(cell)],flameGrid[CELLX(cell)][CELLY(cell)],dangerGrid[CELLX(cell)][CELLY(cell)]);
}
