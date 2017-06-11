#include "Bot.hpp"
#include "common.hpp"
#include "mrboom.h"
#include "GridFunctions.hpp"
#include <algorithm>

#define IFTRACES ((debugTracesPlayer(_playerIndex)) && (traceMask & DEBUG_MASK_GRIDS))

Bot::Bot(int playerIndex) {
	_playerIndex=playerIndex;
	initBot();
}

void Bot::initBot() {
	calculatedBestCellToDropABomb=0;
	calculatedBestCellToPickUpBonus=0;
	for (int j=0; j<grid_size_y; j++) {
		for (int i=0; i<grid_size_x; i++) {
			bestExplosionsGrid[i][j]=0;
		}
	}
#ifdef DEBUG
	_direction1FrameAgo=button_error;
	_direction2FramesAgo=button_error;
	_shiveringCounter=0;
#endif
}


int Bot::bestBonusCell() {
	if (travelGrid.cost(calculatedBestCellToPickUpBonus)!=TRAVELCOST_CANTGO) {
		return calculatedBestCellToPickUpBonus;
	} else {
		return -1;
	}
}

int scoreForBonus(Bonus bonus,int distance) {
	int distanceMax=100;
	switch (bonus)
	{
	case bonus_push:
	case bonus_remote:
	case bonus_bulletproofjacket:
		distanceMax+=75;
		break;
	case bonus_egg:
	case bonus_heart:
		distanceMax+=150;
		break;
	default:
		break;
	}
	if (distanceMax>distance) {
		return (TRAVELCOST_CANTGO-distance);
	}
	return 0;
}

uint8_t Bot::calculateBestCellToPickUpBonus() {
	int bestCell=-1;
	int bestScore=0;
	for (int j=0; j<grid_size_y; j++) {
		for (int i=0; i<grid_size_x; i++) {
			Bonus bonus=bonusInCell(i,j);
			if (bonusPlayerWouldLike(_playerIndex,bonus)) {
				int score=scoreForBonus(bonus,travelGrid.cost(i,j));
				if (score>bestScore) {
					int cellIndex=CELLINDEX(i,j);
					bestCell=cellIndex;
					bestScore=score;
				}
			}
		}
	}
	if (tracesDecisions(_playerIndex)) log_debug("BOTTREEDECISIONS: %d/%d:bestCell=%d bestScore=%d\n",frameNumber(),_playerIndex,bestCell,bestScore);
	return bestCell;
}

