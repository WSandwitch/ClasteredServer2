#include <cstdio>
extern "C"{
}
#include "../world.h"
#include "../../share/system/mutex.h"
#include "message.h"

#define addProcessor(id)\
	messages[id]=&message ## id

using namespace share;

namespace slave {
	
	std::map<char, processor> processors::messages;
	
	//server connected
	//[id, $servers]
	static void* message2(packet* p){
		printf("server %d connected\n", p->chanks[0].value.i);
		withLock(world::m, world::grid->add(p->chanks[0].value.i, 1));
		return 0;
	}
	
	//server disconnected
	//[id, $servers]
	static void* message3(packet* p){
		printf("server %d disconnected\n", p->chanks[0].value.i);
		withLock(world::m, world::grid->remove(p->chanks[0].value.i, 1));
		return 0;
	}
	
	//servers info
	//[(id,)+]
	static void* message4(packet* p){
		for(unsigned i=0, s=p->chanks.size();i<s;i++){
			withLock(world::m, world::grid->add(p->chanks[i].value.i, i==s-1));//reconfigure on last
		}
		return 0;
	}

	//client connected	
	//[id, $clients]
	static void* message5(packet* p){
		printf("client connected %d\n", p->chanks[0].value.i);
		player *pl=world::players[p->chanks[0].value.i];
		if (!pl)
			pl=withLock(world::m, world::players[p->chanks[0].value.i]=new player(p->chanks[0].value.i));
		withLock(pl->m, pl->connected=1);
		return 0;
	}

	//client disconnected	
	//[id, $clients]
	static void* message6(packet* p){
		printf("client disconnected %d\n", p->chanks[0].value.i);
		player *pl=world::players[p->chanks[0].value.i];
		if (pl){
			if (pl->npc){
				withLock(pl->npc->m, pl->npc->slave_id=0);
			}
			world::m.lock();
				world::players.erase(p->chanks[0].value.i);
			world::m.unlock();
			delete pl;
		}
		return 0;
	}
	
	//got new id
	//[id]
	static void* message9(packet* p){
		world::m.lock();
			world::ids.push(p->chanks[0].value.i);
		world::m.unlock();
		printf("got new id %d\n", p->chanks[0].value.i);
		return 0;
	}
	
	//server ready
	//[id]
	static void* message10(packet* p){
		printf("server %d ready\n", p->chanks[0].value.i);
		withLock(world::m, world::grid->add(p->chanks[0].value.i, 1));
		//add grid update
		return 0;
	}
	
	///custom messages
	//ask npc info
	//[id] server
	static void* message40(packet* p){
		if (p->dest.type==CLIENT_MESSAGE){
			//TODO: need?
		}else if (p->dest.type==SERVER_MESSAGE){//ask for npc info
			for(unsigned i=0;i<p->chanks.size();i++){
				npc* n;
				withLock(world::m, n=world::npcs[p->chanks[i].value.i]);
				if (n){
					n->m.lock();
						n->pack(1,1);
						n->p.dest.id=p->dest.id;
						world::sock->send(&n->p);
					n->m.unlock();
					printf("sent info about %d\n",n->id);
				}
			}
		}
		return 0;
	}
	
	//update npc
	//[(keys_val,)+] client
	//[id, (attr_id, attr_value)+] server
	static void* message41(packet* p){
		if (p->dest.type==CLIENT_MESSAGE){//give keys status
			player* pl=world::players[p->dest.id];
			if (pl && pl->npc){
				pl->npc->m.lock();
					for(unsigned i=0;i<p->chanks.size();i+=2){
						pl->npc->keys[(int)p->chanks[i].value.c]=p->chanks[i+1].value.c;
//						printf("key %d status %d\n", p->chanks[i].value.c, p->chanks[i+1].value.c);
					}
					pl->npc->set_dir();
				pl->npc->m.unlock();
			}
		}else if (p->dest.type==SERVER_MESSAGE){//give npc info
			npc* n=withLock(world::m, world::npcs[p->chanks[0].value.i]);
			if (!n){
				n=new npc(p->chanks[0].value.i, p->dest.id);
				packet p1;
				p1.setType(MSG_SERVER_NPC_INFO);//get full info
				p1.add(n->id);
				p1.dest.type=SERVER_MESSAGE;
				p1.dest.id=p->dest.id;
				world::sock->send(&p1);
				withLock(world::m, world::npcs[n->id]=n);
			}
			printf("got info about %d\n", n->id);
			n->m.lock();
				n->update(p);
			n->m.unlock();
		}
		return 0;
	}
	
	//player info
	//[] client
	//[]  server
	static void* message42(packet* p){
		if (p->dest.type==CLIENT_MESSAGE){//ask player info
			
		}else if (p->dest.type==SERVER_MESSAGE){//give player info
			player* pl=world::players[p->dest.id];
			if (pl){
				pl->update(p);
			}
		}
		return 0;
	}
	
	void processors::init(){
		addProcessor(2);
		addProcessor(3);
		addProcessor(4);
		addProcessor(5);
		addProcessor(6);
		addProcessor(9);
		addProcessor(10);
		addProcessor(40);
		addProcessor(41);
		addProcessor(42);
	}
}