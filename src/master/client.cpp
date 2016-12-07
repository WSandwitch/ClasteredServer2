#include <string.h>

#include <cstdlib>

#include "client.h"
#include "chat.h"
#include "world.h"
#include "server.h"
#include "storage.h"
#include "messageprocessor.h"
#include "../share/network/socket.h"
#include "../share/network/packet.h"
#include "../share/crypt/base64.h"
#include "../share/system/log.h"

/*
╔══════════════════════════════════════════════════════════════╗
║ 	implementation of connected clients 			                       ║
║ created by Dennis Yarikov						                       ║
║ jun 2016									                       ║
╚══════════════════════════════════════════════════════════════╝
*/

using namespace share;

namespace master {

	typedef void*(*client_processor)(client*, packet*);

	std::map<int, client*> client::all;
	share::mutex client::m;



	client_message::client_message(void* buf, short size):ready(0){
		$data=size;
		if ((data=(char*)malloc(sizeof(*data)*($data+1)))==0){
			perror("malloc");
		}
		memcpy(data, buf, $data);
		data[$data]=0;
		//packetAddData(&m->packet,buf,size);
	}

	client_message::~client_message(){
		withLock(mutex, num--);
		if (withLock(mutex, num==0)){	
			free(data);
		}
	}

	client::client(socket *sock):
		id(0),	
		broken(0),
		sock(sock),
		timestamp(0)
	{
		name[0]=0;
		login[0]=0;
		passwd[0]=0;
		npc=new share::npc(&master::world, master::world.getId());
	}
	
	client::~client(){
		mutex.lock();
			if (sock)
				delete sock;
			for (auto mes:messages){
				delete mes;
			}
			if (npc){
				npc->world->m.lock();
					npc->world->npcs.erase(npc->id);
				npc->world->m.unlock();
				withLock(npc->m, npc->owner_id=0);//set to not respawn
				delete npc;
			}
		mutex.unlock();
	}

	int client::add(client* c){
		if (c){
			if (c->id!=0){
				m.lock();
					all[c->id]=c;
				m.unlock();
			}
			return c->id;
		}
		return 0;
	}

	client* client::get(int id){
		client *c=0;
		m.lock();
			auto i=all.find(id);
			if (i!=all.end())
				c=i->second;
			if (c!=0 && c->broken)
				c=0;
		m.unlock();
		return c;
	}

	void client::check(){
		std::list<client*> l;
		m.lock();
			for (auto c:all){
				if (withLock(c.second->mutex, c.second->broken) || c.second->id==0){
					if (abs(share::time(0)-c.second->timestamp)>=0){//add 10 seconds for reconnect
						l.push_back(c.second);
					}
				}
			}
			for (auto c:l){
				printf("client %d removed\n", c->id);
				all.erase(c->id);
				delete c;
			}
//			bintreeForEach(&clients, checkC, &list);
//			worklistForEachRemove(&list, removeC, 0);
		m.unlock();
	}

	void client::remove(client* c){
		if (c){
			m.lock();
				all.erase(c->id);
				delete c;
			m.unlock();
		}
	}

	int client::proceed(packet *p){
		char* buf=(char*)p->data();
		client_processor processor;
		//void*(*processor)(packet*);
	//	printf("got message %d\n", *buf);
		if ((processor=(client_processor)messageprocessorClient(*buf))!=0){
			return processor(this, p)!=0;
		}
		return 0;
	}

	void client::messages_add(client_message *mes){
		if (mes){
			mes->num=1;
			mes->ready=1;
			mutex.lock();
				messages.push_back(mes);
			mutex.unlock();
				//find client and add
		}
	}
	
	void client::broadcast(client_message *mes){
		if (mes){
			//add to all, and then
			m.lock();
				for (auto i:all){
					client *c=i.second;
					c->mutex.lock();
						c->messages.push_back(mes);
						mes->mutex.lock();
							mes->num++;
						mes->mutex.unlock();
					c->mutex.unlock();
				}
//				bintreeForEach(&clients, clientAddEach, m);
				mes->mutex.lock();
					mes->ready=1;
				mes->mutex.unlock();
			m.unlock();
		}
	}

	void clientChatsAdd(client* cl, void* _c){
/*		chat *c=_c;
		t_mutexLock(cl->mutex);
		if (bintreeAdd(&cl->chats, c->id, c)){
			t_mutexUnlock(cl->mutex);
			chatClientsAdd(c, cl);
			return;
		}
		t_mutexUnlock(cl->mutex);
*/	}

	void* clientChatsGet(client* cl, int id){
		chat *c=0;
/*		t_mutexLock(cl->mutex);
			c=bintreeGet(&cl->chats, id);
		t_mutexUnlock(cl->mutex);
*/		return c;
	}

	void clientChatsRemove(client* cl, void* _c){
/*		chat *c=_c;
		chat* found=0;
		if (cl==0 || c==0)
			return;
		void clientChatsRemoveChat(void* data){
			found=data;
		}
		t_mutexLock(cl->mutex);
			bintreeDel(&cl->chats, c->id, clientChatsRemoveChat);//check for deadlock
		t_mutexUnlock(cl->mutex);
		chatClientsRemove(found, cl);
*/	}

	void client::messages_proceed(){
		mutex.lock();
			for (auto i=messages.begin(), end=messages.end();i!=end;){
				client_message *m=*i;
				if (withLock(m->mutex, m->ready)){
					packet p;
					p.init(m->data, m->$data);
					sock->send(&p);
					messages.erase(i++);
					delete m;
				}else{
					i++;
				}
			}
		mutex.unlock();
	}

	
	int client::set_info(user_info *u){
		id=u->id;
		sprintf(name,"%s",u->name);
		sprintf(login,"%s",u->login);
		share::base64::decode((unsigned char*)u->passwd, (unsigned char*)passwd, strlen(u->passwd));
		//add other
		return 0;
	}

	void client::server_clear(){
		withLock(mutex, server_id=0);
	}
	
}