uint8_t Bot::calculateBestCellToDropABomb() {
	uint8_t bestCell=0;
	int bestScore=0;
	int bestTravelCost=TRAVELCOST_CANTGO;
	for (int j=0; j<grid_size_y; j++) {
		for (int i=0; i<grid_size_x; i++) {
			int score=bestExplosionsGrid[i][j];
			int travelCost=travelGrid.cost(i,j);
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

int Bot::bestCellToDropABomb() {
	if (travelGrid.cost(calculatedBestCellToDropABomb)!=TRAVELCOST_CANTGO) {
		return calculatedBestCellToDropABomb;
	} else {
		return -1;
	}
}

int Bot::bestSafeCell() {
	int bestCell=-1;
	int bestScore=0;
	for (int j=0; j<grid_size_y; j++) {
		for (int i=0; i<grid_size_x; i++) {
			if (!somethingThatIsNoTABombAndThatWouldStopPlayer(i,j)) {
				int score=TRAVELCOST_CANTGO-travelGrid.cost(i,j);
				if ((score>bestScore) && (dangerGrid[i][j]==false)) {
					int cellIndex=CELLINDEX(i,j);
					bestCell=cellIndex;
					bestScore=score;
				}
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
	return ((x>-MAX_PIXELS_PER_FRAME/2) && (x<MAX_PIXELS_PER_FRAME/2) && (y<MAX_PIXELS_PER_FRAME/2) && (y>-MAX_PIXELS_PER_FRAME/2));
}

bool Bot::amISafe() {
	int x=xPlayer(_playerIndex);
	int y=yPlayer(_playerIndex);
	return (dangerGrid[x][y]==false);
}

bool Bot::isThereABombUnderMe() {
	int x=xPlayer(_playerIndex);
	int y=yPlayer(_playerIndex);
	return bombInCell(x,y);
}

int Bot::howManyBombsLeft() {
	return howManyBombsHasPlayerLeft(_playerIndex);
}

void Bot::printGrid()
{
	if (IFTRACES) {
		for (int j=0; j<grid_size_y; j++) {
			for (int i=0; i<grid_size_x; i++) {
				db brickKind=m.truc[i+j*grid_size_x_with_padding];
				if (monsterInCell(i,j) || playerInCell(i,j)) {
					if (monsterInCell(i,j)) {
						log_debug("   8(   ");
					} else {
						log_debug("   8)   ");
					}
				} else {
					switch (brickKind) {
					case 1:
						log_debug("[======]");
						break;
					case 2:
						log_debug("(******)");
						break;
					default:
						if (no_bonus!=bonusInCell(i,j)) {
							log_debug("   (%d)  ",bonusInCell(i,j));
						} else {
							log_debug("        ");
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

		log_debug("travelCostGrid %d/%d cell:%d x:%d y:%d adderX=%d adderY=%d\n",frameNumber(),_playerIndex,cellPlayer(_playerIndex), xPlayer(_playerIndex),yPlayer(_playerIndex),GETXPIXELSTOCENTEROFCELL(_playerIndex)*framesToCrossACell(_playerIndex)/CELLPIXELSSIZE,
		          GETYPIXELSTOCENTEROFCELL(_playerIndex)*framesToCrossACell(_playerIndex)/CELLPIXELSSIZE);
		for (int i=0; i<grid_size_x; i++) {
			log_debug("__%03d__ ",i);
		}
		log_debug("\n");
		for (int j=0; j<grid_size_y; j++) {
			for (int i=0; i<grid_size_x; i++) {
				travelGrid.printCell(i,j);
			}
			log_debug("-%03d-",j);
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

void Bot::startPushingJumpButton() {
	mrboom_update_input(button_x,_playerIndex,1,true);
}

void Bot::stopPushingJumpButton() {
	mrboom_update_input(button_x,_playerIndex,0,true);
}

void Bot::startPushingBombDropButton() {
	pushingDropBombButton=true;
	mrboom_update_input(button_b,_playerIndex,1,true);
}

void Bot::stopPushingBombDropButton() {
	pushingDropBombButton=false;
	mrboom_update_input(button_b,_playerIndex,0,true);
}
#ifdef DEBUG
extern int howToGoDebug;
#endif
bool Bot::walkToCell(int cell) {
	#ifdef DEBUG
	howToGoDebug=0;
	#endif
	bool shouldJump=false;
	enum Button direction = howToGo(_playerIndex,CELLX(cell), CELLY(cell), travelGrid, shouldJump);
	#ifdef DEBUG
	if (tracesDecisions(_playerIndex)) {
		char * directionText=(char *)"?";
		switch (direction) {
		case button_up:
			directionText=(char *)"button_up";
			break;
		case button_down:
			directionText=(char *)"button_down";
			break;
		case button_left:
			directionText=(char *)"button_left";
			break;
		case button_right:
			directionText=(char *)"button_right";
			break;
		default:
			break;
		}
		log_debug("BOTTREEDECISIONS: %d/%d:howToGo to %d:%s %d/%d\n",frameNumber(),_playerIndex,cell,directionText,GETXPIXELSTOCENTEROFCELL(_playerIndex),GETYPIXELSTOCENTEROFCELL(_playerIndex));
	}
	#endif
	stopWalking();

	if (shouldJump) {
		startPushingJumpButton();
	}

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

#ifdef DEBUG
#define MAX_SHIVERING 5
	if ((_direction2FramesAgo==direction) && (_direction1FrameAgo!=direction)) {
		_shiveringCounter++;
		if (_shiveringCounter>=MAX_SHIVERING) {
			log_error("shivering on bot %d\n",_playerIndex);
			assert(0);
		}
	} else {
		_shiveringCounter=0;
	}
	_direction2FramesAgo=_direction1FrameAgo;
	_direction1FrameAgo=direction;
#endif
	return (direction!=button_error);
}

int Bot::getCurrentCell() {
	int x=xPlayer(_playerIndex);
	int y=yPlayer(_playerIndex);
	return CELLINDEX(x,y);
}

void Bot::printCellInfo(int cell) {
	log_debug("printCellInfoBot Cell:%d Bot:%d: travelCostGrid=%d bestExplosionsGrid=%d  flameGrid=%d dangerGrid=%d\n", cell,_playerIndex,travelGrid.cost(cell),bestExplosionsGrid[CELLX(cell)][CELLY(cell)],flameGrid[CELLX(cell)][CELLY(cell)],dangerGrid[CELLX(cell)][CELLY(cell)]);
}




