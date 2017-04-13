#include "common.hpp"
#include "mrboom.h"
#include "MrboomHelper.hpp"

void addOneAIPlayer() {
	db * keys=m.total_t;
	keys[64+5+m.nombre_de_dyna*7]=1;
	keys[8*7+2]=1;
}

void addXAIPlayers(int x) {
	db * keys=m.total_t;
	for (int i=0; i<x; i++) {
		keys[64+5+i*7]=1;
	}
	keys[8*7+2]=1;
}

void pressStart() {
	db * keys=m.total_t;
	keys[8*7]=1;
	keys[8*7+2]=1;
}

void pressESC() {
	m.sortie=1;
}

bool isInTheApocalypse() {
	return (m.in_the_apocalypse==1);
}

bool hasRollers(int player) {
	return (m.patineur[player]==1);
}

// Warning will be zero if less then 1
int pixelsPerFrame(int player) {
	return CELLPIXELSSIZE/framesToCrossACell(player);
}

int framesToCrossACell(int player) {
	bool speed=hasSpeedDisease(player);
	bool slow=hasSlowDisease(player);
	if (hasRollers(player)) {
		if (slow) return (CELLPIXELSSIZE/2)*4;   //32
		if (speed) return (CELLPIXELSSIZE/2)/4;  //2
		return CELLPIXELSSIZE/2; //8
	} else {
		if (slow) return CELLPIXELSSIZE*4; //64
		if (speed) return CELLPIXELSSIZE/4; //4
		return CELLPIXELSSIZE; //16
	}
}
bool isAlive(int index) {
	return (m.vie[index]==1);
}
bool isAIActiveForPlayer(int player) {
	return ((m.control_joueur[player]>=64) && (m.control_joueur[player]<=64*2));
}


bool hasSlowDisease(int player) {
	return (m.maladie[player*2]==2);
}
bool hasSpeedDisease(int player) {
	return (m.maladie[player*2]==1);
}
bool hasInvertedDisease(int player) {
	return (m.maladie[player*2]==4);
}
bool hasDiarrheaDisease(int player) {
	return (m.maladie[player*2]==3);
}
bool hasSmallBombDisease(int player) {
	return (m.maladie[player*2]==6);
}
bool hasConstipationDisease(int player) {
	return (m.maladie[player*2]==5);
}

int numberOfPlayers() {
	return m.nombre_de_dyna;
}

void chooseLevel(int level) {
	m.viseur_liste_terrain=level;
}

bool isGameActive() {
	if ((m.ordre==1) && (m.ordre2==3)) return true;
	return false;
}
int howManyBombsHasPlayerLeft(int player) {
	if (m.nombre_de_vbl_avant_le_droit_de_poser_bombe) return 0;
	if (hasConstipationDisease(player)) return 0;
	return m.j1[player*5]; //nb of bombs
}

void activeApocalypse() {
	m.temps=2;
}

void activeCheatMode() {
	m.temps=816;
	for (int i=0; i<nb_dyna; i++) {
		m.j1[i*5]=1; //nb of bombs
		m.j1[1+i*5]=5; // power of bombs
		// m.j1[4+i*5]=1; // remote
		if (i>= m.nombre_de_dyna) {
			m.nombre_de_coups[i]=1;
		} else {
			m.nombre_de_coups[i]=99;
		}
	}
	setNoMonsterMode(true);
}
void setNoMonsterMode(bool on) {
	m.nomonster=on;
}


bool bonusPlayerWouldLike(int player,enum Bonus bonus) {
	switch (bonus) {
	case no_bonus:
	case bonus_skull:
		return false;
	default:
		return true;
	}
}

int frameNumber() {
	return m.changement;
}

int flameSize(int player) {
	if (hasSmallBombDisease(player)) {
		return 1;
	} else {
		return m.j1[1+player*5];
	}
}
