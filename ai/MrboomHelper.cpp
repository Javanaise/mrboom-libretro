#include "common.hpp"
#include "MrboomHelper.hpp"
#pragma GCC diagnostic ignored "-Warray-bounds"

void addOneAIPlayer()
{
   db *keys = m.total_t;

   keys[64 + 5 + m.nombre_de_dyna * 7] = 1;
   keys[8 * 7 + 2] = 1;
   m.nb_ai_bombermen++;
}

void addXAIPlayers(int x)
{
   db *keys = m.total_t;

   for (int i = 0; i < x; i++)
   {
      keys[64 + 5 + i * 7] = 1;
   }
   keys[8 * 7 + 2] = 1;
}

void pressStart()
{
   db *keys = m.total_t;

   keys[8 * 7]     = 1;
   keys[8 * 7 + 2] = 1;
}

void pressESC()
{
   m.sortie = 1;
}

bool isInTheApocalypse()
{
   return(m.in_the_apocalypse == 1);
}

bool hasRollers(int player)
{
   return(m.patineur[player] == 1);
}

bool hasRemote(int player)
{
   return(m.j1[4 + player * 5]);
}

bool hasPush(int player)
{
   return(m.pousseur[player] == 1);
}

bool hasTriBomb(int player)
{
   return(m.tribombe[player] == 1);
}

// Warning will be zero if less then 1
int pixelsPerFrame(int player)
{
   return(CELLPIXELSSIZE / framesToCrossACell(player));
}

int framesToCrossACell(int player)
{
   bool speed = hasSpeedDisease(player);
   bool slow  = hasSlowDisease(player);

   if (hasRollers(player))
   {
      if (slow)
      {
         return((CELLPIXELSSIZE / 2) * 4);           //32
      }
      if (speed)
      {
         return((CELLPIXELSSIZE / 2) / 4); //2
      }
      return(CELLPIXELSSIZE / 2);          //8
   }

   if (slow)
   {
      return(CELLPIXELSSIZE * 4);        //64
   }
   if (speed)
   {
      return(CELLPIXELSSIZE / 4); //4
   }
   return(CELLPIXELSSIZE);        //16
}

int nbLives(int player)
{
   if (isAlive(player))
   {
      return(m.nombre_de_coups[player] + 1);
   }
   else
   {
      return(0);
   }
}

bool isDead(int player)
{
   return(m.vie[player] == 16);
}

bool isAlive(int player)
{
   return(m.vie[player] == 1);
}

bool isAIActiveForPlayer(int player)
{
   return((m.control_joueur[player] >= 64) && (m.control_joueur[player] <= 64 * 2));
}

bool playerGotDisease()
{
   static int current  = 0;
   int        diseases = 0;
   bool       result   = false;

   for (int i = 0; i < numberOfPlayers(); i++)
   {
      if (isAlive(i) && hasAnyDisease(i))
      {
         diseases++;
      }
   }
   if (current < diseases)
   {
      result = true;
   }
   current = diseases;
   return(result);
}

bool hasAnyDisease(int player)
{
   return(m.maladie[player * 2] != 0);
}

bool hasSlowDisease(int player)
{
   return(m.maladie[player * 2] == 2);
}

bool hasSpeedDisease(int player)
{
   return(m.maladie[player * 2] == 1);
}

bool hasInvertedDisease(int player)
{
   return(m.maladie[player * 2] == 4);
}

bool hasDiarrheaDisease(int player)
{
   return(m.maladie[player * 2] == 3);
}

bool hasSmallBombDisease(int player)
{
   return(m.maladie[player * 2] == 6);
}

bool hasConstipationDisease(int player)
{
   return(m.maladie[player * 2] == 5);
}

void setDisease(int player, int disease, int duration)
{
   m.maladie[player * 2]     = disease;
   m.maladie[player * 2 + 1] = duration;
}

int numberOfPlayers()
{
   return(m.nombre_de_dyna);
}

bool replay()
{
   return(m.action_replay != 0);
}

int level()
{
   if (replay())
   {
      return(-1);
   }
   if (inTheMenu())
   {
      return(-1);
   }
   return(m.viseur_liste_terrain);
}

void chooseLevel(int level)
{
   m.viseur_liste_terrain = level;
}

bool inTheMenu()
{
   return((isGameActive() == false) && m.ordre == 'S');
}

bool isGameActive()
{
   if ((m.ordre == 1) && (m.ordre2 == 3))
   {
      return(true);
   }
   return(false);
}

bool isAboutToWin()
{
   return(isGameActive() && (m.attente_avant_med < 100));
}

bool isDrawGame()
{
   return(m.ordre2 == 'D');
}

bool won()
{
   return(m.ordre2 == 'Z');
}

int nbBombsLeft(int player)
{
   if (m.nombre_de_vbl_avant_le_droit_de_poser_bombe)
   {
      return(0);
   }
   if (hasConstipationDisease(player))
   {
      return(0);
   }
   if (isAboutToWin())
   {
      return(0);
   }
   return(m.j1[player * 5]);   //nb of bombs
}

bool isApocalypseSoon()
{
   return(isGameActive() && ((m.temps & 0x3FFF) < 3));
}

void activeApocalypse()
{
   m.temps = 2;
}

int invincibility(int player)
{
   return(m.invinsible[player]);
}

