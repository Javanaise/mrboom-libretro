#pragma once
#include <stdint.h>
#include "mrboom.h"
#include "common.hpp"
#ifndef DEBUG
#define NDEBUG
#endif
#include "assert.h"
#ifdef __cplusplus
extern "C" {
#endif

#define DELTA_X                     3
#define DELTA_Y                     14
#define COUNTDOWN_DURATON           256
#define CELLPIXELSSIZE              16
#define grid_size_x_with_padding    (32)
#define grid_size_x                 (grid_size_x_with_padding - 13)
#define grid_size_y                 (13)
#define NUMBER_OF_CELLS             (grid_size_x * grid_size_y)
#define GETXPIXELSTOCENTEROFCELL(player)    (-7 + ((m.donnee[player] + DELTA_X) % CELLPIXELSSIZE))
#define GETYPIXELSTOCENTEROFCELL(player)    (-7 + ((m.donnee[nb_dyna + player] + DELTA_Y) % CELLPIXELSSIZE))
#define CELLINDEX(cellx, celly)             (((celly) * grid_size_x) + (cellx))
#define CELLX(cell)                         (cell % grid_size_x)
#define CELLY(cell)                         (cell / grid_size_x)
#define CELLXWITHPADDING(cell)              (cell % grid_size_x_with_padding)
#define CELLYWITHPADDING(cell)              (cell / grid_size_x_with_padding)
#define TRAVELCOST_CANTGO       9999
#define FLAME_DURATION          (16 * 5 + 6 * 4 * 2)
#define MAX_PIXELS_PER_FRAME    8

enum Bonus
{
   no_bonus,
   bonus_bomb,
   bonus_flame,
   bonus_skull,
   bonus_bulletproofjacket,
   bonus_heart,
   bonus_remote,
   bonus_push,
   bonus_roller,
   bonus_time,
   bonus_tribomb,
   bonus_banana,
   bonus_egg
};

bool someHumanPlayersAlive();
bool someHumanPlayersNotDead();
bool isInTheApocalypse();
bool isAlive(int player);
bool isAIActiveForPlayer(int player);
void addOneAIPlayer();
void addXAIPlayers(int x);
void pressStart();
void pressESC();

bool inline hasKangaroo(int player)
{
   return(m.lapipipino[player] == 1);
}

bool hasRemote(int player);
bool hasRollers(int player);
bool hasPush(int player);
bool hasTriBomb(int player);
bool hasAnyDisease(int player);
bool hasSlowDisease(int player);
bool hasSpeedDisease(int player);
bool hasInvertedDisease(int player);
bool hasDiarrheaDisease(int player);
bool hasSmallBombDisease(int player);
bool hasConstipationDisease(int player);
void setDisease(int player, int disease, int duration);
int nbBombsLeft(int player);
bool bonusPlayerWouldLike(int player, enum Bonus bonus);
int numberOfPlayers();
bool inTheMenu();
bool isGameActive();
bool isAboutToWin();
bool isDrawGame();
bool won();
void activeCheatMode();
void activeApocalypse();
bool isApocalypseSoon();
bool playerGotDisease();
void setNoMonsterMode(bool on);
int invincibility(int player);
int framesToCrossACell(int player);
int pixelsPerFrame(int player);

int inline frameNumber()
{
   return(m.changement);
}

void setFrameNumber(int frame);
int flameSize(int player);
void chooseLevel(int level);
bool replay();
int level();
void setTeamMode(int teamMode);
int teamMode();
void setAutofire(bool on);
bool autofire();
void pauseGameButton();
bool isGamePaused();
bool isGameUnPaused();
int xPlayer(int player);
int yPlayer(int player);
int cellPlayer(int player);
bool tracesDecisions(int player);
bool isInMiddleOfCell(int player);
int dangerousCellForMonster(int player);
int victories(int player);

int inline getAdderX(int player)
{
   return(GETXPIXELSTOCENTEROFCELL(player) * framesToCrossACell(player) / CELLPIXELSSIZE);
}

int inline getAdderY(int player)
{
   return(GETYPIXELSTOCENTEROFCELL(player) * framesToCrossACell(player) / CELLPIXELSSIZE);
}

bool isSuicideOK(int player);
int nbLives(int player);


enum playerKind
{
   player_team1 = 1,
   player_team2 = 2,
   player_team3 = 4,
   player_team4 = 8,
   player_team5 = 16,
   player_team6 = 32,
   player_team7 = 64,
   player_team8 = 128,
   monster_team = 256
};

enum playerKind inline teamOfPlayer(int player)
{
   if (player >= numberOfPlayers())
   {
      return(monster_team);
   }
   else
   {
      return(static_cast <playerKind>(1 << m.team[player]));
   }
}

#ifdef __cplusplus
}
#endif
