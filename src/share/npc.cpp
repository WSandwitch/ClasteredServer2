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
#include "../share/object.h"

using namespace share;

#define packAttr(a,call,c,sall,s,ts)\
	do{\
		char $=attr.push_back(a);\
		if(call)\
			pack_attrs(0,1).push_back($);\
		if(c)\
			pack_attrs(0,0).push_back($);\
		if(sall)\
			pack_attrs(1,1).push_back($);\
		if(s)\
			pack_attrs(1,0).push_back($);\
		if(ts)\
			pack_attrs(1,0,1).push_back($);\
	}while(0)

namespace share {

	npc::npc(share::world *w, int id, short t): 
		id(id), 
		state(0), 
		health(100),
		_health(100),
		type(1), //player/bot npc by default 
		owner_id(0), 
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
		
		//	testing	
		move_id=t;
		shoot_id=1;
	}
	
	void npc::remove(){
		if (world){
			for(auto i: cells){
				auto cell=world->map->cells(i);
				withLock(cell->m, cell->npcs.erase(id));
			}
			if (world->id==0){//on master
				world->npcs_m.lock();
					world->old_npcs.insert(id);
				world->npcs_m.unlock();
			
				//respawn with same id
				//if it is bot, or assigned to player
				if (bot.used || (owner_id!=0)){//TODO: add respawn mark
					world->npcs_m.lock();
						world->new_npcs.push_back(clone());
					world->npcs_m.unlock();
					printf("%d respawned\n", id);
					return;//no delete
				}else{
	//				printf("%d died\n", id);
					world->putId(id);
				}
			}
		}
		delete this;
	}
	
