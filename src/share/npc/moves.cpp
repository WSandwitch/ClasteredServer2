#include <cstdlib>

#include "moves.h"
#include "../npc.h"
#include "../world.h"

namespace share{
	
	std::map<short, move_func> npc::moves;
	npc_moves npc::_moves;
	
#define addMoveFunc(id)\
	moves[id]=(move_func)&npc_moves::move ## id;
	
	npc_moves::npc_moves(){
		addMoveFunc(0);
		addMoveFunc(1);
		addMoveFunc(2);
	}
#undef addMoveFunc
	
	//common move
	void npc_moves::move0(typeof(point::x) x, typeof(point::y) y){
		if (x!=0)
			if (check_point(position.x+x,position.y)){
				position.x+=x;
				attrs[attr(&position.x)]=1;
			}
		if (y!=0)
			if (check_point(position.x,position.y+y)){
				position.y+=y;
				attrs[attr(&position.y)]=1;
			}
		
		if (bot.used){
//			printf("bot %d on %g %g -> %g %g\n", id, position.x, position.y, bot.goal.x, bot.goal.y);
			if (position.distanse2(bot.goal)<=3*vel){
				bot.goal.x=(rand()%(((int)world->map_size[0]-20)*100))/100.0+10;
				bot.goal.y=(rand()%(((int)world->map_size[1]-20)*100))/100.0+10;
//				printf("new goal on %d -> %g %g\n", id, bot.goal.x, bot.goal.y);
				set_dir();
			}
		}
//		update_cells();
	}
	
	//bullet move, go straight for dist, enemy or wall, than suicide
	void npc_moves::move1(typeof(point::x) x, typeof(point::y) y){
		if (x!=0 && y!=0){
			if (check_point(position.x+x,position.y+y)){
				position.x+=x;
				position.y+=y;
				bot.dist+=vel;
				attrs[attr(&position.x)]=1;
			} else {
				hurt(100);//suicide
			}
		}
		
		if (bot.used){
			//TODO: add check for touch enemy and suicude if need
		}
		//dont need to update cells
	}
	
	//stiky move (move to the same position as target npc)
	void npc_moves::move2(typeof(point::x) x, typeof(point::y) y){
		//char angle=point(1,2).to_angle();
		//can't move independently
		if (bot.used){
			if (bot.target){
				if (bot.target->attrs[bot.target->attr(&bot.target->position.x)]){
					position.x=bot.target->position.x;
					attrs[attr(&position.x)]=1;
				}
				if (bot.target->attrs[bot.target->attr(&bot.target->position.y)]){
					position.y=bot.target->position.y;
					attrs[attr(&position.y)]=1;
				}
			}
			//TODO: add check for touch enemy and suicude if need
		}
	}
}
