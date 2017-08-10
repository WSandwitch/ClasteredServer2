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
				n=new npc(&slave::world, id); //TODO: check get from new_npcs
				slave::world.npcs_m.lock();
					slave::world.new_npcs.push_back(n);
				slave::world.npcs_m.unlock();
				printf("added npc %d\n", id);
			}
			n->m.lock();
				n->update(p, 0);
//				n->attrs[8]=1;//TODO: update this dirty hack, why it needs to be marked
			n->m.unlock();
		slave::world.m.unlock();
//		printf("%g %g\n", n->direction.x, n->direction.y);
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
				n->remove();
				printf("npc %d removed\n", id);
			}catch(...){
				printf("npc %d not found\n", id);
			}
		slave::world.m.unlock();
		return 0;
	}
	
	static void* message_MESSAGE_PAUSE(packet* p){
		slave::world.m.lock();
			slave::world.pause=p->chanks[0].value.c;
			printf("pause %d\n", slave::world.pause);
		slave::world.m.unlock();
		return 0;
	}
	
	processors::processors(){
		messages[MESSAGE_NPC_UPDATE]=&message_NPC_UPDATE;
		messages[MESSAGE_NPC_REMOVE]=&message_NPC_REMOVE;
		messages[MESSAGE_PAUSE]=&message_MESSAGE_PAUSE;
	}
}