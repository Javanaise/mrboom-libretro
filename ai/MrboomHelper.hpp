#pragma once
#ifdef __cplusplus
extern "C" {
#endif
#define COUNTDOWN_DURATON 256
#define CELLPIXELSSIZE 16
#define grid_size_x_with_padding (32)
#define grid_size_x (grid_size_x_with_padding-13)
#define grid_size_y (13)
#define GETXPLAYER(player) (m.donnee[player]+3)/CELLPIXELSSIZE
#define GETYPLAYER(player) (m.donnee[nb_dyna+player]+14)/CELLPIXELSSIZE
#define GETXPIXELSTOCENTEROFCELL(player) (-7+((m.donnee[player]+3)%CELLPIXELSSIZE))
#define GETYPIXELSTOCENTEROFCELL(player) (-7+((m.donnee[nb_dyna+player]+14)%CELLPIXELSSIZE))
#define CELLINDEX(x,y) y*grid_size_x+x
#define CELLX(cell) cell%grid_size_x
#define CELLY(cell) cell/grid_size_x
#define CELLXWITHPADDING(cell) cell%grid_size_x_with_padding
#define CELLYWITHPADDING(cell) cell/grid_size_x_with_padding
#define TRAVELCOST_CANTGO 9999
#define FLAME_DURATION (16*5+6*4*2)
enum Bonus {
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
bool isInTheApocalypse();
bool isAlive(int index);
bool isAIActiveForPlayer(int player);
void addOneAIPlayer();
void addXAIPlayers(int x);
void pressStart();
void pressESC();
bool hasSlowDisease(int player);
bool hasSpeedDisease(int player);
bool hasInvertedDisease(int player);
bool hasDiarrheaDisease(int player);
bool hasSmallBombDisease(int player);
bool hasConstipationDisease(int player);
int howManyBombsHasPlayerLeft(int player);
bool bonusPlayerWouldLike(int player,enum Bonus bonus);
int numberOfPlayers();
bool isGameActive();
void activeCheatMode();
void activeApocalypse();
void setNoMonsterMode(bool on);
int framesToCrossACell(int player);
int pixelsPerFrame(int player);
int frameNumber();
int flameSize(int player);
void chooseLevel(int level);
void setTeamMode(int teamMode);
int teamMode();

#ifdef __cplusplus
}
#endif
