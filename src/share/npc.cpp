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

#define packAttr(a,call,c,sall,s,ts)\
	do{\
		attr.push_back(a);\
		if(call)\
			pack_attrs(0,1).push_back(&a);\
		if(c)\
			pack_attrs(0,0).push_back(&a);\
		if(sall)\
			pack_attrs(1,1).push_back(&a);\
		if(s)\
			pack_attrs(1,0).push_back(&a);\
		if(ts)\
			pack_attrs(1,0,1).push_back(&a);\
	}while(0)

namespace share {

	npc::npc(share::world *w, int id, short t): 
		id(id), 
		state(0), 
		health(100),
		type(t), 
//		bot({0}), 
		angle(0),
		world(w),
		slave_id(0),
		cell_id(0),
		spawn_wait(0),
		attackable(1)
	{
//		slave_id=slave?:world->id;
		memset(&bot,0,sizeof(bot));
		memset(&weapon,0,sizeof(weapon));
//		memset(&direction,0,sizeof(direction));
		
		init_attrs();
		init_position();
		recalculate_type();
	}
	
	npc::~npc(){
		if (world){
			for(auto i: cells){
				auto cell=world->map.cells(i);
				cell->npcs.erase(id);
			}
			world->npcs_m.lock();
				world->old_npcs.insert(id);
			world->npcs_m.unlock();
		
			//respawn with same id
			//if it is bot, or assigned to player
			if (bot.used || (owner_id!=0)){//TODO: add respawn mark
				world->npcs_m.lock();
					world->new_npcs.push_back(clone());
				world->npcs_m.unlock();
			}else{
				world->putId(id);
			}
		}
	}
	
	npc* npc::clone(){
		npc* n=new npc(*this);
		n->clear();
		n->init_attrs();
		n->init_position();
		n->recalculate_type();
		n->damagers.clear();
		//set health and position
		return n;
	}

	bool npc::clear(){
		for(auto i: attrs){
			attrs[i.first]=0;
		}
		for(auto i: _packs){
			_packs.p[i.first]=0;
		}
		if (health<=0){
			return 1;
		}		
		return 0;
	}
	
	void npc::init_attrs(){
		//why it doesn't work from 0?
		/*
			attribute
			all attributes to client
			changes to client
			all attributes to slave
			changes to master, slave can change it
			changes to slave
		*/
		///(attr, client_all, client, master_slave_all, from_slave, to_slave)
		packAttr(position.x,1,1,1,1,0); //1cm
		packAttr(position.y,1,1,1,1,0); //2cm
		packAttr(direction.x,1,1,1,1,1); //3cms
		packAttr(direction.y,1,1,1,1,1); //4cms
		packAttr(state,1,1,1,1,1); //5cms
		packAttr(type,1,1,1,0,1); //6cms
		packAttr(slave_id,0,0,1,0,1); //7ms
		packAttr(health,1,1,0,0,0); //8c
		packAttr(angle,1,1,1,1,1); //9cms
		packAttr(bot.goal.x,0,0,1,1,1); //10ms
		packAttr(bot.goal.y,0,0,1,1,1); //11ms
		packAttr(bot.used,0,0,1,0,1); //12s
		packAttr(move_id,0,0,1,0,1); //13s
		packAttr(shoot_id,0,0,1,0,1); //14s 
		packAttr(attackable,0,0,1,1,1); //15s //TODO: check can be got from info
		for(auto i:attr){
			attrs[i.first]=1;
		}
	}
			
	void npc::init_position(){
		//TODO: add normal spawn position
		//if bot rand in square
		//else nearest safe zone
		
		///for testing
		position.x=20;
		position.y=20;
	}
	
	void npc::recalculate_type(){
		//update dinamic attrs like damage, health from chosen type and other
		move_id=type;
		shoot_id=0;
		timestamp=time(0);
		///for testing
		vel=10;
		r=5;
		weapon.damage=1;
		weapon.dist=30;
	}
	
	//example - shoot_type, warmup, cooldown, latency, angle_diap, attacks
	//chainsaw - 0, 0.5, 0.3, 0.21, 0, 10
	//flamethrower - 0, 2, 2, 0.2,  4, 8
	//axe - 0, 0.8, 0.1, 1.6, 0, 3
	//bat - 0, 0.2, 0.2, 0.8, 70, 1
	//minigun - 1, 2, 2, 0.2, 4, 1
	void npc::attack(){
		//TODO: check	
		short warmup=NPC_FULL_TEMP/world->tps/1; //NPC_FULL_TEMP/world->tps/n -> n seconds to max
		short cooldown=NPC_FULL_TEMP/world->tps/1; //set
		short latency=0.5*world->tps; //tiks
		//add attack prepare
		if (state==STATE_WARMUP){//preparing
//			printf("warmup %hd/%hd\n", weapon.temp,NPC_FULL_TEMP);
			if(weapon.temp<NPC_FULL_TEMP){
				weapon.temp+=warmup;
			}else{
				state=STATE_ATTACK;
			}
		}
		if (state==STATE_ATTACK){//attacking
//			printf("nextshot %hd\n", weapon.next_shot);
			if (weapon.next_shot==0){
				shoot();
				weapon.next_shot=latency;
			}else{
				weapon.next_shot--;
			}
		}
		if (state==STATE_COOLDOWN){//after attack			
//			printf("cooldown %hd\n", weapon.temp);
			if(weapon.temp>0){
				weapon.temp-=cooldown;
			}else{
				weapon.temp=0;
				state=STATE_IDLE;
			}
		}
	}
	
