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
#include "object.h"
#include "system/time.h"
#include "npc/moves.h"
#include "world.h"
#include "messages.h"
#include "../share/object.h"
#include "../share/system/log.h"

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
		non_target(0),
		health(10),
		_health(10),
		type(1), //base id
		weapon_id(1), //TODO:set 
		body_id(0),
		head_id(0),
		bullet_id(2), //TODO:set 
		owner_id(0),
		map_id(0), 
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
//		recalculate_type();//TODO: move outside
//		restore_attrs();//TODO: move outside
		//	testing	
		move_id=0;
		shoot_id=1;
	}
	
	void npc::remove(){
		if (world){
			do_on_map([&](map* m)->int{
				for(auto i: cells){
					auto cell=m->cells(i);
					withLock(cell->m, cell->npcs.erase(id));
				}
				return 0;
			});
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
//					printf("%d died\n", id);
					world->putId(id);
//					printf("new npcs: %d\n", world->new_npcs.size());
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
	npc* npc::clone(){
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
		n->restore_attrs();
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
		packAttr(position.x,1,1,1,1,1); //1
		packAttr(position.y,1,1,1,1,1); //2
		packAttr(direction.x,1,1,1,1,1); //3
		packAttr(direction.y,1,1,1,1,1); //4
		packAttr(state,1,1,1,1,1); //5
		packAttr(type,1,1,1,0,1); //6
		packAttr(slave_id,0,0,1,0,1); //7
		packAttr(health,1,1,0,0,0); //8
		packAttr(angle,1,1,1,1,1); //9
		packAttr(bot.goal.x,0,0,1,1,1); //10
		packAttr(bot.goal.y,0,0,1,1,1); //11
		packAttr(bot.used,0,0,1,0,1); //12
		packAttr(move_id,0,0,1,0,1); //13
		packAttr(shoot_id,0,0,1,0,1); //14
		packAttr(attackable,0,0,1,1,1); //15 //TODO: check can be got from info
		packAttr(bot.owner_id,0,0,1,0,1); //16 
		packAttr(weapon.dist,0,0,1,0,1); //17
		packAttr(weapon.ang_shift,0,0,1,0,1); //18
		packAttr(weapon.attacks,0,0,1,0,1); //19
		packAttr(weapon.ang_diap,0,0,1,0,1); //20
		packAttr(weapon.warmup,0,0,1,0,1); //21
		packAttr(weapon.cooldown,0,0,1,0,1); //22
		packAttr(weapon.latency,0,0,1,0,1); //23
		packAttr(weapon.next_shot,0,0,1,0,1); //24 //??
		packAttr(vel,1,0,1,0,0); //25s 
		packAttr(r,1,0,1,0,0); //26s 
		packAttr(map_id,0,0,1,0,1); //27s 
		packAttr(weapon_id,1,1,0,0,0); //28s 
		packAttr(bullet_id,1,1,0,0,0); //29s 
		packAttr(portalled,0,0,1,1,1); //30s 
		packAttr(weapon.ricochet,0,0,1,0,1); //31s 
		for(auto i:attr){
			attrs[i.first]=1;
		}
	}
			
	void npc::init_position(){
		//TODO: add normal spawn position
		//if bot rand in square
		//else nearest safe zone
		
		if (world){
			do_on_map([&](map* m)->int{
				position=m->nearest_safezone(position).rand_point_in();
				return 0;
			});
//			printf("position %g, %g\n", position.x, position.y);
		}else{
			printf("npc %d without world\n", id);
			///for testing
			position.x=100;
			position.y=100;
		}
	}
	
#define apply_objectM(name)\
	try{ \
		apply(object::all.at(name##_id)); \
	}catch(...){\
		printf("couldn't find %s with id %d\n", #name, name##_id);\
		name##_id=0;\
	}

	void npc::recalculate_type(){
		//update dinamic attrs like damage, health from chosen type and other
		timestamp=time(0);
		///for testing
//		vel=5;
//		r=23;
//		weapon.r=3;
//		weapon.vel=35;
//		weapon.damage=1;
//		weapon.dist=1300;
//		weapon.ang_diap=2;//60;//degree
//		weapon.ang_shift=0;//10;//degree
//		weapon.attacks=1;//2;//bullets for 1 shot
		_health=0;

		vel=0;
		r=0;
		memset(&weapon,0,sizeof(weapon));
		
		apply_objectM(weapon)
		apply_objectM(body)
		apply_objectM(head)
		//apply other objects
		
		weapon.ang_diap=PPI/360*(weapon.ang_diap);// to pdegree
		weapon.ang_shift=PPI/360*(weapon.ang_shift);//pdegree
		if (world){
			weapon.warmup=weapon.warmup>0 ? NPC_FULL_TEMP/(world->slave_tps*weapon.warmup) : NPC_FULL_TEMP;
			weapon.cooldown=weapon.cooldown>0 ? NPC_FULL_TEMP/(world->slave_tps*weapon.cooldown) : NPC_FULL_TEMP;
			weapon.latency=world->slave_tps*weapon.latency;
		}
	}
	
	void npc::restore_attrs(){
		health=_health;
	}

	#define update_attrs(a, b)\
		case a:{\
			switch(mod.type){\
				case OMODTYPE::MUL:{\
					set_attr(b, b*(typeof(b))mod.value);\
					break;\
				}\
				case OMODTYPE::ADD:{\
					set_attr(b, b+(typeof(b))mod.value);\
					break;\
				}\
				case OMODTYPE::MAX:{\
					set_attr(b, (b>mod.value)?b:(typeof(b))mod.value);\
					break;\
				}\
			}\
			/*printf("npc %d %s set %g now %g\n",id,#b,mod.value,(float)b);*/\
			break;\
		}
	void npc::apply(object *o){
		weapon.bullet_offset+=o->offset;
		for (auto &mod:o->mods){
			switch (mod.attr){
				update_attrs(OMODATTR::HEALTH, _health)
				update_attrs(OMODATTR::R, r)
				update_attrs(OMODATTR::VEL, vel)
				update_attrs(OMODATTR::DIST, weapon.dist)
				update_attrs(OMODATTR::DAMAGE, weapon.damage)
				update_attrs(OMODATTR::SHOOT_ANG_DIAP, weapon.ang_diap)
				update_attrs(OMODATTR::SHOOT_ANG_SHIFT, weapon.ang_shift)
				update_attrs(OMODATTR::SHOOT_ATTACKS, weapon.attacks)
				update_attrs(OMODATTR::SHOOT_WARMUP, weapon.warmup)
				update_attrs(OMODATTR::SHOOT_COOLDOWN, weapon.cooldown)
				update_attrs(OMODATTR::SHOOT_LATENCY, weapon.latency)
				update_attrs(OMODATTR::WEAPON_RICOCHET, weapon.ricochet)
			}
		}
	}
	
	#undef update_attrs
	
	//example - shoot_type, warmup, cooldown, latency, angle_diap, attacks
	//chainsaw - 0, 0.5, 0.3, 0.21, 0, 10
	//flamethrower - 0, 2, 2, 0.2,  4, 8
	//axe - 0, 0.8, 0.1, 1.6, 0, 3
	//bat - 0, 0.2, 0.2, 0.8, 70, 1
	//minigun - 1, 2, 2, 0.2, 4, 1
	///slave
	void npc::attack(){
		//TODO: check	
		register int warmup=weapon.warmup;//NPC_FULL_TEMP/(world->tps*weapon.warmup); //NPC_FULL_TEMP/world->tps/n -> n seconds to max
		register int cooldown=weapon.cooldown;//NPC_FULL_TEMP/(world->tps*weapon.cooldown);//NPC_FULL_TEMP/world->tps/1; //set
		register int latency=weapon.latency;//tiks
		//add attack prepare
		if (state==STATE_WARMUP){//preparing
//			printf("%d warmup %d/%hd | %d\n", id, weapon.temp, NPC_FULL_TEMP, warmup);
			weapon.temp+=warmup;
			if(weapon.temp>=NPC_FULL_TEMP){
				state=STATE_ATTACK;
//				weapon.next_shot=0;
			}
		}
		if (state==STATE_SHOOT)//state for show that npc do shot
			state=STATE_ATTACK;
		if (state==STATE_ATTACK){//attacking
//			printf("%d nextshot %hd\n", id, weapon.next_shot);
			if (weapon.next_shot==0){
//				printf("%d  shoot\n", id);
				state=STATE_SHOOT;
				shoot();
				weapon.next_shot=latency>60000 ? 60000 : latency; //max latency 60000 tiks
			}
		}
		if (weapon.next_shot>0){
			weapon.next_shot--;
		}
		if (state==STATE_COOLDOWN){//after attack			
//			printf("%d cooldown %d/0 | \n", id, weapon.temp, cooldown);
			weapon.temp-=cooldown;
			if(weapon.temp<=0){
				weapon.temp=0;
				state=STATE_IDLE;
			}
		}
	}

	//toggle attack
	///master
	void npc::attack(bool s){
		set_attr(state,s?STATE_WARMUP:STATE_COOLDOWN);
	}

	//velocity depends on angle
	float npc::vel_angle(float max){
		register short $=abs((short)direction.to_angle()-(short)angle);
		return 1-(1-max)*($>PPI?PPI*2-$:$)/PPI;//decrease vel by max if we go back
	}
	
	void npc::move(){
		//teleport if needed
		set_attr(portalled, do_on_map([&](map* m)->int{
			auto &&c=m->cells(position);
			for(auto &&p:c->portals){
				if(p->area.contains(position)){
					if (!portalled){
						point shift=position-p->area.a;
						//printf("teleport! (%g %g)[%g %g] %g %g\n", position.x, position.y, p->area.a.x, p->area.a.y, shift.x, shift.y);
						try{
							auto &&$=m->portals.at(p->target)->area.a+shift;
							set_attr(position.x, $.x);
							set_attr(position.y, $.y);
						}catch(...){}
					}
					return 1;
				}
			}
			return 0;
		}));
		
		try{
			register float v=vel*vel_angle(0.43f);
			(this->*(moves.at(move_id)))(direction.x*v, direction.y*v);//TODO:add angle correction
		}catch(...){}
	}
	
	void npc::shoot(){
		try{
			(this->*(shoots.at(shoot_id)))(0, 0);//add useful coordinates
		}catch(...){}
	}
	
	bool npc::update_cells(){//TODO:improve performance
		return do_on_map([&](map* m)->int{
			int _cell_id=m->to_grid(position.x, position.y);
			if (cell_id!=_cell_id){//if npc move to another cell
				std::unordered_map<int, short> e;
				std::list<int> &&v=m->near_cells(_cell_id, r);
				//set old cells to 2
				for(auto i: cells){
					e[i]=2;
				}
				//inc new cells
				for(auto i: v){
					e[i]++;
				}
				for(auto i: e){
					auto $=m->cells(i.first);
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
		});
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
	///master
	bool npc::hurt(short d){
		set_attr(health, health-d);
		return health<=0;
	}
	
	//hurt by n, tell it to master
	///slave
	void npc::hurt(npc* n){
		packet p;
		p.setType(MESSAGE_NPC_HURT);
		p.add(id);
		p.add(n->id);
		world->sock->send(&p);
	}
	
	//tell master want to make shot
	///slave
	void npc::make_shot(char a){
		packet p;
		p.setType(MESSAGE_NPC_MAKE_SHOT);
		p.add(id);
		p.add(a);
		world->sock->send(&p);
	}
		
	//tell master want to die
	///slave
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
	
	//set attr by pointer and type
	bool npc::set_attr(short type, void *attr, void *data){
		return (this->*set_attr_funcs[type])(attr, data);
	}
	

	
	//create packet with attr that have been changed
//s - for server, all - pack all attrs for curr type, ts - to slave(only for to server)
	packet* npc::pack(bool s, bool all, bool ts, int timestamp){
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
				if (timestamp){
					p.add((char)0); //zero attr is timestamp
					p.add(timestamp); //zero attr is timestamp
				}
			}
		_pack.m.unlock();
		return &p;
	}
	
	npc* npc::addBot(share::world *world, int id, float x, float y, short type){
		npc* n=new npc(world, id, type);
		//set ids
		n->recalculate_type();
		n->restore_attrs();
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
	
	//check can npc move to point
	bool npc::check_point(typeof(point::x) x, typeof(point::y) y, std::function<bool(point&,segment*)> &&callback){
		return do_on_map([&](map* m)->int{
			point p(x,y);
			segment ps(position,p);
			//ps.length(ps.length()+r*2);
			segment pshalf(ps);
			float halfl=pshalf.length()/2.0f;
			pshalf.length(halfl);
			//printf("[%g %g | %g %g] [%g %g %g]\n", ps.a.x, ps.a.y, ps.b.x, ps.b.y, pshalf.b.x, pshalf.b.y, halfl+r);
			std::list<int> &&ids=m->near_cells(pshalf.b.x, pshalf.b.y, halfl+r); //!check this!
			//std::list<int> &&ids=m->near_cells(x, y, r); //!check this!
			std::unordered_set<segment*> done;
			//printf("segments %d \n", world->map->segments.size());
			for(auto c: ids){//TODO: change to check by map grid
				share::cell *cell=m->cells(c);
				for(int i=0,end=cell->segments.size();i<end;i++){
					segment *s=cell->segments[i];
					if (done.count(s)==0){ //uniq check
						if(!s->directed || (s->directed && s->vector(position)<0 && s->cross(&ps)>0)){ //check for directed segments
							try{
								if (callback(p, s)){
									return 0;
								}
							}catch(...){
								if(s->distanse(p)<=r){
									//printf("dist \n");
									return 0;
								}
							}
						}
						done.insert(s);
					}
				}
			}
			return 1;
		});
	}

	#define RAND_VALUE 100
	bool npc::randInPercent(float p){
		return (rand()%RAND_VALUE)<(int)(p*RAND_VALUE);
	}
}
