#include <cstdio>
#include <cstdlib>
#include <iostream>
#include <list>
#include <unordered_map>
extern "C"{
#include <math.h>
#include <string.h>
}
#include "npc.h"
#include "system/time.h"
#include "npc/moves.h"
#include "world.h"
#include "messages.h"

using namespace share;

namespace share {
	
	npc::npc(share::world *w, int id, int slave, short type): 
		id(id), 
		state(0), 
		health(1),
		type(type), 
		bot({0}), 
		world(w),
		slave_id(slave),
		cell_id(0)
	{
//		slave_id=slave?:world->id;
//		memset(&bot,0,sizeof(bot));
//		memset(&direction,0,sizeof(direction));
		memset(&_updated,0,sizeof(_updated));
		
		attr.push_back(position.x); //0
		attr.push_back(position.y); //1
		attr.push_back(direction.x); //2
		attr.push_back(direction.y); //3
		attr.push_back(state); //4
		attr.push_back(type); //5
		attr.push_back(slave_id); //6s
		attr.push_back(health); //7c
		attr.push_back(angle); //8
		attr.push_back(bot.goal.x); //9s
		attr.push_back(bot.goal.y); //10s
		attr.push_back(bot.used); //11s
		attr.push_back(move_id); //12s
		attr.push_back(shoot_id); //13s
		
		for(auto i:attr){
			attrs[i.first]=1;
		}
		
		move_id=type;
		timestamp=time(0);
		//TODO: add normal spawn position
		///
		position.x=10;
		position.y=10;
		vel=10;
		r=5;
	}
	
	npc::~npc(){
		for(auto i: cells){
			auto cell=world->map.cells(i);
			cell->npcs.erase(id);
		}
		//add returning of id
	}
		
	bool npc::clear(){
//		if (health<=0 || (time(0)-timestamp>15 && (gridOwner()!=world->id || (!bot.used)))){
//			return 1;
//		}
		
		for(auto i: attrs){
			attrs[i.first]=0;
		}
//		_updated.pack.done=0;
//		_updated.pack.all=0;
//		_updated.pack.server=0;
		memset(&_updated,0,sizeof(_updated));
		return 0;
	}
	
	void npc::attack(){
		//TODO: check	
		short warmup=1000; //set
		short cooldown=1000; //set
		short latency=10; //tiks
		//add attack prepare
		if (state==STATE_WARMUP){//preparing
			if(weapon.temp<NPC_FULL_TEMP){
				weapon.temp+=warmup;
			}else{
				state=STATE_ATTACK;
			}
		}
		if (state==STATE_ATTACK){//attacking
			if (weapon.next_shot==0){
				shoot();
				weapon.next_shot=latency;
			}else{
				weapon.next_shot--;
			}
		}
		if (state==STATE_COOLDOWN){//after attack			
			if(weapon.temp>0){
				weapon.temp-=cooldown;
			}else{
				weapon.temp=0;
				state=STATE_IDLE;
			}
		}
	}
	
	void npc::move(){ //TODO: check if it works
		auto $=moves[move_id];
		if ($)
			(this->*$)(direction.x*vel, direction.y*vel);//TODO:add angle correction
	}
	
	void npc::shoot(){
		auto $=shoots[shoot_id];
		if ($)
			(this->*$)(0, 0);//add useful coordinates
	}
	
#define m world->map
	bool npc::update_cells(){//TODO:improve performance
		int _cell_id=m.to_grid(position.x, position.y);
		if (cell_id!=_cell_id){//if npc move to another cell
			std::unordered_map<int, short> e;
			std::list<int> &&v=m.near_cells(_cell_id, r);
			//set old cells to 2
			for(auto i: cells){
				e[i]=2;
			}
			//inc new cells
			for(auto i: v){
				e[i]++;
			}
			for(auto i: e){
				switch(i.second){
					case 1: //new
						m.cells(i.first)->npcs[id]=this;
						break;
					case 2: //remove
						m.cells(i.first)->npcs.erase(id);
						break;
					case 3: //already has
						break;
				}
			}
			//c->npcs.erase(id);
			cell_id=_cell_id;
			cells=v;
			return 1;
		}
		return 0;
	}
#undef m
	