	void npc::move(){
		auto $=moves[move_id];
		if ($){
			auto v=vel*(1-0.4f*PPI/abs(direction.to_angle()-angle));//decrease vel by 0.6 (1-0.4) if we go back
			(this->*$)(direction.x*v, direction.y*v);//TODO:add angle correction
		}
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
	
	void npc::make_shot(char angle){
		packet p;
		p.setType(MESSAGE_NPC_MAKE_SHOT);
		p.add(id);
		p.add(angle);
		world->sock->send(&p);
	}
		
	bool npc::suicide(){
		packet p;
		p.setType(MESSAGE_NPC_SUICIDE);
		p.add(id);
		world->sock->send(&p);
		return 1;
	}
	
	void npc::update(packet * p){
		for(unsigned i=1;i<p->chanks.size();i++){
			int index=(int)p->chanks[i++].value.c;
			void *pattr=attr(index);
			if (p->chanks[i-1].type!=1)
				printf("chank index type error, got %d\n", p->chanks[i-1].type);
//			printf("index %d\n", index);
			if (pattr){
				if (p->chanks[i].type<6){
//					printf("sizeof chank %d\n",p->chanks[i].size());
					void* data=p->chanks[i].data();
					if (data && p->chanks[i].size()==attr.size(index)){
						if (memcmp(pattr, data, p->chanks[i].size())!=0){
//							printf("%d updated\n", index);
							attrs[index]=1;//updated
							memcpy(pattr, data, p->chanks[i].size());
						}
					}else{//smth wrong with server>server proxy
						printf("npc update corrupt chank %d index %d (size %d == %d)\n", i, (int)index, p->chanks[i].size(), attr.size(index));
					}
				}
			}else{
				printf("got strange index %d\n", (int)index);
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
	
#define packAttr0(p, a, b)\
	do{\
		int $=attr(&(a));\
		if (b || attrs[$]){\
			p.add((char)$);\
			p.add(a);\
		}\
	}while(0)
	
	//need to choose: <0 - static attrs or slave attrs
	void npc::pack(bool s, bool all, bool ts){
		if (!_packs(s,all,ts)){
			auto as=pack_attrs(s,all,ts);
//			printf("pack %d %d %d, %d \n", s,all,ts, as.size());
			packet &p=packs(s,all,ts);
			p.init();
			p.setType(MESSAGE_NPC_UPDATE);//npc update
			p.add(id);
			for(auto a: as){
				int $=attr(a);
				if (all || attrs[$]){
					p.add((char)$);
//					printf("added type %d index %d\n", attr.type(a), $);
					switch(attr.type(a)){
						case 1:
							p.add(*(char*)a);
//							printf("added type value %d\n", *(char*)a);
							break;
						case 2:
							p.add(*(short*)a);
//							printf("added type value %d\n", *(short*)a);
							break;
						case 3:
							p.add(*(int*)a);
//							printf("added type value %d\n", *(int*)a);
							break;
						case 4:
							p.add(*(float*)a);
//							printf("added type value %g\n", *(float*)a);
							break;
						case 5:
							p.add(*(double*)a);
//							printf("added type value %lg\n", *(double*)a);
							break;
						default:
							p.add((char)0);
							break;
					}
				}
			}
			_packs(s,all,ts)=1;
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
		npc* n=new npc(world, id, type);
		n->position.x=x;
		n->position.y=y;
		n->direction.y=0.1;
		n->bot.goal.x=x;
		n->bot.goal.y=y;
		
		n->bot.used=1;
		world->npcs_m.lock();
			world->new_npcs.push_back(n);
		world->npcs_m.unlock();
		printf("added bot %d on %g, %g\n", n->id, n->position.x, n->position.y);
		return n;
	}
	
	bool npc::check_point(typeof(point::x) x, typeof(point::y) y){
		point p(x,y);
		std::list<int> &&ids=world->map.near_cells(x, y, r); //!check this!
		std::unordered_set<segment*> done;
		//printf("segments %d \n", world->map.segments.size());
		for(auto c: ids){//TODO: change to check by map grid
			share::cell *cell=world->map.cells(c);
			for(int i=0,end=cell->segments.size();i<end;i++){//TODO: change to check by map grid
				segment *s=cell->segments[i];
				if (done.count(s)==0){ //uniq check
					if(s->distanse(p)<=r){
						//printf("dist \n");
						return 0;
					}
					done.insert(s);
				}
			}
		}
		return 1;
	}

}
