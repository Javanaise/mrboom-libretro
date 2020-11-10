#include <vector>
#include <algorithm>
#include <queue>
#include "GridFunctions.hpp"
#include "common.hpp"
#include "MrboomHelper.hpp"
#ifndef __LIBRETRO__
#include <strings.h>
#endif

#define liste_bombe_size        (247)
#define INFINITE_SHIELD         1000000
#define COUNTDOWN_APOCALYPSE    64

int  playerGrid[NUMBER_OF_CELLS];
int  killablePlayerGrid[NUMBER_OF_CELLS]; // is there a killable player in a cell
bool humanPlayer[NUMBER_OF_CELLS];        // is there an human player in a cell
int  victoriesGrid[NUMBER_OF_CELLS];      // biggest number of victories for players in cell
int  lastPlayerGridUpdate = 0;

void inline updatePlayerGrid()
{
   if ((!lastPlayerGridUpdate) || (frameNumber() != lastPlayerGridUpdate))
   {
      for (int i = 0; i < NUMBER_OF_CELLS; i++)
      {
         playerGrid[i]         = 0;
         humanPlayer[i]        = false;
         killablePlayerGrid[i] = false;
         victoriesGrid[i]      = 0;
      }
      for (int i = 0; i < numberOfPlayers(); i++)
      {
         if (isAlive(i))
         {
            int cell = cellPlayer(i);
            playerGrid[cell] = teamOfPlayer(i) | playerGrid[cell];
            if (!isAIActiveForPlayer(i))
            {
               humanPlayer[cell] = true;
            }
            if (invincibility(i) < FLAME_DURATION)
            {
               killablePlayerGrid[cell] = teamOfPlayer(i) | playerGrid[cell];
            }
            int v = victories(i);
            if (victoriesGrid[cell] < v)
            {
               victoriesGrid[cell] = v;
            }
         }
      }
      for (int i = numberOfPlayers(); i < nb_dyna; i++)
      {
         if (isAlive(i))
         {
            int cell = cellPlayer(i);
            playerGrid[cell] = monster_team | playerGrid[cell];
         }
      }
      lastPlayerGridUpdate = frameNumber();
   }
}

bool monsterInCell(int x, int y)
{
   updatePlayerGrid();
   return(playerGrid[CELLINDEX(x, y)] & monster_team);
}

bool playerInCell(int x, int y)
{
   updatePlayerGrid();
   return(playerGrid[CELLINDEX(x, y)] & (player_team1 | player_team2 | player_team3 | player_team4 | player_team5 | player_team6 | player_team7 | player_team8));
}

bool playerInCell(int player, int x, int y)
{
   int xp = xPlayer(player);
   int yp = yPlayer(player);

   return((x == xp) && (y == yp));
}

bool killablePlayerNotFromMyTeamInCell(int player, int x, int y)
{
   updatePlayerGrid();
   int notMyTeamMask = (~teamOfPlayer(player)) & (~monster_team);
   return(notMyTeamMask & killablePlayerGrid[CELLINDEX(x, y)]);
}

bool enemyInCell(int player, int x, int y)
{
   updatePlayerGrid();
   if ((x >= grid_size_x - 1) || (!x) || (y >= grid_size_y - 1) || (!y))
   {
      return(false);
   }
   int notMyTeamMask = ~teamOfPlayer(player);
   int cell          = CELLINDEX(x, y);
   return(notMyTeamMask & playerGrid[cell]);
}

bool enemyAroundCell(int player, int x, int y)
{
   updatePlayerGrid();
   if ((x >= grid_size_x - 1) || (!x) || (y >= grid_size_y - 1) || (!y))
   {
      return(false);
   }
   int notMyTeamMask    = ~teamOfPlayer(player);
   int cell             = CELLINDEX(x, y);
   int closeMonsterMask = 0;
   closeMonsterMask = closeMonsterMask | playerGrid[cell];
   closeMonsterMask = closeMonsterMask | playerGrid[cell + 1];
   closeMonsterMask = closeMonsterMask | playerGrid[cell - 1];
   closeMonsterMask = closeMonsterMask | playerGrid[cell - grid_size_x];
   closeMonsterMask = closeMonsterMask | playerGrid[cell - grid_size_x - 1];
   closeMonsterMask = closeMonsterMask | playerGrid[cell - grid_size_x + 1];
   closeMonsterMask = closeMonsterMask | playerGrid[cell + grid_size_x];
   closeMonsterMask = closeMonsterMask | playerGrid[cell + grid_size_x - 1];
   closeMonsterMask = closeMonsterMask | playerGrid[cell + grid_size_x + 1];
   return(notMyTeamMask & closeMonsterMask);
}

bool shouldPlayerFearCulDeSac(int player, int x, int y)
{
   enum Bonus bonus = bonusInCell(x, y);

   if ((bonus == bonus_heart) || (bonus == bonus_egg) || (bonus == bonus_bulletproofjacket))
   {
      return(false);
   }
   if (invincibility(player))
   {
      return(false);                             //TOFIX
   }
   return(true);
}

