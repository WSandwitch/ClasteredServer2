#include <cstdlib>

#include "shoots.h"
#include "../npc.h"
#include "../world.h"

namespace share{
	
	std::map<short, shoot_func> npc::shoots;
	npc_shoots npc::_shoots;

#define addShootFunc(id)\
	shoots[id]=(shoot_func)&npc_shoots::shoot ## id;
	
	npc_shoots::npc_shoots(){
		addShootFunc(0);
		addShootFunc(1);
	}
#undef addShootFunc
	
	//common shoot
	void npc_shoots::shoot0(typeof(point::x) x, typeof(point::y) y){
		//spawn bullet npcs
		//ask master to spawn
/*
		npc* n=npc::addBot(world, world->getId, position.x, position.y, 1);
		n->keys[3]=(x || y)? point(x,y).to_angle() : keys[3];
		point&& p=point::from_angle(n->keys[3]);
		n->set_dir(p.x, p.y);
*/
	}
	
	//bullet shoot
	void npc_shoots::shoot1(typeof(point::x) x, typeof(point::y) y){
		
		
		if (bot.used){
			//TODO: add check for touch enemy and suicude if need
		}
		//dont need to update cells
	}
	
}
