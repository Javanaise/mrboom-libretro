#pragma once
#include "mrboom.h"
#include "common.hpp"
#include "MrboomHelper.hpp"
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
	int x() {
		return CELLXWITHPADDING(offsetCell);
	};
	int y() {
		return CELLYWITHPADDING(offsetCell);
	};
} bombInfo;
#pragma pack(pop)
enum Button howToGo(int player,int toX,int toY,const int travelGrid[grid_size_x][grid_size_y]);
bool isPlayerTheClosestPlayerFromThatCell(int player, int x,int y);
typedef void (*FunctionWithBombInfo)(struct bombInfo *);
void iterateOnBombs(FunctionWithBombInfo f);
typedef void (*FunctionWithThreeInts)(int, int, int);
void drawBombFlames(int cell, int flameSize, FunctionWithThreeInts f);
void updateBestExplosionGrid(int player, uint32_t bestExplosionsGrid[grid_size_x][grid_size_y], int const travelGrid[grid_size_x][grid_size_y],const int flameGrid[grid_size_x][grid_size_y],const bool dangerGrid[grid_size_x][grid_size_y]);
void updateTravelGrid(int player, int travelGrid[grid_size_x][grid_size_y],const int flameGrid[grid_size_x][grid_size_y]);
void updateFlameAndDangerGrids(int player,int flameGrid[grid_size_x][grid_size_y],bool dangerGrid[grid_size_x][grid_size_y]);
bool flameInCell(int x,int y);
Bonus bonusInCell(int x,int y);
bool monsterInCell(int x,int y);
bool playerInCell(int x,int y);
bool bombInCell(int x,int y);
bool somethingThatWouldStopFlame(int x,int y);
bool somethingThatWouldStopPlayer(int x,int y);
bool mudbrickInCell(int x,int y);
void printCellInfo(int cell);