bool isCellCulDeSac(int x, int y)
{
   if ((x >= grid_size_x - 1) || (!x) || (y >= grid_size_y - 1) || (!y))
   {
      return(false);
   }
   int i = 0;
   if (!(brickOrSkullBonus(x, y + 1) || bombInCell(x, y + 1)))
   {
      i++;
   }
   if (i > 1)
   {
      return(false);
   }
   if (!(brickOrSkullBonus(x, y - 1) || bombInCell(x, y - 1)))
   {
      i++;
   }
   if (i > 1)
   {
      return(false);
   }
   if (!(brickOrSkullBonus(x - 1, y) || bombInCell(x - 1, y)))
   {
      i++;
   }
   if (i > 1)
   {
      return(false);
   }
   if (!(brickOrSkullBonus(x + 1, y) || bombInCell(x + 1, y)))
   {
      i++;
   }
   if (i > 1)
   {
      return(false);
   }
   return(true);
}

static int heuristicDistance(int x, int y, int xP, int yP)
{
   return(abs(x - xP) + abs(y - yP));
}

bool isPlayerFastestToCell(int player, int x, int y)
{
   int xP         = xPlayer(player);
   int yP         = yPlayer(player);
   int myDistance = heuristicDistance(x, y, xP, yP) * framesToCrossACell(player);

   for (int i = 0; i < numberOfPlayers(); i++)
   {
      if (isAlive(i) && (i != player))
      {
         int xP2         = xPlayer(i);
         int yP2         = yPlayer(i);
         int hisDistance = heuristicDistance(x, y, xP2, yP2) * framesToCrossACell(i);
         if (hisDistance < myDistance)
         {
            return(false);
         }
      }
   }
   return(true);
}

bool isSameTeamTwoFastestToCell(int x, int y)
{
   int fatest           = -1;
   int secondFatest     = -1;
   int fatestTeam       = -1;
   int secondFatestTeam = -1;

   for (int i = 0; i < numberOfPlayers(); i++)
   {
      if (isAlive(i))
      {
         int xP2      = xPlayer(i);
         int yP2      = yPlayer(i);
         int distance = heuristicDistance(x, y, xP2, yP2) * framesToCrossACell(i);
         if ((fatest == -1) || (fatest > distance))
         {
            secondFatest     = fatest;
            secondFatestTeam = fatestTeam;
            fatest           = distance;
            fatestTeam       = teamOfPlayer(i);
         }
         else
         {
            if ((secondFatest == -1) || (secondFatest > distance))
            {
               secondFatest     = distance;
               secondFatestTeam = teamOfPlayer(i);
            }
         }
      }
   }
   return(secondFatestTeam == fatestTeam);
}

struct bombInfo *bombsGrid[grid_size_x][grid_size_y];  // NULL if no bomb, pointer to the bomb in m.liste_bombe
int lastBombGridUpdate = 0;

void iterateOnBombs(FunctionWithBombInfo f)
{
   int nbBombs = m.liste_bombe;
   int index   = 0;
   struct bombInfo *bombesInfoArray = (struct bombInfo *)&m.liste_bombe_array;

   while (nbBombs && index < liste_bombe_size)
   {
      if (bombesInfoArray[index].countDown != 0)
      {
         f(&bombesInfoArray[index]);
         nbBombs--;
      }
      index++;
   }
   assert(index < liste_bombe_size);
}

void drawBombFlames(int player, int cell, int flameSize, FunctionWithFlameDrawingHelpfulData f, uint32_t flameGrid[grid_size_x][grid_size_y], bool dangerGrid[grid_size_x][grid_size_y], int&score)
{
   int x = CELLX(cell);
   int y = CELLY(cell);

   f(player, x, y, 0, flameGrid, dangerGrid, score);
   int xx = x;
   int yy = y;
   int fs = flameSize;
   while ((xx > 0) && (fs))
   {
      xx--;
      fs--;
      f(player, xx, yy, flameSize - fs, flameGrid, dangerGrid, score);
      if (somethingThatWouldStopFlame(xx, yy))
      {
         break;
      }
   }
   xx = x;
   yy = y;
   fs = flameSize;
   while ((yy > 0) && (fs))
   {
      yy--;
      fs--;
      f(player, xx, yy, flameSize - fs, flameGrid, dangerGrid, score);
      if (somethingThatWouldStopFlame(xx, yy))
      {
         break;
      }
   }
   xx = x;
   yy = y;
   fs = flameSize;
   while ((xx < grid_size_x - 2) && (fs))
   {
      xx++;
      fs--;
      f(player, xx, yy, flameSize - fs, flameGrid, dangerGrid, score);
      if (somethingThatWouldStopFlame(xx, yy))
      {
         break;
      }
   }
   xx = x;
   yy = y;
   fs = flameSize;
   while ((yy < grid_size_y - 2) && (fs))
   {
      yy++;
      fs--;
      f(player, xx, yy, flameSize - fs, flameGrid, dangerGrid, score);
      if (somethingThatWouldStopFlame(xx, yy))
      {
         break;
      }
   }
}

