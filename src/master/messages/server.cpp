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

	static void* message_NPC_HURT(server *sv, packet *p){
		if (p->chanks.size()<1)
			return p;//strange
		//find npc and hurt it
		master::world.m.lock();
			npc *n=master::world.npcs[p->chanks[0].value.i];
			npc *e=master::world.npcs[p->chanks[1].value.i];
			if (n && e){
				n->m.lock();
					n->hurt(withLock(e->m, e->damage));
				n->m.unlock();
			}
		master::world.m.unlock();
		return 0;
	}

	static void* message_SERVER_READY(server *sv, packet *p_){
		master::world.m.lock();
			master::grid->add(sv->id);
		master::world.m.unlock();
		return 0;
	}

//	voidMessageProcessor(1)


	void serverMessageProcessorInit(){
//		serverMessageProcessor(1);
		messageprocessorServerAdd(MESSAGE_NPC_HURT, (void*)&message_NPC_HURT);
		messageprocessorServerAdd(MESSAGE_SERVER_READY, (void*)&message_SERVER_READY);
	}
}
