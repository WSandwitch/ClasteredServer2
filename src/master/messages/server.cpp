#include <stdio.h>
#include <string.h>

#include "server.h"
#include "client.h"
#include "../server.h"
#include "../client.h"
#include "../world.h"
#include "../messageprocessor.h"
#include "../../share/network/packet.h"
#include "../../share/system/log.h"
#include "../../share/messages.h"


/*
╔══════════════════════════════════════════════════════════════╗
║ 	server messages processors 			                       ║
║ created by Dennis Yarikov						                       ║
║ jun 2016									                       ║
╚══════════════════════════════════════════════════════════════╝
*/

#define serverMessageProcessor(id)\
	messageprocessorServerAdd(id, (void*)&message ## id)

#define voidMessageProcessor(i)\
	static void *message ## i(server*s, packet* p){\
	return 0;\
}

using namespace share;

///get client attributes 
namespace master {

	///[nid, enemyid]
	static void* message_NPC_HURT(server *sv, packet *p){
		if (p->chanks.size()<1)
			return p;//strange
		//find npc and hurt it
		master::world.m.lock();
			npc *n=master::world.npcs[p->chanks[0].value.i];
			npc *e=master::world.npcs[p->chanks[1].value.i];
			if (n && e){
				n->m.lock();
					auto d=withLock(e->m, e->damage);
					n->hurt(d);
					n->damagers[e->id]+=d;
				n->m.unlock();
				printf("%d hurts by %d for %d\n", n->id, e->id, d);
			}
		master::world.m.unlock();
		return 0;
	}

	///[sid]
	static void* message_SERVER_READY(server *sv, packet *p_){
		master::world.m.lock();
			master::grid->add(sv->id);
		master::world.m.unlock();
		printf("server %d ready\n", sv->id);
		return 0;
	}

	static void* message_NPC_UPDATE(server *sv, packet* p){
		int id=p->chanks[0].value.i;
		npc* n=0;
		master::world.m.lock();
			n=master::world.npcs[id];
			if(!n){
				n=new npc(&master::world, id);
				master::world.npcs_m.lock();
					master::world.new_npcs.push_back(n);
				master::world.npcs_m.unlock();
			}
			n->m.lock();
		master::world.m.unlock();
			n->update(p);
		n->m.unlock();
		return 0;
	}
	

//	voidMessageProcessor(1)


	void serverMessageProcessorInit(){
//		serverMessageProcessor(1);
		messageprocessorServerAdd(MESSAGE_NPC_HURT, (void*)&message_NPC_HURT);
		messageprocessorServerAdd(MESSAGE_SERVER_READY, (void*)&message_SERVER_READY);
		messageprocessorServerAdd(MESSAGE_NPC_UPDATE, (void*)&message_NPC_UPDATE);
	}
}