bool flameInCell(int x, int y)
{
   db z = m.truc2[x + y * grid_size_x_with_padding];

   return((z > 4) && (z < 54));
}

bool somethingThatWouldStopFlame(int x, int y)
{
   if (bonusInCell(x, y) != no_bonus)
   {
      return(true);
   }
   if (brickInCell(x, y))
   {
      return(true);
   }
   if (mudbrickInCell(x, y))
   {
      return(true);
   }
   return(false);
}

#ifdef DEBUG
int howToGoDebug;
int howToGoDebugMax = 1;
#endif
enum Button howToGo(int player, int toX, int toY, const travelCostGrid& travelGrid, bool&shouldJump)
{
   assert(toX >= 0);
   assert(toX < grid_size_x);
   assert(toY >= 0);
   assert(toY < grid_size_y);
   if ((xPlayer(player) == toX) && (yPlayer(player) == toY))
   {
#ifdef DEBUG
      if (tracesDecisions(player))
      {
         log_debug("BOTTREEDECISIONS: player==toX %d %d\n", toX, toY);
      }
#endif
      int adderX = getAdderX(player);
      int adderY = getAdderY(player);
      if (adderX < 0)
      {
         return(button_right);
      }
      if (adderX > 0)
      {
         return(button_left);
      }
      if (adderY > 0)
      {
         return(button_up);
      }
      if (adderY < 0)
      {
         return(button_down);
      }
   }

#ifdef DEBUG
   howToGoDebug++;
   if (howToGoDebug > howToGoDebugMax)
   {
      howToGoDebugMax = howToGoDebug;

      assert(howToGoDebug < 100);
   }
#endif
   enum Button result       = button_error;
   int         cost         = TRAVELCOST_CANTGO;
   int         toXChosen    = -1;
   int         toYChosen    = -1;
   int         adderXChosen = 0;
   int         adderYChosen = 0;
   int         initialCost  = travelGrid.cost(toX, toY);
   int         path         = player % 8;

   for (int lcv = 0; lcv < 4; lcv++)
   {
      int adderX            = 0;
      int adderY            = 0;
      enum Button direction = button_error;
      int calculatedCost    = TRAVELCOST_CANTGO;

      switch (path % 4)
      {
      case 0:  // look to the left
         if (toX > 1)
         {
            adderX    = -1;
            adderY    = 0;
            direction = button_right;
         }
         break;

      case 1:  // look to the right
         if (toX < grid_size_x - 2)
         {
            adderX    = +1;
            adderY    = 0;
            direction = button_left;
         }
         break;

      case 2:  // look to the north
         if (toY > 1)
         {
            adderX    = 0;
            adderY    = -1;
            direction = button_down;
         }
         break;

      case 3:  // look to the south
         if (toY < grid_size_y - 2)
         {
            adderX    = 0;
            adderY    = +1;
            direction = button_up;
         }
         break;
      }
	  
      path += (player < 4) ? +1 : -1;
      if (direction == button_error)
      {
         continue;
      }

      calculatedCost = travelGrid.cost(toX + adderX, toY + adderY, direction);
      if ((calculatedCost < cost) && (initialCost >= calculatedCost))
      {
         toXChosen    = toX + adderX;
         toYChosen    = toY + adderY;
         adderXChosen = adderX;
         adderYChosen = adderY;
         cost         = calculatedCost;
         result       = direction;
      }
   }

   if (result == button_error)
   {
      return(result);
   }

   if ((xPlayer(player) == toXChosen) && (yPlayer(player) == toYChosen))
   {
      return(result);
   }
   else
   {
      if (travelGrid.wouldInvolveJumping(toXChosen, toYChosen, result))                                 // to avoid trying L turns on top of jump
      {
         toXChosen += adderXChosen;
         toYChosen += adderYChosen;
         if ((xPlayer(player) == toXChosen) && (yPlayer(player) == toYChosen))
         {
            if (isInMiddleOfCell(player))
            {
               shouldJump = true;
               return(result);
            }
         }
      }

#ifdef DEBUG
      if (tracesDecisions(player))
      {
         log_debug("-> %d/%d", toXChosen, toYChosen);
      }
#endif
      return(howToGo(player, toXChosen, toYChosen, travelGrid, shouldJump));
   }
}