/*	void npc::operator delete(void *n_){
		npc *n=(npc*)n_;
		printf("delete overloaded\n");
		//TODO: move here destructor body
		::delete n;
	}
*/	
	npc* npc::clone(){//TODO: change to update this attrs and return tjis
		npc* n=this;
		//set health and position
		n->health=n->_health;
		n->spawn_wait=100;
		//cleanup and init
		n->clear();
		for(auto i:n->attr){
			n->attrs[i.first]=1;
		}
		n->init_position();
		n->recalculate_type();
		n->damagers.clear();
		n->bot.dist=0;
		//TODO:check for other attributes need to be cleared
		printf("%d reused\n", id);
//	*((int*)(0))=5;
		return n;
	}

	bool npc::clear(){
		for(auto i: attrs){
			attrs[i.first]=0;//TODO: check for .second=
		}
		for(auto &i: _packs){
			i.done=0;
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
		attr.set_base(this);
		packAttr(position.x,1,1,1,1,1); //1cm
		packAttr(position.y,1,1,1,1,1); //2cm
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
		packAttr(bot.owner_id,0,0,1,0,1); //16s 
		packAttr(weapon.dist,0,0,1,0,1); //17s
		packAttr(weapon.ang_shift,0,0,1,0,1); //18s
		packAttr(weapon.attacks,0,0,1,0,1); //19s
		packAttr(weapon.ang_diap,0,0,1,0,1); //20s
		packAttr(weapon.warmup,0,0,1,0,1); //21s
		packAttr(weapon.cooldown,0,0,1,0,1); //22s
		packAttr(weapon.latency,0,0,1,0,1); //23s
		packAttr(weapon.next_shot,0,0,1,0,1); //24s //??
		packAttr(vel,0,0,1,0,0); //25s 
		for(auto i:attr){
			attrs[i.first]=1;
		}
	}
			
	void npc::init_position(){
		//TODO: add normal spawn position
		//if bot rand in square
		//else nearest safe zone
		
		if (world){
			position=world->map->nearest_safezone(position).rand_point_in();
//			printf("position %g, %g\n", position.x, position.y);
		}else{
			printf("npc without world\n");
			///for testing
			position.x=100;
			position.y=100;
		}
	}
	
	void npc::recalculate_type(){
		//update dinamic attrs like damage, health from chosen type and other
		timestamp=time(0);
		try{
			object *o=object::all.at(weapon_id);
//			weapon.damage=o->weapon.damage;
			weapon.dist=o->weapon.dist;
			weapon.ang_diap=o->weapon.ang_diap;//pdegree
			weapon.ang_shift=o->weapon.ang_shift;//pdegree
			weapon.attacks=o->weapon.attacks;
			weapon.warmup=o->weapon.warmup ? NPC_FULL_TEMP/world->tps/o->weapon.warmup : NPC_FULL_TEMP; //warmup in seconds
			weapon.cooldown=o->weapon.cooldown ? NPC_FULL_TEMP/world->tps/o->weapon.cooldown : NPC_FULL_TEMP;//cooldown in seconds
			weapon.latency=o->weapon.latency;
		}catch(...){}
		
		///for testing
		vel=5;
		r=23;
		weapon.vel=25;
		weapon.damage=1;
		weapon.dist=300;
		weapon.ang_diap=2;//60;//pdegree
		weapon.ang_shift=0;//10;//pdegree
		weapon.attacks=1;//2;//bullets for 1 shot
		if (world){
			weapon.warmup=NPC_FULL_TEMP;//NPC_FULL_TEMP/world->tps/1; //NPC_FULL_TEMP/world->tps/n -> n seconds to max
			weapon.cooldown=0;//NPC_FULL_TEMP/world->tps/1; //set
			weapon.latency=0.3*world->tps; //tiks
		}
	}
	
	//example - shoot_type, warmup, cooldown, latency, angle_diap, attacks
	//chainsaw - 0, 0.5, 0.3, 0.21, 0, 10
	//flamethrower - 0, 2, 2, 0.2,  4, 8
	//axe - 0, 0.8, 0.1, 1.6, 0, 3
	//bat - 0, 0.2, 0.2, 0.8, 70, 1
	//minigun - 1, 2, 2, 0.2, 4, 1
	void npc::attack(){
		//TODO: check	
		short warmup=weapon.warmup;//NPC_FULL_TEMP/world->tps/1; //NPC_FULL_TEMP/world->tps/n -> n seconds to max
		short cooldown=weapon.cooldown;//NPC_FULL_TEMP/world->tps/1; //set
		short latency=weapon.latency;//0.3*world->tps; //tiks
		//add attack prepare
		if (state==STATE_WARMUP){//preparing
//			printf("%d warmup %hd/%hd\n", id, weapon.temp,NPC_FULL_TEMP);
			if(weapon.temp<NPC_FULL_TEMP){
				weapon.temp+=warmup;
			}else{
				state=STATE_ATTACK;
			}
		}
		if (state==STATE_SHOOT)//state for show that npc do shot
			state=STATE_ATTACK;
		if (state==STATE_ATTACK){//attacking
//			printf("%d nextshot %hd\n", id, weapon.next_shot);
			if (weapon.next_shot==0){
//				printf("%d  shoot\n", id);
				shoot();
				state=STATE_SHOOT;
				weapon.next_shot=latency;
			}else{
				weapon.next_shot--;
			}
		}
		if (state==STATE_COOLDOWN){//after attack			
//			printf("%d cooldown %hd\n", id, weapon.temp);
			if(weapon.temp>0){
				weapon.temp-=cooldown;
			}else{
				weapon.temp=0;
				state=STATE_IDLE;
			}
		}
	}

	void npc::attack(bool s){
		set_attr(state,s?STATE_WARMUP:STATE_COOLDOWN);
	}

	float npc::vel_angle(float max){
		short $=abs((short)direction.to_angle()-(short)angle);
		return 1-(1-max)*($>PPI?PPI*2-$:$)/PPI;//decrease vel by max if we go back
	}
	
	void npc::move(){
		try{
			float v=vel*vel_angle(0.43f);
			(this->*(moves.at(move_id)))(direction.x*v, direction.y*v);//TODO:add angle correction
		}catch(...){}
	}
	
	void npc::shoot(){
		try{
			(this->*(shoots.at(shoot_id)))(0, 0);//add useful coordinates
		}catch(...){}
	}
	
	bool npc::update_cells(){//TODO:improve performance
		int _cell_id=world->map->to_grid(position.x, position.y);
		if (cell_id!=_cell_id){//if npc move to another cell
			std::unordered_map<int, short> e;
			std::list<int> &&v=world->map->near_cells(_cell_id, r);
			//set old cells to 2
			for(auto i: cells){
				e[i]=2;
			}
			//inc new cells
			for(auto i: v){
				e[i]++;
			}
			for(auto i: e){
				auto $=world->map->cells(i.first);
				switch(i.second){
					case 1: //new
						withLock($->m, $->npcs[id]=this);
						break;
					case 2: //remove
						withLock($->m, $->npcs.erase(id));
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
	
	void npc::set_dir(){//TODO:remove
		if (bot.used)
			set_dir(bot.goal.x-position.x, bot.goal.y-position.y);
		else
			set_dir(direction.x, direction.y);
	}

	void npc::set_dir(float x, float y, bool to_1){
		set_attr(direction.x, x);
		set_attr(direction.y, y);
		timestamp=share::time(0);
		direction.normalize(to_1);
	}
	
//hurt for d health
	bool npc::hurt(short d){
		set_attr(health, health-d);
		return health<=0;
	}
	
//hurt by n, tell it to master
	void npc::hurt(npc* n){
		packet p;
		p.setType(MESSAGE_NPC_HURT);
		p.add(id);
		p.add(n->id);
		world->sock->send(&p);
	}
	
//tell master want to make shot
	void npc::make_shot(char a){
		packet p;
		p.setType(MESSAGE_NPC_MAKE_SHOT);
		p.add(id);
		p.add(a);
		world->sock->send(&p);
	}
		
//tell master want to die
	bool npc::suicide(){
		packet p;
		p.setType(MESSAGE_NPC_SUICIDE);
		p.add(id);
		world->sock->send(&p);
		return 1;
	}
	
//update attrs by income packet
	void npc::update(packet * p, int update_attrs){
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
						attrs[index]=update_attrs & set_attr(p->chanks[i].type, pattr, data);
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
	
//check if any attrs were changed
	bool npc::updated(bool s, bool all, bool ts){
		if (all)
			return 1;
		auto as=pack_attrs(s,all,ts);
		for(auto $: as){
			if (attrs[$]){
				return 1;
			}
		}
		return 0;
	}
	
	template<class T>
		bool npc::set_attr(void* where, void* what){
			if ((*(T*)where)!=(*(T*)what)){
				(*(T*)where)=(*(T*)what);
				return 1;
			}
			return 0;
		}
		
	set_attr_func npc::set_attr_funcs[6]={0, &npc::set_attr<char>, &npc::set_attr<short>, &npc::set_attr<int>, &npc::set_attr<float>, &npc::set_attr<double>};
	
	bool npc::set_attr(short type, void *attr, void *data){
		return (this->*set_attr_funcs[type])(attr, data);
	}
	

	
	//create packet with attr that have been changed
//s - for server, all - pack all attrs for curr type, ts - to slave(only for to server)
	packet* npc::pack(bool s, bool all, bool ts){
		auto _pack=_packs(s,all,ts);
packet &p=packs(s,all,ts);
		_pack.m.lock();//TODO: move mutex to packet
			if (!_pack.done){
				auto as=pack_attrs(s,all,ts);
	//			printf("pack %d %d %d, %d \n", s,all,ts, as.size());

				p.init();
				p.setType(MESSAGE_NPC_UPDATE);//npc update
				p.add(id);
				for(auto $: as){
					if (all || attrs[$]){//all needs here
						void *a=attr($);
						p.add((char)$);
						p.add(attr.type(a), a);
//						if ($==3 || $==4)
//							printf("sent (%g %g)\n", direction.x,direction.y);
					}
				}
				_pack.done=1;
			}
		_pack.m.unlock();
return &p;
	}


	
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
		segment ps(position,p);
		ps.length(r*3);
		std::list<int> &&ids=world->map->near_cells(x, y, r); //!check this!
		std::unordered_set<segment*> done;
		//printf("segments %d \n", world->map->segments.size());
		for(auto c: ids){//TODO: change to check by map grid
			share::cell *cell=world->map->cells(c);
			for(int i=0,end=cell->segments.size();i<end;i++){//TODO: change to check by map grid
				segment *s=cell->segments[i];
				if (done.count(s)==0){ //uniq check
					if(!s->directed || (s->directed && s->vector(position)<0 && s->cross(&ps)>0)){ //TODO: check is it right
						if(s->distanse(p)<=r){
							//printf("dist \n");
							return 0;
						}
					}
					done.insert(s);
				}
			}
		}
		return 1;
	}

}