	void npc::set_dir(){//TODO:remove
		if (bot.used)
			set_dir(bot.goal.x-position.x, bot.goal.y-position.y);
		else
			set_dir(direction.x, direction.y);
	}

	void npc::set_dir(float x, float y){
		set_attr(direction.x, x);
		set_attr(direction.y, y);
		timestamp=share::time(0);
		direction.normalize();
	}
	
	bool npc::hurt(short d){
		set_attr(health, health-d);
		return health<=0;
	}
	
	void npc::hurt(npc* n){
		packet p;
		p.setType(MESSAGE_NPC_HURT);
		p.add(id);
		p.add(n->id);
		world->sock->send(&p);
	}
	
	void npc::update(packet * p){
		for(unsigned i=1;i<p->chanks.size();i++){
			int index=(int)p->chanks[i++].value.c;
			void *pattr=attr(index);
			if (p->chanks[i-1].type!=1)
				printf("chank index type error, got %d\n", p->chanks[i-1].type);
//			printf("index %d\n", index);
			if (index>=0){
				if (pattr){
					if (p->chanks[i].type<6){
//						printf("sizeof chank %d\n",p->chanks[i].size());
						void* data=p->chanks[i].data();
						if (data && p->chanks[i].size()==attr.size(index)){
							if (memcmp(pattr, data, p->chanks[i].size())!=0){
								attrs[index]=1;//updated
								memcpy(pattr, data, p->chanks[i].size());
							}
						}else{//smth wrong with server>server proxy
							printf("npc update corrupt chank on index %d %d\n", (int)index, i);
						}
					}
				}else{
					printf("got strange index %d\n", (int)index);
				}
			}
		}
//		set_dir();
	}
	
	bool npc::updated(){
		for(unsigned i=0;i<attrs.size();i++){
			if (attrs[i]){
				return 1;
			}
		}
		return 0;
	}
	
#define packAttr(p, a, b)\
	do{\
		int $=attr(&(a));\
		if (b || attrs[$]){\
			p.add((char)$);\
			p.add(a);\
		}\
	}while(0)
	
	//need to choose: <0 - static attrs or slave attrs
	void npc::pack(bool server, bool all){
		if (!_updated.pack.done || 
				_updated.pack.server!=server || 
				_updated.pack.all!=all){
			p.init();
			p.setType(MESSAGE_NPC_UPDATE);//npc update
			p.add(id);
			packAttr(p, position.x, all);
			packAttr(p, position.y, all);
			packAttr(p, direction.x, all);
			packAttr(p, direction.y, all);
			packAttr(p, state, all);
			
			packAttr(p, type, all);
			packAttr(p, owner_id, all);
			_updated.pack.all=1;
			if (server){
				packAttr(p, bot.used, all);
				packAttr(p, bot.goal.x, all);
				packAttr(p, bot.goal.y, all);
				_updated.pack.server=1;
			} 
			_updated.pack.done=1;
		}
	}
#undef packAttr
	
//	int npc::gridOwner(){
//		return world->grid->getOwner(position.x, position.y);
//	}
	
//	std::vector<int>& npc::gridShares(){
//		return world->grid->getShares(position.x, position.y);		
//	}
	
	npc* npc::addBot(share::world *world, int id, float x, float y, short type){
		npc* n=new npc(world, id, 0, type);
		n->position.x=x;
		n->position.y=y;
		n->direction.y=0.1;
		n->bot.goal.x=x;
		n->bot.goal.y=y;
		
		n->bot.used=1;
		world->new_npcs_m.lock();
			world->new_npcs.push_back(n);
		world->new_npcs_m.unlock();
		printf("added bot %d on %g, %g\n", n->id, n->position.x, n->position.y);
		return n;
	}
	
	bool npc::check_point(typeof(point::x) x, typeof(point::y) y){
		point p(x,y);
		std::list<int> &&ids=world->map.near_cells(x, y, r); //!check this!
		//printf("segments %d \n", world->map.segments.size());
		for(auto c: ids){//TODO: change to check by map grid
			share::cell *cell=world->map.cells(c);
			for(int i=0,end=cell->segments.size();i<end;i++){//TODO: change to check by map grid
				segment *s=cell->segments[i];
				if(s->distanse(p)<=r){
					//printf("dist \n");
					return 0;
				}
			}
		}
		return 1;
	}

}