static bool canPlayerJump(int player, int x, int y, int inVbls, int fromDirection, const uint32_t flameGrid[grid_size_x][grid_size_y], const bool dangerGrid[grid_size_x][grid_size_y])
{
   if (hasKangaroo(player))
   {
      int x2 = x;
      int y2 = y;
      switch (fromDirection)
      {
      case button_right:
         x2++;
         if (x2 > grid_size_x - 1)
         {
            return(false);
         }
         break;

      case button_left:
         assert(x > 0);
         x2--;
         if (x2 < 0)
         {
            return(false);
         }
         break;

      case button_up:
         y2--;
         if (y2 < 0)
         {
            return(false);
         }
         break;

      case button_down:
         y2++;
         if (y2 > grid_size_x - 1)
         {
            return(false);
         }
         break;

      default:
         assert(0);
         break;
      }
      if (dangerGrid[x2][y2])
      {
         return(false);
      }
      if (somethingThatIsNoTABombAndThatWouldStopPlayer(x2, y2))
      {
         return(false);
      }
      int danger = flameGrid[x2][y2] - inVbls;
      if ((danger > 0) && (danger <= FLAME_DURATION))
      {
         return(false);
      }

      return(true);
   }
   else
   {
      return(false);
   }
}

static bool canPlayerWalk(int player, int invincibility, int x, int y, int inVbls, int fromDirection, const uint32_t flameGrid[grid_size_x][grid_size_y], const bool dangerGrid[grid_size_x][grid_size_y])
{
   int danger = flameGrid[x][y] - inVbls;
   int shield = invincibility - inVbls;

   if (dangerGrid[x][y])
   {
      return(false);
   }

   if ((danger > 0) && (danger <= FLAME_DURATION) && (shield <= 0) && (bonusInCell(x, y) != bonus_bulletproofjacket))
   {
      return(false);
   }

   if (brickOrSkullBonus(x, y))
   {
      return(false);
   }

   if ((monsterInCell(x, y)) && (shield <= 0))
   {
      return(false);
   }

   if (bombInCell(x, y))
   {
      if (hasPush(player))
      {
         if ((playerInCell(x, y) || monsterInCell(x, y)))
         {
            return(false);
         }
         int x2 = x;
         int y2 = y;
         switch (fromDirection)
         {
         case button_right:
            assert(x < grid_size_x);
            x2++;
            break;

         case button_left:
            assert(x > 0);
            x2--;
            break;

         case button_up:
            assert(y > 0);
            y2--;
            break;

         case button_down:
            assert(y < grid_size_y);
            y2++;
            break;

         default:
            assert(0);
            return(false);

            break;
         }
         if (bombInCell(x2, y2))
         {
            return(false);
         }
         if (somethingThatIsNoTABombAndThatWouldStopPlayer(x2, y2))
         {
            return(false);
         }
         if (bonusInCell(x2, y2) != no_bonus)
         {
            return(false);
         }
      }
      else
      {
         return(false);
      }
   }
   return(true);
}

// fromDistance is the distance from the bomb center
static int scoreForBombingCell(int player, int x, int y, int fromDistance, int flameSize, bool ignoreBricks)
{
   int result = 0;

   if (killablePlayerNotFromMyTeamInCell(player, x, y))
   {
      if (humanPlayer[CELLINDEX(x, y)])
      {
         result++;                                     // focus on humans
      }
      result += victoriesGrid[CELLINDEX(x, y)];        // focus on players with more victories
      result += 3;
   }

   if (monsterInCell(x, y))
   {
      int monsterScore = 4 * (fromDistance + 1);
      result += monsterScore;
   }

   if (ignoreBricks)
   {
      return(result);
   }

   if (bombInCell(x, y))
   {
      result += 2;
   }

   if (bonusInCell(x, y) == bonus_skull)
   {
      result += 2;
   }

   // dont care about blowing bricks when 1 bomb left and monster in the vicinity
   if ((nbBombsLeft(player) < 2) && canPlayerBeReachedByMonster(player))
   {
      return(result);
   }

   // if has a bullet proof jacket, focus on attacking other players
   if (invincibility(player) > FLAME_DURATION && canPlayerReachEnemy(player))
   {
      return(result);
   }

   if (mudbrickInCell(x, y))
   {
      result++;
      if ((mudbrickInCell(x + 1, y)) || (brickInCell(x + 1, y)))
      {
         result++;
      }
      if ((mudbrickInCell(x - 1, y)) || (brickInCell(x - 1, y)))
      {
         result++;
      }
      if ((mudbrickInCell(x, y - 1)) || (brickInCell(x, y - 1)))
      {
         result++;
      }
      if ((mudbrickInCell(x, y + 1)) || (brickInCell(x, y + 1)))
      {
         result++;
      }
   }
   return(result);
}

static void updateScoreFunctionFunctionWithFlameDrawingHelpfulData(int player, int x, int y, int distance, uint32_t flameGrid[grid_size_x][grid_size_y], bool dangerGrid[grid_size_x][grid_size_y], int&score)
{
   if (!flameGrid[x][y])
   {
      score += scoreForBombingCell(player, x, y, distance, flameSize(player), false);
   }
   flameGrid[x][y] = COUNTDOWN_DURATON + FLAME_DURATION;
}

