#include "catch.hpp"
#include "MrboomHelper.hpp"
#include "common.hpp"
#include "mrboom.h"
#include "GridFunctions.hpp"

void initBomb(int player,int x,int y,int flameSize,int countDown) {
    struct bombInfo * bombesInfoArray=(struct bombInfo *) &m.liste_bombe_array;
    bombesInfoArray[m.liste_bombe].infojoueur=0;
    bombesInfoArray[m.liste_bombe].countDown=countDown;
    bombesInfoArray[m.liste_bombe].flameSize=flameSize;
    bombesInfoArray[m.liste_bombe].offsetCell=grid_size_x_with_padding*y+x;
    m.liste_bombe++;
}
void initGround() {
  m.liste_bombe=0;
  for (int j=0;j<grid_size_y;j++) {
      for (int i=0;i<grid_size_x;i++) {
        m.truc[i+j*grid_size_x_with_padding]=0;
        if ((i==0) || (i==grid_size_x-1) || (j==grid_size_y-1) || (j==0)) {
            m.truc[i+j*grid_size_x_with_padding]=1; //brick
        }
      }
    }
}
TEST_CASE( "Bomb blow other bombs", "[gridfunctions]" ) {
      int flameGrid[grid_size_x][grid_size_y];
      bool dangerGrid[grid_size_x][grid_size_y];
      int flameSize=3;
      int countDown=100;
      int x1=5;
      int y1=5;
      int x2=x1;
      int y2=y1+1;
      initGround();
      initBomb(0,x1,y1,flameSize,countDown);
      initBomb(0,x2,y2,flameSize,countDown+10);
      updateFlameAndDangerGrids(0,flameGrid,dangerGrid);
      REQUIRE(flameGrid[x1][y1]==countDown+FLAME_DURATION);
      REQUIRE(flameGrid[x1][y1]==flameGrid[x2][y2]);
      REQUIRE(flameGrid[x1][y1]==flameGrid[x2][y2+1]);
      REQUIRE(flameGrid[x1][y1]==flameGrid[x2][y2+2]);
      REQUIRE(flameGrid[x1][y1]==flameGrid[x2][y2+3]);
      REQUIRE(0==flameGrid[x2][y2+4]);
}



TEST_CASE( "X Grid macros are coherents", "[gridmacros]" ) {
    int player=0;
    m.donnee[player]=0;
    m.donnee[nb_dyna+player]=0;
    int savedX=0;
    int savedCell;
    for (int i=0;i<320;i++) {
        m.donnee[player]=i;
        m.donnee[nb_dyna+player]=i;

        int x=GETXPIXELSTOCENTEROFCELL(player);
        int newCellX=GETXPLAYER(player);
        if (i==0) {
            savedX=x;
            savedCell=newCellX;
        } else {
            if (savedCell!=newCellX) {
                REQUIRE((((x<0) && (savedX>0)) || ((x>0) && (savedX<0))));
            }
            savedCell=newCellX;
            savedX=x;
        }
    }
}


TEST_CASE( "Y Grid macros are coherents", "[gridmacros]" ) {
    int player=0;
    m.donnee[player]=0;
    m.donnee[nb_dyna+player]=0;
    int savedY=0;
    int savedCell;
    for (int i=0;i<320;i++) {
        m.donnee[player]=i;
        m.donnee[nb_dyna+player]=i;
        int y=GETYPIXELSTOCENTEROFCELL(player);
        int newCellY=GETYPLAYER(player);
        if (i==0) {
            savedY=y;
            savedCell=newCellY;
        } else {
            if (savedCell!=newCellY) {
                REQUIRE((((y<0) && (savedY>0)) || ((y>0) && (savedY<0))));
            }
            savedCell=newCellY;
            savedY=y;
        }
    }
}
