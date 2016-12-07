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

#define attackCheck(n)\
		(n && n->attackable && n->id!=id)

#define attack(n, n0, a)\
	do{\
		n->hurt(n0);\
		if (a--==0)\
			break;\
	}while(0)\
	
	//melee shot
	void npc_shoots::shoot0(typeof(point::x) x, typeof(point::y) y){
		//init vars
		short ang_diap=60;//weapon.ang_diap//pdegree
		short ang_shift=10;//weapon.ang_shift//pdegree
		short attacks=1;//weapon.attacks
		int dist=20;//weapon.dist

		short ang=angle+ang_shift;

		//for cells
		std::unordered_set<npc*> npcs;
		auto cells=world->map.cells(position, dist);
		for(auto c: cells){
			auto cell=world->map.cells(c);
			for(auto n: cell->npcs)
				if (attackCheck(n.second)){
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
	
	//bullet shot
	//if enemy near self, attack it than suicide
	//bullet r is attack dist
	//bullet weapon.dist is  move dist
	void npc_shoots::shoot1(typeof(point::x) x, typeof(point::y) y){
		short attacks=2;//weapon.attacks;
		
		std::unordered_set<npc*> npcs;
		auto cells=world->map.cells(position, r);
		for(auto c: cells){
			auto cell=world->map.cells(c);
			for(auto n: cell->npcs)
				if (attackCheck(n.second)){
//					printf("added %d !=%d\n", n.second->id, id);
					npcs.insert(n.second);
				}
		}
		for(auto n: npcs){
			if(position.distanse2(n->position)<=sqr(r+n->r)){//hurt if touch
				n->hurt(this);
				if(attacks--==0){
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
		short ang_diap=60;//weapon.ang_diap//pdegree
		short ang_shift=10;//weapon.ang_shift//pdegree
		short attacks=1;//weapon.attacks

		short ang=angle+ang_shift;

		for (auto i =0;i<attacks;i++){
			make_shot((char)(ang+(rand()%(ang_diap)-ang_diap/2)));//calc random angle in diap
		}
	}
	
	
}
