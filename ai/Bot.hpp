#pragma once
#include "MrboomHelper.hpp"
#include "GridFunctions.hpp"


class Bot {
public:
Bot(int playerIndex);
int  bestBonusCell();
int  bestCellToDropABomb();
int  bestSafeCell();
bool isInMiddleOfCell();
bool isSomewhatInTheMiddleOfCell();
bool isThereABombUnderMe();
void stopWalking();
void startPushingBombDropButton();
void startPushingRemoteButton();
void startPushingJumpButton();
void stopPushingBombDropButton();
void stopPushingRemoteButton();
void stopPushingJumpButton();
bool walkToCell(int cell);
bool amISafe();
int getCurrentCell();
void printGrid();
void printCellInfo(int cell);
int howManyBombsLeft();
int _playerIndex;
public:
travelCostGrid travelGrid;
uint32_t bestExplosionsGrid[grid_size_x][grid_size_y];  // score based on the nb of bricks one of my bomb there would break or of the proximity from a monster
uint32_t flameGrid[grid_size_x][grid_size_y];     // 0: no flame, 1..FLAME_DURATION+1: time with a flame, FLAME_DURATION+2: time before end of flame
bool dangerGrid[grid_size_x][grid_size_y]; // used to track all dangers, including the ones we don't know the timing: true means a flame is coming (possibily under a remote controled bomb...), or that a monster is there
bool pushingDropBombButton;
};