void updateBestExplosionGrid(int player,
                             uint32_t bestExplosionsGrid[grid_size_x][grid_size_y],
                             const travelCostGrid& travelGrid,
                             const uint32_t flameGrid[grid_size_x][grid_size_y],
                             const bool dangerGrid[grid_size_x][grid_size_y])
{
   // calculate the best place to drop a bomb
   int currentCell = cellPlayer(player);

   for (int j = 0; j < grid_size_y; j++)
   {
      for (int i = 0; i < grid_size_x; i++)
      {
         int score = 0;
         if (
            (dangerGrid[i][j] == false || ((CELLX(currentCell) == i) && (CELLY(currentCell)) == j)) &&            //authorise the current player cell even if it's in the dangerGrid
            travelGrid.canWalk(i, j) &&
            (flameGrid[i][j] == 0 || travelGrid.cost(i, j) > flameGrid[i][j]) &&
            bombInCell(i, j) == false
            )
         {
            uint32_t grid[grid_size_x][grid_size_y];
            memmove(grid, flameGrid, sizeof(grid));
            bool unusedDangerGrid[grid_size_x][grid_size_y];

            drawBombFlames(player, CELLINDEX(i, j), flameSize(player), updateScoreFunctionFunctionWithFlameDrawingHelpfulData, grid, unusedDangerGrid, score);

            // check that there is still a safe place in the grid:
            bool foundSafePlace = false;
            for (int j = 0; j < grid_size_y; j++)
            {
               for (int i = 0; i < grid_size_x; i++)
               {
                  if (dangerGrid[i][j] == false &&
                      travelGrid.canWalk(i, j) &&
                      (grid[i][j] == 0 ||
                       travelGrid.cost(i, j) > grid[i][j])
                      )
                  {
                     foundSafePlace = true;
                  }
               }
            }
            if (!foundSafePlace)
            {
               score = -score;
            }
         }
         bestExplosionsGrid[i][j] = score;
      }
   }
}

static bool apocalyseDangerForCell(int x, int y)
{
   if (isInTheApocalypse())
   {
      db danger = m.truc_fin[x + y * grid_size_x_with_padding];
      if (danger < COUNTDOWN_APOCALYPSE)
      {
         return(true);
      }
   }

   return(false);
}

static void visitCell(int player, bool ignoreFlames, int currentCell,
                      const uint32_t flameGrid[grid_size_x][grid_size_y], const bool dangerGrid[grid_size_x][grid_size_y],
                      int adderX, int adderY, int framesPerCell, int direction, travelCostGrid& travelGrid, std::priority_queue <std::pair <int, int> >&queue, bool visited[NUMBER_OF_CELLS])
{
   int      nextCell;
   uint32_t nextCost  = travelGrid.cost(currentCell) + framesPerCell;
   int      adderCell = 0;

   switch (direction)
   {
   case button_right:
      nextCost += -adderX + abs(adderY);
      adderCell = 1;
      break;

   case button_left:
      nextCost += adderX + abs(adderY);
      adderCell = -1;
      break;

   case button_up:
      nextCost += adderY + abs(adderX);
      adderCell = -grid_size_x;
      break;

   case button_down:
      nextCost += -adderY + abs(adderX);
      adderCell = grid_size_x;
      break;

   default:
      assert(0);
      break;
   }
   nextCell = currentCell + adderCell;
   int      nextCell2 = nextCell + adderCell;
   uint32_t nextCost2 = nextCost + framesPerCell;
   if (!visited[nextCell])
   {
      if (canPlayerWalk(player, ignoreFlames ? INFINITE_SHIELD : invincibility(player) - framesPerCell, CELLX(nextCell), CELLY(nextCell), nextCost, direction, flameGrid, dangerGrid))
      {
         if (nextCost < travelGrid.cost(nextCell))
         {
            travelGrid.setWalkingCost(nextCell, nextCost);
            queue.push(std::pair <int, int>(-nextCost, nextCell));
         }
      }
      else if (!ignoreFlames && (canPlayerJump(player, CELLX(nextCell), CELLY(nextCell), nextCost2, direction, flameGrid, dangerGrid)))
      {
         if ((travelGrid.jumpingCost(nextCell, direction) >= nextCost) && (travelGrid.cost(nextCell2) >= nextCost2))
         {
            travelGrid.setJumpingCost(nextCell, nextCost, direction);
            travelGrid.setWalkingCost(nextCell2, nextCost2);
            queue.push(std::pair <int, int>(-nextCost2, nextCell2));
         }
      }
   }
}

