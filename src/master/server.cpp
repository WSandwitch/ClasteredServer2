#include <string.h>

#include "messages/server.h"
#include "server.h"
#include "client.h"
#include "messageprocessor.h"
#include "workers/serverworkers.h"
#include "../share/containers/bintree.h"
#include "../share/containers/worklist.h"
#include "../share/network/packet.h"
#include "../share/system/types.h"
#include "../share/system/log.h"
#include "../share/crc32.h"

/*
╔══════════════════════════════════════════════════════════════╗
║ 	implementation of slave servers 			                       ║
║ created by Dennis Yarikov						                       ║
║ jun 2016									                       ║
╚══════════════════════════════════════════════════════════════╝
*/

typedef void*(*server_processor)(server*, packet*);

static short servers_total=0;
static bintree servers={0};
static t_mutex_t mutex=0;

static void* serversSendPacket(bintree_key k, void* v, void * p);

void serversInit(){
	memset(&servers, 0,sizeof(servers));
	if ((mutex=t_mutexGet())==0){
		perror("t_mutexGet");
		return;
	}
}

void serversClear(){
	t_mutexLock(mutex);
		bintreeErase(&servers, (void(*)(void*))serverClear);
	t_mutexUnlock(mutex);
	t_mutexRemove(mutex);
}

server *serverNew(char* host, short port){
	server * s;
	if ((s=malloc(sizeof(*s)))==0){
		perror("malloc");
		return 0;
	}
	memset(s,0,sizeof(*s));
	sprintf(s->host, "%s", host);
	s->port=port;
	if ((s->sock=socketConnect(s->host, s->port))==0){
		perror("socketConnect");
		serverClear(s);
		return 0;
	}
	storageSlaveSetUnbroken(s->host, s->port);//maybe need not here
	if ((s->mutex=t_mutexGet())==0){
		perror("t_mutexGet");
		serverClear(s);
		return 0;
	}
	//TODO: add auth 
	s->id=serverIdByAddress(host,port);
	printf("server %d created\n", s->id);
	return s;
}

//not used
server* serverReconnect(server *s){
	socketClear(s->sock);
	if ((s->sock=socketConnect(s->host, s->port))==0){
		return 0;
	}
	return s;
}

void serverClear(server* s){
	if (s==0)
		return;
	if (s->mutex){
		t_mutexLock(s->mutex);
			bintreeErase(&s->clients, (void(*)(void*))clientServerClear);
		t_mutexUnlock(s->mutex);
		t_mutexRemove(s->mutex);
	}
	socketClear(s->sock);
	free(s);
}

int serversAdd(server* s){
	packet *p;
	if (s->id!=0){
		t_mutexLock(mutex);
			servers_total++;
			bintreeAdd(&servers, s->id, s);
			if ((p=packetNew(100))!=0){
				packetInitFast(p);
				packetAddNumber(p, (char)MSG_S_SERVER_CONNECTED);
				packetAddNumber(p, (char)2);
				packetAddInt(p, s->id);
				packetAddShort(p, servers_total);
				packetAddNumber(p, (char)0);
				packetAddNumber(p, (int)0);
				///send packet
				bintreeForEach(&servers, serversSendPacket, p);
				free(p);
			}
		t_mutexUnlock(mutex);
		serverworkersAddWorkAuto(s);			
	}
	return s->id;
}

server *serversGet(int id){
	server *s;
//	printf("get server %d\n", id);
	t_mutexLock(mutex);
		s=bintreeGet(&servers, id);
	t_mutexUnlock(mutex);
	return s;
}

void serversRemove(server* s){
	int id=s->id;
	packet *p;
	t_mutexLock(mutex);
		servers_total--;
		bintreeDel(&servers, s->id, (void(*)(void*))serverClear);
	t_mutexUnlock(mutex);
	printf("removed server %d\n", id);
	if ((p=packetNew(100))!=0){
		packetInitFast(p);
		packetAddNumber(p, (char)MSG_S_SERVER_DISCONNECTED);
		packetAddNumber(p, (char)2);
		packetAddInt(p, id);
		packetAddShort(p, serversTotal());
		packetAddNumber(p, (char)0);
		packetAddNumber(p, (int)0);
		serversPacketSendAll(p);
		free(p);
	}
}

static void* setUncheck(bintree_key k, void *v, void *arg){
	server *s=v;
	s->checked=0;
	return 0;
}
static int checkSlaves(slave_info *si, void *arg){
	int id=serverIdByAddress(si->host, si->port);
	server *s=serversGet(id);
//	printf("check server %d, got %d\n", id, s);
	if (s==0){
		if ((s=serverNew(si->host, si->port))!=0){
			serversAdd(s);
			//fist message to serer is server_connected 
		}
	}
	if (s){
		s->checked=1;
		//add message server created
	}
	return 0;
}
static void* checkS(bintree_key k, void *v, void *arg){
	server *s=v;
	if (s->checked==0){
		worklistAdd(arg, v);
	}
	return 0;
}
static void* checkR(void *v, void *arg){
	server *s=v;
	socketClose(s->sock);//it will be cleared lately
	return v;
}
void serversCheck(){
	worklist l;
	memset(&l,0,sizeof(l));
	t_mutexLock(mutex);
		bintreeForEach(&servers, setUncheck, 0);
	t_mutexUnlock(mutex);
	storageSlaves(checkSlaves, 0);
	t_mutexLock(mutex);
		bintreeForEach(&servers, checkS, &l);
	t_mutexUnlock(mutex);
	worklistForEachRemove(&l, checkR, 0);
}