void activeCheatMode()
{
   log_info("activeCheatMode\n");
   m.temps = 10;
   for (db i = 0; i < nb_dyna; i++)
   {
      //		setDisease(i,3,1000); Diarrhea

      /*
       * if (i>= m.nombre_de_dyna)
       *      m.nombre_de_coups[i]=1; //number of lifes
       * else
       *      m.nombre_de_coups[i]=99;
       */

      if (i < m.nombre_de_dyna)
      {
         m.j1[i * 5] = 1;            //nb of bombs
         //m.j1[1+i*5]=5; // power of bombs
         m.j1[4 + i * 5] = 1;        // remote
         m.pousseur[i]   = 1;        // bomb pusher
         m.lapipipino[i] = 1;
         m.nombre_de_coups[i]++;
      }
   }
   setNoMonsterMode(true);
}

void setNoMonsterMode(bool on)
{
   m.nomonster = on;
}

bool bonusPlayerWouldLike(int player, enum Bonus bonus)
{
   switch (bonus)
   {
   case no_bonus:
   case bonus_skull:
   case bonus_time:
      return(false);

   case bonus_roller:
      return(hasRollers(player) == false);

   case bonus_remote:
      return(hasRemote(player) == false);

   case bonus_tribomb:
      return(false);

//		return (hasTriBomb(player)==false);
   case bonus_push:
      return(hasPush(player) == false);

   case bonus_egg:
      return(hasKangaroo(player) == false);

   default:
      break;
   }
   return(true);
}

void setFrameNumber(int frame)
{
   m.changement = frame;
}

int flameSize(int player)
{
   if (hasSmallBombDisease(player))
   {
      return(1);
   }
   return(m.j1[1 + player * 5]);
}

void setTeamMode(int teamMode)
{
   m.team3_sauve = teamMode;
}

int teamMode()
{
   return(m.team3_sauve);
}

void setAutofire(bool on)
{
   if (on)
   {
      m.autofire = 1;
   }
   else
   {
      m.autofire = 0;
   }
}

bool autofire()
{
   return(m.autofire == 1);
}

int xPlayer(int player)
{
   return((m.donnee[player] + DELTA_X) / CELLPIXELSSIZE);
}

int yPlayer(int player)
{
   return((m.donnee[nb_dyna + player] + DELTA_Y) / CELLPIXELSSIZE);
}

int cellPlayer(int player)
{
   return(xPlayer(player) + yPlayer(player) * grid_size_x);
}

bool tracesDecisions(int player)
{
   return(debugTracesPlayer(player) && (traceMask & DEBUG_MASK_BOTTREEDECISIONS));
}

bool isInMiddleOfCell(int player)
{
   int step = pixelsPerFrame(player);

   assert(step <= MAX_PIXELS_PER_FRAME);
   int x = GETXPIXELSTOCENTEROFCELL(player);
   int y = GETYPIXELSTOCENTEROFCELL(player);
   if (step < 1)
   {
      return((!x) && (!y));
   }
   return((x >= -step / 2) && (x <= step / 2) && (y <= step / 2) && (y >= -step / 2));
}

int dangerousCellForMonster(int player)
{
   int cell  = cellPlayer(player);
   int index = m.viseur_change_in[player] / 4;

   index--;
   if (index < 0)
   {
      index = 15;
   }
   switch (m.changeiny[index])
   {
   case 0:
      return(cell + grid_size_x);

   case 8:
      return(cell + 1);

   case 16:
      return(cell - 1);

   case 24:
      return(cell - grid_size_x);
   }
   assert(0);
   return(0);
}

int victories(int player)
{
   int mode = teamMode();

   switch (mode)
   {
   case 0:
      return(m.victoires[player]);

      break;

   case 1:      // color mode
      return(m.victoires[player / 2]);

      break;

   case 2:      // sex mode
      return(m.victoires[player % 2]);

      break;

   case 4:  // skynet mode
      return(m.victoires[isAIActiveForPlayer(player) ? 1 : 0]);

      break;

   default:
      assert(0);
      break;
   }
   return(0);
}

void pauseGameButton()
{
   if (replay())
   {
      pressESC();
      return;
   }
   if (m.pauseur2)
   {
      m.pauseur2 = 0;
   }
   else
   {
      m.pauseur2 = 4;
   }
}

bool isGameUnPaused()
{
   bool        result = false;
   static bool prev   = isGamePaused();

   if ((isGamePaused() == false) && (prev))
   {
      result = true;
   }
   prev = isGamePaused();
   return(result);
}

bool isGamePaused()
{
   return(m.pauseur2 && isGameActive());
}

bool isSuicideOK(int player)
{
   int myTeam         = teamOfPlayer(player);
   int nbLivesEnemies = 0;
   int nbLivesFriends = 0;

   for (int i = 0; i < numberOfPlayers(); i++)
   {
      if (myTeam == teamOfPlayer(i))
      {
         nbLivesFriends += nbLives(i);
         if (invincibility(i))
         {
            nbLivesFriends++;
         }
      }
      if (myTeam != teamOfPlayer(i))
      {
         nbLivesEnemies += nbLives(i);
         if (invincibility(i))
         {
            nbLivesEnemies++;
         }
      }
   }
   return((nbLivesFriends > 1) && (nbLivesEnemies == 1));
}

bool someHumanPlayersAlive() // About to die players are considered dead
{
   for (int i = 0; i < numberOfPlayers(); i++)
   {
      if (isAIActiveForPlayer(i) == false)
      {
         if (isAlive(i))
         {
            return(true);
         }
      }
   }
   return(false);
}

bool someHumanPlayersNotDead() // About to die players are considered alive
{
   for (int i = 0; i < numberOfPlayers(); i++)
   {
      if (isAIActiveForPlayer(i) == false)
      {
         if (!isDead(i))
         {
            return(true);
         }
      }
   }
   return(false);
}