void updateTravelGrid(int player, bool ignoreFlames,
                      travelCostGrid& travelGrid,
                      const uint32_t flameGrid[grid_size_x][grid_size_y],
                      const bool dangerGrid[grid_size_x][grid_size_y])
{
   bool visited[NUMBER_OF_CELLS];

   std::priority_queue <std::pair <int, int> > queue;
   std::pair <int, int> pair;
   travelGrid.init();
   int adderX        = getAdderX(player);
   int adderY        = getAdderY(player);
   int playerCell    = cellPlayer(player);
   int currentCell   = playerCell;
   int framesPerCell = framesToCrossACell(player);

   for (int i = 0; i < NUMBER_OF_CELLS; i++)
   {
      visited[i] = false;
      if (CELLX(i) == 0 || CELLX(i) == grid_size_x - 1 || CELLY(i) == 0 || CELLY(i) == grid_size_y - 1)
      {
         visited[i] = true;
      }
   }

   travelGrid.setWalkingCost(currentCell, 0);

   queue.push(std::pair <int, int> (0, currentCell));
   while (!queue.empty())
   {
      pair = queue.top();
      queue.pop();
      currentCell = pair.second;
      if (!visited[currentCell])
      {
         visited[currentCell] = true;
         visitCell(player, ignoreFlames, currentCell, flameGrid, dangerGrid, adderX, adderY, framesPerCell, button_right, travelGrid, queue, visited);
         visitCell(player, ignoreFlames, currentCell, flameGrid, dangerGrid, adderX, adderY, framesPerCell, button_left, travelGrid, queue, visited);
         visitCell(player, ignoreFlames, currentCell, flameGrid, dangerGrid, adderX, adderY, framesPerCell, button_up, travelGrid, queue, visited);
         visitCell(player, ignoreFlames, currentCell, flameGrid, dangerGrid, adderX, adderY, framesPerCell, button_down, travelGrid, queue, visited);
         adderX = 0;
         adderY = 0;
      }
   }
   travelGrid.setWalkingCost(playerCell, abs(getAdderX(player)) + abs(getAdderY(player)));
}

static void updateFlameAndDangerGridsFunctionFunctionWithThreeInts(int player, int x, int y, int distance, uint32_t flameGrid[grid_size_x][grid_size_y], bool dangerGrid[grid_size_x][grid_size_y], int&countDown)
{
   flameGrid[x][y] = flameGrid[x][y] ? std::min(flameGrid[x][y], uint32_t(countDown)) : countDown;
   if (!countDown)
   {
      dangerGrid[x][y] = true;
   }
}

static std::vector <struct bombInfo *> vec;
static void addBombsIntoVector(struct bombInfo *bomb)
{
   vec.push_back(bomb);
}

static void updateScoreFunctionFunction(int player, int x, int y, int distance, uint32_t flameGrid[grid_size_x][grid_size_y], bool dangerGrid[grid_size_x][grid_size_y], int&score)
{
   score           += scoreForBombingCell(player, x, y, distance, flameSize(player), true);
   dangerGrid[x][y] = true;
}

bool shouldActivateRemote(int player)
{
   if (!hasRemote(player))
   {
      return(false);
   }
   int      score = 0;
   uint32_t unusedFlameGrid[grid_size_x][grid_size_y];
   bool     bombedGrid[grid_size_x][grid_size_y];

   for (int j = 0; j < grid_size_y; j++)
   {
      for (int i = 0; i < grid_size_x; i++)
      {
         bombedGrid[i][j] = false;
      }
   }

   vec.clear();
   iterateOnBombs(addBombsIntoVector);
   for (std::vector <struct bombInfo *>::iterator it = vec.begin(); it != vec.end(); ++it)
   {
      struct bombInfo *bomb = *it;
      int i = bomb->x();
      int j = bomb->y();
      if (bomb->getPlayer() == player)
      {
         drawBombFlames(player, CELLINDEX(i, j), flameSize(player), updateScoreFunctionFunction, unusedFlameGrid, bombedGrid, score);
      }
   }

// chain effect
   for (int z = 0; z < 4; z++)
   {
      for (std::vector <struct bombInfo *>::iterator it = vec.begin(); it != vec.end(); ++it)
      {
         struct bombInfo *bomb = *it;
         int i = bomb->x();
         int j = bomb->y();
         if ((bomb->getPlayer() != player) && (bombedGrid[i][j] == true))
         {
            drawBombFlames(player, CELLINDEX(i, j), flameSize(bomb->getPlayer()), updateScoreFunctionFunction, unusedFlameGrid, bombedGrid, score);
         }
      }
   }
   int myTeam = teamOfPlayer(player);

   if (isSuicideOK(player))
   {
      for (int i = 0; i < numberOfPlayers(); i++)
      {
         if (myTeam != teamOfPlayer(i) && isAlive(i))
         {
            if (bombedGrid[xPlayer(i)][yPlayer(i)])
            {
               log_debug("player %d suicide bombing? trying to kill player %d %d/%d %d/%d\n", player, i, xPlayer(i), yPlayer(i), myTeam, teamOfPlayer(i));
               // check if my team would survive
               int nblives = 0;
               for (int j = 0; j < numberOfPlayers(); j++)
               {
                  if (myTeam == teamOfPlayer(j) && isAlive(j))
                  {
                     nblives += nbLives(j);
                     if (bombedGrid[xPlayer(j)][yPlayer(j)] && (invincibility(j) < FLAME_DURATION))
                     {
                        nblives--;
                     }
                  }
               }
               if (nblives)
               {
                  return(true);
               }
               else
               {
                  log_debug("Cancelled suicide bombing\n");
                  return(false);
               }
            }
         }
      }
   }

   // check if he would touch a friend or himself
   for (int i = 0; i < numberOfPlayers(); i++)
   {
      if (myTeam == teamOfPlayer(i) && isAlive(i))
      {
         if (bombedGrid[xPlayer(i)][yPlayer(i)] && (invincibility(i) < FLAME_DURATION))
         {
            return(false);
         }
      }
   }
   return(score);
}