void serversForEach(void*(*f)(bintree_key k, void *v, void *arg), void* a){
	t_mutexLock(mutex);
		bintreeForEach(&servers, f, a);
	t_mutexUnlock(mutex);

}

static void* findAuto(bintree_key k, void *v, void *arg){
	int2_t *d=arg;
	server *s=v;
	if (s->ready &&(d->i1==0 || d->i2>=s->$clients)){
		d->i1=s->id;
		d->i2=s->$clients;
//		return &s->id;
	}
	return 0;
}
int serversGetIdAuto(){
	int2_t d={0,0};
	t_mutexLock(mutex);
		bintreeForEach(&servers, findAuto, &d);
	t_mutexUnlock(mutex);
	return d.i1;
}

short serversTotal(){
	short o;
	t_mutexLock(mutex);
		o=servers_total;
	t_mutexUnlock(mutex);
	return o;
}

void serversTotalInc(){
	t_mutexLock(mutex);
		servers_total++;
	t_mutexUnlock(mutex);
}

void serversTotalDec(){
	t_mutexLock(mutex);
		servers_total--;
	t_mutexUnlock(mutex);
}

void serverPacketProceed(server *s, packet *p){
	void* buf=packetGetData(p);
	server_processor processor;
//	printf("got server message %d\n", *((char*)buf));
	if ((processor=messageprocessorServer(*((char*)buf)))==0){
		//remove client data from the end
		short size=packetGetSize(p);
//		printf("got message size %d\n", size);
		int _id=*((typeof(_id)*)(buf+(size-=sizeof(_id))));//check for write size size
		char dir=*((typeof(dir)*)(buf+(size-=sizeof(dir))));
		if (dir==MSG_CLIENT){ //redirect packet to client
//			printf("redirect to client %d\n", _id);
			client* c=0;
			if (_id==0 || (c=clientsGet(_id))!=0){
				clientMessagesAdd(c, clientMessageNew(buf, size));
			}
		}else if (dir==MSG_SERVER){ //redirect packet to server
//			printf("redirect to server %d\n", _id);
			server* sv=serversGet(_id);
			packetSetSize(p, size);
//			printf("set message size %d\n", size);
			packetAddChar(p, MSG_SERVER);//message from server
			packetAddNumber(p, s->id);
			if (sv){
				packetSend(p, sv->sock);
			}else if (_id==0){
				serversPacketSendAll(p);
			}
		}
	}else{//proceed by self
		processor(s, p);
	}
}

int serverIdByAddress(char* address, short port){ //return 6 bytes integer
	char str[400];
	sprintf(str, "%s%d", address, port);
	return crc32(str, strlen(str));
}

static void* serversSendPacket(bintree_key k, void* v, void * p){
	server* s=v;
	packetSend(p, s->sock);
	return 0;
}
void serversPacketSendAll(packet* p){
	t_mutexLock(mutex);
		bintreeForEach(&servers, serversSendPacket, p);
	t_mutexUnlock(mutex);
}

int serverClientsAdd(server *s, void *_c){
	client *c=_c;
	packet *p;
	clientCritical(c,c->server_id=s->id);
	t_mutexLock(s->mutex);
		bintreeAdd(&s->clients, c->id, c);
		s->$clients++;
	t_mutexUnlock(s->mutex);
//	printf("added client %d to server %d\n",c->id, s->id);
	if ((p=packetNew(100))!=0){
		packetAddNumber(p, (char)MSG_S_CLIENT_CONNECTED);
		packetAddNumber(p, (char)2);
		packetAddInt(p, c->id);
		packetAddShort(p, s->$clients);
		packetAddNumber(p, (char)0);
		packetAddNumber(p, (int)0);
		packetSend(p, s->sock);
		free(p);
	}
	return 0;
}

void* serverClientsGet(server *s, int id){
	void* c;
	t_mutexLock(s->mutex);
		c=bintreeGet(&s->clients, id);
	t_mutexUnlock(s->mutex);
	return c;
}

int serverClientsRemove(server *s, void *_c){
	client *c=_c;
	int id=c->id;
	packet *p;
	t_mutexLock(s->mutex);
		bintreeDel(&s->clients, c->id, (void(*)(void*))clientServerClear);
		s->$clients--;
	t_mutexUnlock(s->mutex);
//	printf("removed client %d to server %d\n", id, s->id);
	if ((p=packetNew(100))!=0){
		packetAddNumber(p, (char)MSG_S_CLIENT_DISCONNECTED);
		packetAddNumber(p, (char)2);
		packetAddInt(p, id);
		packetAddShort(p, s->$clients);
		packetAddNumber(p, (char)0);//must be here
		packetAddNumber(p, (int)0);//must be here
		packetSend(p, s->sock);
		free(p);
	}
	return 0;
}

static void* serverClientsEraseEach(bintree_key k, void* v, void* arg){
	clientServerClear(v);
	return 0;
}
void serverClientsErase(server *s){
	t_mutexLock(s->mutex);
		bintreeForEach(&s->clients, serverClientsEraseEach,0);
		s->$clients=0;
	t_mutexUnlock(s->mutex);
}

void serverSetReady(server* s){
	t_mutexLock(s->mutex);
		s->ready=1;
	t_mutexUnlock(s->mutex);
}

