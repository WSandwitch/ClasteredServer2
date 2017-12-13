#include <cstdlib>

#include "moves.h"
#include "../npc.h"
#include "../world.h"

namespace share{
	
	typeof(npc::moves) npc::moves;
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
		char moved=0;
		if (x!=0)
			if (check_point(position.x+x,position.y)){
				set_attr(position.x, position.x+x);
				moved++;
			}
		if (y!=0)
			if (check_point(position.x,position.y+y)){
				set_attr(position.y, position.y+y);
				moved++;
			}
		
		if (bot.used){
//			printf("bot %d on %g %g -> %g %g\n", id, position.x, position.y, bot.goal.x, bot.goal.y);
			if (!moved || position.distanse2(bot.goal)<=3*vel){//for testing
				do_on_map([&](map* m){
					bot.goal.x=(rand()%(((int)m->map_size[0]-20)*100))/100.0+10;
					bot.goal.y=(rand()%(((int)m->map_size[1]-20)*100))/100.0+10;
	//				printf("new goal on %d -> %g %g\n", id, bot.goal.x, bot.goal.y);
					set_dir();
					return 0;
				});
			}
		}
//		update_cells();
	}
	
	//bullet move, go straight for dist, enemy or wall, than suicide
	void npc_moves::move1(typeof(point::x) x, typeof(point::y) y){
		//it is not bot (for disable respawn)
		if (x!=0 || y!=0){
			if (check_point(position.x+x,position.y+y) && (bot.dist<weapon.dist || weapon.dist<=0)){
//				point p=position;
				set_attr(position.x, position.x+x);
				set_attr(position.y, position.y+y);
				bot.dist+=vel;//usualy in full speed//p.distanse(position);
			} else {
				suicide();//suicide
			}
		}
//		printf("%d ?< %d\n", bot.dist, weapon.dist);
	}
	
	//stiky move (move to the same position as target npc)
	void npc_moves::move2(typeof(point::x) x, typeof(point::y) y){
		//char angle=point(1,2).to_angle();
		//can't move independently
		if (bot.target){
			if (bot.target->attrs[bot.target->attr(&bot.target->position.x)]){
				set_attr(position.x, bot.target->position.x);
			}
			if (bot.target->attrs[bot.target->attr(&bot.target->position.y)]){
				set_attr(position.y, bot.target->position.y);
			}
			if (bot.target->attrs[bot.target->attr(&bot.target->angle)]){
				set_attr(angle, bot.target->angle);
			}
		}
	}
}