void updateFlameAndDangerGridsWithBombs(int player, uint32_t flameGrid[grid_size_x][grid_size_y], bool dangerGrid[grid_size_x][grid_size_y])
{
   struct bombInfo possibleShieldRemoteBombsUnderPlayer[nb_dyna];

   for (int j = 0; j < grid_size_y; j++)
   {
      for (int i = 0; i < grid_size_x; i++)
      {
         flameGrid[i][j]  = 0;
         dangerGrid[i][j] = false;
      }
   }
   vec.clear();
   iterateOnBombs(addBombsIntoVector);
// add "virtual bombs" under other players that have remote + shields
   for (int i = 0; i < numberOfPlayers(); i++)
   {
      if (player != i && isAlive(i) && hasRemote(i) && invincibility(i))
      {
         possibleShieldRemoteBombsUnderPlayer[i].remote = 1;
         possibleShieldRemoteBombsUnderPlayer[i].cell(cellPlayer(i));
         possibleShieldRemoteBombsUnderPlayer[i].countDown = 0;
         possibleShieldRemoteBombsUnderPlayer[i].flameSize = flameSize(i);
         vec.push_back(&possibleShieldRemoteBombsUnderPlayer[i]);
      }
   }
//
   for (std::vector <struct bombInfo *>::iterator it = vec.begin(); it != vec.end(); ++it)
   {
      struct bombInfo *bomb = *it;

      int countDown = (int)
                      bomb->countDown + FLAME_DURATION;
      if (bomb->remote)
      {
         countDown = 0;
      }
      int i = bomb->x();
      int j = bomb->y();
      if (flameGrid[i][j])
      {
         countDown = std::min(flameGrid[i][j], uint32_t(countDown));             //this enable bomb explosions chains
      }
      drawBombFlames(player, CELLINDEX(bomb->x(), bomb->y()), bomb->flameSize, updateFlameAndDangerGridsFunctionFunctionWithThreeInts, flameGrid, dangerGrid, countDown);
   }
   for (int j = 0; j < grid_size_y; j++)
   {
      for (int i = 0; i < grid_size_x; i++)
      {
         if (flameInCell(i, j))
         {
            flameGrid[i][j] = FLAME_DURATION;                   //TODO be more precise.
         }
      }
   }
}

void updateDangerGridWithMonstersSickPlayersAndCulDeSacs(int player, bool dangerGrid[grid_size_x][grid_size_y])
{
   for (int i = 0; i < numberOfPlayers(); i++)
   {
      if (isAlive(i) && hasAnyDisease(i) && player != i)
      {
         int cell = cellPlayer(i);
         dangerGrid[CELLX(cell)][CELLY(cell)]     = true;
         dangerGrid[CELLX(cell) - 1][CELLY(cell)] = true;
         dangerGrid[CELLX(cell) + 1][CELLY(cell)] = true;
         dangerGrid[CELLX(cell)][CELLY(cell) - 1] = true;
         dangerGrid[CELLX(cell)][CELLY(cell) + 1] = true;
      }
   }
   for (int i = numberOfPlayers(); i < nb_dyna; i++)
   {
      if (isAlive(i))
      {
         int cell = cellPlayer(i);
         dangerGrid[CELLX(cell)][CELLY(cell)] = true;
      }
   }

   for (int j = 0; j < grid_size_y; j++)
   {
      for (int i = 0; i < grid_size_x; i++)
      {
         if (apocalyseDangerForCell(i, j))
         {
            dangerGrid[i][j] = true;
         }
         else
         {
            if (invincibility(player) > FLAME_DURATION)
            {
               dangerGrid[i][j] = false;
            }
            else
            {
               if ((enemyAroundCell(player, i, j)) && (isCellCulDeSac(i, j)) && shouldPlayerFearCulDeSac(player, i, j))
               {
                  dangerGrid[i][j] = true;
               }
            }
         }
      }
   }
}

void updateMonsterIsComingGrid(bool monsterIsComingGrid[NUMBER_OF_CELLS])
{
   for (int i = 0; i < NUMBER_OF_CELLS; i++)
   {
      monsterIsComingGrid[i] = false;
   }
   for (int i = numberOfPlayers(); i < nb_dyna; i++)
   {
      if (isAlive(i))
      {
         monsterIsComingGrid[dangerousCellForMonster(i)] = true;
      }
   }
}

