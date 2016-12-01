#include <cstdlib>

#include "shoots.h"
#include "../npc.h"
#include "../world.h"

namespace share{
	
	typeof(npc::shoots) npc::shoots;
	npc_shoots npc::_shoots;

#define addShootFunc(id)\
	shoots[id]=(shoot_func)&npc_shoots::shoot ## id;
	
	npc_shoots::npc_shoots(){
		addShootFunc(0);
		addShootFunc(1);
		addShootFunc(2);
	}
#undef addShootFunc
	
#define attack(n, n0, a)\
	do{\
		n->hurt(n0);\
		if (a--==0)\
			break;\
	}while(0)\
	
	//melee shoot
	void npc_shoots::shoot0(typeof(point::x) x, typeof(point::y) y){
		//init vars
		short ang_diap=60;//pdegree
		short ang_shift=10;//pdegree
		short ang=angle+ang_shift;
		int dist=20;
		int attacks=1;

		//for cells
		std::unordered_set<npc*> npcs;
		auto cells=world->map.cells(position, dist);
		for(auto c: cells){
			auto cell=world->map.cells(c);
			for(auto n: cell->npcs)
				if (n.second && n.second->id!=id){
//					printf("added %d !=%d\n", n.second->id, id);
					npcs.insert(n.second);
				}
		}
		switch(ang_diap){
			case 0:{
				segment s(position, position+point::from_angle(ang, dist));//center
				for(auto n: npcs)
					if (s.distanse(n->position)<=n->r) //check inside circle
						attack(n, this, attacks);
				break;
			}
			case 240:{
				for(auto n: npcs)
					if (position.distanse2(n->position)<=sqr(dist+n->r)) //check near segment
						attack(n, this, attacks);
				break;
			}
			default:{
				segment sr(position, position+point::from_angle(ang-ang_diap/2, dist));//right
				segment sl(position+point::from_angle(ang+ang_diap/2, dist), position);//left
				for(auto n: npcs)
					if (position.distanse2(n->position)<=sqr(dist+n->r) &&
							sr.signed_area2(n->position)>0 && 
							sl.signed_area2(n->position)>0) //check in sector
						attack(n, this, attacks);
				break;
			}
		}
	}
#undef attack
	
	//bullet shoot
	//if enemy near self, attack it than suicide
	void npc_shoots::shoot1(typeof(point::x) x, typeof(point::y) y){
		share::cell *cell=world->map.cells(position);
		if(cell){
			for(auto ni: cell->npcs){
				npc *n=ni.second;
				if(position.distanse2(n->position)<r*r){
					n->hurt(this);
					suicide();
					break;
				}
			}
		}
		
		if (bot.used){
			//TODO: add check for touch enemy and suicude if need
		}
		//dont need to update cells
	}
	
	void npc_shoots::shoot2(typeof(point::x) x, typeof(point::y) y){
		//spawn bullet npcs
		//ask master to spawn
/*
		npc* n=npc::addBot(world, world->getId, position.x, position.y, 1);
		n->keys[3]=(x || y)? point(x,y).to_angle() : keys[3];
		point&& p=point::from_angle(n->keys[3]);
		n->set_dir(p.x, p.y);
*/
	}
	
	
}
