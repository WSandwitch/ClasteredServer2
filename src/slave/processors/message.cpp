#include <cstdio>
extern "C"{
}
#include "../world.h"
#include "../../share/system/mutex.h"
#include "../../share/messages.h"
#include "../processors.h"

#define addProcessor(id)\
	messages[id]=&message ## id

using namespace share;

namespace slave {
	
	std::map<char, processor> processors::messages;
	processors processors::init;
	
	static void* message_NPC_UPDATE(packet* p){
		int id=p->chanks[0].value.i;
		npc* n=0;
		slave::world.m.lock();
			try{
				n=slave::world.npcs.at(id);
			}catch(...){
				n=new npc(&slave::world, id);
				slave::world.npcs_m.lock();
					slave::world.new_npcs.push_back(n);
				slave::world.npcs_m.unlock();
			}
			n->m.lock();
				n->update(p);
			n->m.unlock();
		slave::world.m.unlock();
//		printf("%g %g\n", n->position.x, n->position.y);
		return 0;
	}
	
	static void* message_NPC_REMOVE(packet* p){
		int id=p->chanks[0].value.i;
		npc* n=0;
		slave::world.m.lock();
			try{
				n=slave::world.npcs.at(id);
				n->m.lock();
					slave::world.npcs.erase(id);
				n->m.unlock();
				delete n;
			}catch(...){}
			printf("npc %d removed\n", id);
		slave::world.m.unlock();
		return 0;
	}
	
	processors::processors(){
		messages[MESSAGE_NPC_UPDATE]=&message_NPC_UPDATE;
		messages[MESSAGE_NPC_REMOVE]=&message_NPC_REMOVE;
	}
}