void updateDangerGridWithMonster4CellsTerritories(bool dangerGrid[grid_size_x][grid_size_y])
{
   static int      frame;
   static bool     init = true;
   static uint32_t noFlameGrid[grid_size_x][grid_size_y];
   static bool     noDangerGrid[grid_size_x][grid_size_y];
   static bool     resultDangerGrid[grid_size_x][grid_size_y];

   if (init)
   {
      for (int j = 0; j < grid_size_y; j++)
      {
         for (int i = 0; i < grid_size_x; i++)
         {
            noFlameGrid[i][j]  = 0;
            noDangerGrid[i][j] = false;
         }
      }
      init  = false;
      frame = frameNumber() - 1;
   }

   if (frame != frameNumber())
   {
      for (int j = 0; j < grid_size_y; j++)
      {
         for (int i = 0; i < grid_size_x; i++)
         {
            resultDangerGrid[i][j] = false;
         }
      }


      for (int monsterIndex = numberOfPlayers(); monsterIndex < nb_dyna; monsterIndex++)
      {
         if (isAlive(monsterIndex))
         {
            int            accessibleCells = 0;
            travelCostGrid travelGrid;
            updateTravelGrid(monsterIndex, true, travelGrid, noFlameGrid, noDangerGrid);
            for (int j = 0; j < grid_size_y; j++)
            {
               for (int i = 0; i < grid_size_x; i++)
               {
                  if (travelGrid.canWalk(i, j))
                  {
                     accessibleCells++;
                  }
               }
            }
            if (accessibleCells <= 4)
            {
               for (int j = 0; j < grid_size_y; j++)
               {
                  for (int i = 0; i < grid_size_x; i++)
                  {
                     if (travelGrid.canWalk(i, j))
                     {
                        resultDangerGrid[i][j] = true;
                     }
                  }
               }
            }
         }
      }
   }

// update ...
   for (int j = 0; j < grid_size_y; j++)
   {
      for (int i = 0; i < grid_size_x; i++)
      {
         if (resultDangerGrid[i][j])
         {
            dangerGrid[i][j] = true;
         }
      }
   }
   frame = frameNumber();
}

bool canPlayerBeReachedByMonster(int player)
{
   static bool     result[nb_dyna];
   static int      frame[nb_dyna];
   static bool     init = true;
   static uint32_t noFlameGrid[grid_size_x][grid_size_y];
   static bool     noDangerGrid[grid_size_x][grid_size_y];

   if (isAlive(player) == false)
   {
      return(false);
   }

   travelCostGrid travelGrid;
   if (init)
   {
      for (int j = 0; j < grid_size_y; j++)
      {
         for (int i = 0; i < grid_size_x; i++)
         {
            noFlameGrid[i][j]  = 0;
            noDangerGrid[i][j] = false;
         }
      }
      init = false;
      for (int i = 0; i < nb_dyna; i++)
      {
         frame[i]  = frameNumber() - 1;
         result[i] = false;
      }
   }

   if (frame[player] != frameNumber())
   {
      frame[player] = frameNumber();
   }
   else
   {
      return(result[player]);
   }
   updateTravelGrid(player, true, travelGrid, noFlameGrid, noDangerGrid);

   for (int j = 0; j < grid_size_y; j++)
   {
      for (int i = 0; i < grid_size_x; i++)
      {
         if (monsterInCell(i, j) && travelGrid.canWalk(i, j))
         {
            result[player] = true;
            return(result[player]);
         }
      }
   }
   result[player] = false;
   return(result[player]);
}

bool canPlayerReachEnemy(int player)
{
   static bool     result[nb_dyna];
   static int      frame[nb_dyna];
   static bool     init = true;
   static uint32_t noFlameGrid[grid_size_x][grid_size_y];
   static bool     noDangerGrid[grid_size_x][grid_size_y];

   if (isAlive(player) == false)
   {
      return(false);
   }

   travelCostGrid travelGrid;
   if (init)
   {
      for (int j = 0; j < grid_size_y; j++)
      {
         for (int i = 0; i < grid_size_x; i++)
         {
            noFlameGrid[i][j]  = 0;
            noDangerGrid[i][j] = false;
         }
      }
      init = false;
      for (int i = 0; i < nb_dyna; i++)
      {
         frame[i]  = frameNumber() - 1;
         result[i] = false;
      }
   }

   if (frame[player] != frameNumber())
   {
      frame[player] = frameNumber();
   }
   else
   {
      return(result[player]);
   }
   updateTravelGrid(player, true, travelGrid, noFlameGrid, noDangerGrid);

   for (int j = 0; j < grid_size_y; j++)
   {
      for (int i = 0; i < grid_size_x; i++)
      {
         if (enemyInCell(player, i, j) && travelGrid.canWalk(i, j))
         {
            result[player] = true;
            return(result[player]);
         }
      }
   }
   result[player] = false;
   return(result[player]);
}

void printCellInfo(int cell, int player)
{
   log_debug("printCellInfo %d: mudbrickInCell=%d brickInCell=%d  bombInCell=%d bonusInCell=%d\n", cell, mudbrickInCell(CELLX(cell), CELLY(cell)), brickInCell(CELLX(cell), CELLY(cell)), bombInCell(CELLX(cell), CELLY(cell)), bonusInCell(CELLX(cell), CELLY(cell)));
}
