#include <string.h>

#include "chat.h"
#include "client.h"

#define t_mutexLock(mutex) mutex.lock()
#define t_mutexUnlock(mutex) mutex.unlock()
#define t_mutexRemove(mutex) mutex

namespace master {
	static std::map<int, void*> chats;
	static t_mutex_t mutex;

	void chatsInit(){
	}

	void chatsClear(){
/*		t_mutexLock(mutex);
			for (auto c:chats){
				chatClear((void*)c.second);
			}
		t_mutexUnlock(mutex);
		t_mutexRemove(mutex);
*/	}

	chat* chatNew(){
		return new chat();
	}

	void chatClear(chat* c){
		if (c==0)
			return;
/*		std::list<chat*> l;
		t_mutexLock(c->mutex);
			for (auto c:clients){
				l.push_back(c->second);
			}
		t_mutexUnlock(c->mutex);
		for (auto c:l){
			c->chats_remove();
		}
//		worklistForEachRemove(&list, removeR, c);
		t_mutexRemove(c->mutex);
*/		delete c;
	}

	void chatClientsAdd(chat* c, void* _client){
/*		client* cl=(client*)_client;
		t_mutexLock(c->mutex);
		c->clients[cl->id]=cl;
		t_mutexUnlock(c->mutex);
		cl->chats_add(c);
*/	}

	void* chatClientsGet(chat* c, int id){
		client* cl=0;
/*		t_mutexLock(c->mutex);
			cl=c->clients[id];
		t_mutexUnlock(c->mutex);
*/		return (void*)cl;
	}

	void chatClientsRemove(chat* c, void* _client){
/*		client* cl=_client;
		client* found=0;
		if (cl==0 || c==0)
			return;
		void chatClientsRemoveClient(void* data){
			found=data;
		}
		t_mutexLock(c->mutex);
			found=c->clients[cl->id];
			c->clients.erase(cl->id);
//			bintreeDel(&c->clients, cl->id,  chatClientsRemoveClient);//check for deadlock
		t_mutexUnlock(c->mutex);
		if (found)
			found->chats_remove(c);
*/	}

	int chatsAdd(chat* c){
		if (c && c->id!=0){
/*			t_mutexLock(mutex);
				chats[c->id]=c;
			t_mutexUnlock(mutex);
*/			return c->id;
		}
		return 0;
	}

	chat* chatsGet(int id){
		chat *c=0;
/*		t_mutexLock(mutex);
			c=&chats[id];
		t_mutexUnlock(mutex);
*/		return c;
	}

	void chatsCheck(){
/*		std::list<chat*> l;
		t_mutexLock(mutex);
			for (auto c:chats){
				//l.push_back(c->second);
			}
//			bintreeForEach(&chats, checkC, &list);
		t_mutexUnlock(mutex);
		for (auto c:l){
			if (*c){
				chats.erase(*c->id);
				chatClear(*c);
			}
		}
//		worklistForEachRemove(&list, removeC, 0);
*/	}

	void chatsRemove(chat* c){
/*		t_mutexLock(mutex);
//			bintreeDel(&chats, c->id, (void(*)(void*))chatClear);
		t_mutexUnlock(mutex);
*/	}


	/*

	void chats_test(){
		void* chatP(bintree_key k, void* v, void* arg){
			client* c=v;
			printf("chat %d\n", c->id);
			return 0;
		}
		void* clientP(bintree_key k, void* v, void* arg){
			client* c=v;
			printf("client %d\n", c->id);
			return 0;
		}
		printf("chats test\n");
		client* c[3]={
			clientNew(socketNew(0)),
			clientNew(socketNew(0)),
			clientNew(socketNew(0))
		};
		chat * ch=chatNew();
		chat * ch2=chatNew();
		c[0]->id=1;
		c[1]->id=2;
		c[2]->id=3;
		ch->id=1;
		ch2->id=2;
		clientChatsAdd(c[0], ch);
	//	clientChatsAdd(c[1], ch);
		bintreeForEach(&c[0]->chats, chatP, 0);
		bintreeForEach(&c[1]->chats, chatP, 0);
		bintreeForEach(&ch->clients, clientP, 0);
		chatClientsRemove(ch,c[0]);
		printf("removed client 0\n");
		bintreeForEach(&c[0]->chats, chatP, 0);
		bintreeForEach(&c[1]->chats, chatP, 0);
		bintreeForEach(&ch->clients, clientP, 0);
		clientChatsAdd(c[0], ch);
		clientChatsAdd(c[0], ch2);
		chatClientsAdd(ch,c[2]);
		printf("added 2\n");
		bintreeForEach(&c[0]->chats, chatP, 0);
		bintreeForEach(&c[1]->chats, chatP, 0);
		bintreeForEach(&ch->clients, clientP, 0);
		printf("clear\n");
		clientClear(c[0]);
		bintreeForEach(&c[0]->chats, chatP, 0);
		bintreeForEach(&c[1]->chats, chatP, 0);
		
		printf("success\n");
	}

	log_config config={0};

	log_config* mainLogConfig(){
		return &config;
	}

	int main(int argc,char* argv[]){
		config.log.debug=1;
		chats_test();
		return 0;

	*/
}
