#include <stdio.h>
#include <string.h>

#include "server.h"
#include "client.h"
#include "../server.h"
#include "../client.h"
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
/*		
	static void *message1(server *sv, packet *p_){

		return 0;//check for error return
	}

	///set client attributes {2, n, 3, int, (6, string)[n]} key value pairs of strings of attributes
	static void *message2(server *sv, packet *p){

		return 0;
	}

	///info about servers {3,0,0,0}
	static void *message3(server *sv, packet *p_){
		packet p;
		p.setType((char)MSG_S_SERVERS_INFO);
		for (auto s:server::all){
			p.add(s.second->id);
		}
		p.dest.type=(char)0;
		p.dest.id=(int)0;
		sv->sock->send(&p);
		return 0;
	}

	///move client to another server {4,2,3,int,3,int,0,0}
	static void *message4(server *sv, packet *p){
		client *c;
		server *s;
		char *buf=(char*)p->data();
		int id=*((int*)(buf+3));
		int cid=*((int*)(buf+8));
		printf("move %d to  server %d\n",id, cid);
		if ((c=sv->clients_get(id))!=0){
			if((s=server::get(cid))!=0){
				sv->clients_remove(c);//func will send message
				s->clients_add(c);//func will send message
				printf("moved\n");
			}
		}
		return 0;
	}

	///i'm ready {5,1,3,id,0,0}
	static void *message5(server *sv, packet *p_){
		char*buf=(char*)p_->data();
		int id=*((int*)(buf+3));
		if (id==sv->id){
			sv->set_ready();
			printf("server %d ready\n", sv->id);
			packet p;
			p.setType((char)MSG_S_SERVER_READY);
			p.add(sv->id);
			p.dest.type=(char)0;
			p.dest.id=(int)0;
			///send packet
			server::sendAll(&p);
		}else{
			printf("server ready id error %d!=%d\n", sv->id, id);
		}
		return 0;
	}

*/

	static void *message_NPC_HURT(server *sv, packet *p_){
		//find npc and hurt it
		return 0;
	}

	static void *message_SERVER_READY(server *sv, packet *p_){
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
