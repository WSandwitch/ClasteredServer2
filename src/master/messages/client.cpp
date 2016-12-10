#include <cstdlib>

#include <string.h>

#include "client.h"
#include "server.h"
#include "../client.h"
#include "../server.h"
#include "../world.h"
#include "../storage.h"
#include "../messageprocessor.h"
#include "../../share/network/packet.h"
#include "../../share/system/log.h"
#include "../../share/crypt/base64.h"
#include "../../share/crypt/md5.h"
#include "../../share/messages.h"

/*
╔══════════════════════════════════════════════════════════════╗
║ 	clients messages processors 			                       ║
║ created by Dennis Yarikov						                       ║
║ jun 2016									                       ║
╚══════════════════════════════════════════════════════════════╝
*/


#define voidMessageProcessor(i)\
	static void *message ## i(client*c, packet* p){\
	clientCheckAuth(c);\
	return 0;\
}

#define clientMessageProcessor(id)\
	messageprocessorClientAdd(id, (void*)&message ## id)

#define clientCheckAuth(c)\
	if(c->id==0){\
		withLock(c->mutex,c->broken=1);\
		printf("unauthorized client\n");\
		return c;\
	}
	
using namespace share;

namespace master {
	//AUTH
	static void *message_MESSAGE_AUTH(client*cl, packet* _p){
		FILE* f=_p->stream();
		char c;
		int size;
		short s;
		char buf[100];
		printf("client auth\n");
		if (f){	
			size=fread(&c,1,sizeof(c),f);//
//			printf("%d\n",c);
			size=fread(&c,1,sizeof(c),f);
//			printf("%d\n",c);
			size=fread(&c,1,sizeof(c),f);
			size=fread(&c,1,sizeof(c),f);
//			printf("%d\n",c);
			do{
				if (c==1){
					user_info u;
					size=fread(&c,1,sizeof(c),f);
					if (c==6){
						size=fread(&s,1,sizeof(s),f);//size
						for(size=s;size>0;){//must read full string
							size-=fread(buf+(s-size),1,size,f);//name, s elements of 1 byte
						}
						buf[s]=0;
						//find client by login
						if(storageUserByLogin(buf, &u)==0){//if we found user
							client* _cl=0;
							struct {
								int $1;
								timestamp_t $2;
							} tokenbase={rand(), share::time(0)};//uniq token
							char token[100];
							cl->set_info(&u);
							cl->conn_type=CLIENT_CONN_SOCKET;
							fclose(f);
							if((_cl=client::get(cl->id))!=0){//already signed in
								if (withLock(_cl->mutex, _cl->broken)){
									client::remove(_cl);
								}else{
									cl->id=0;
									printf("User %s already signed in\n", cl->login);
									//Add message already signed in
									return cl;
								}
							}
							client::add(cl);
							share::MD5::create((char*)&tokenbase, sizeof(tokenbase), cl->token); //add normal token
							s=share::base64::encode((unsigned char*)cl->token, (unsigned char*)token,16, 0);
							packet p;
							p.setType(MSG_C_AUTH_TOKEN);
		//					packetAddNumber(p,s);
							p.add((char*)token, s);
//							std::string ts(token);
//							p.add(ts); 
							cl->sock->send(&p);
//							cl->messages_add(new client_message((char*)p.data(), p.size()));
							break;
						}
					}
					printf("Not correct message\n");
				}else if(c==2){
					size=fread(&c,sizeof(c),1,f);
	//				printf("%d\n",c);
					if (c==6){
						size=fread(&s,sizeof(s),1,f);//size
						size=fread(buf,1,s,f);//hash
						buf[s]=0;
						char token[100];
						char md5[20];
						memcpy(token, cl->token, 16);
						memcpy(token+16, cl->passwd, 16);
						share::MD5::create((char*)token, 32, md5); 
						s=share::base64::encode((unsigned char*)md5, (unsigned char*)token, 16, 0);
						printf("token must be %s got %s\n", token, buf);
						if (strcmp(buf,token)==0){//add normal token check
							//auth ok
							fclose(f);
							packet p;
							p.setType(MSG_C_USER_INFO);
							p.add(cl->id);
							//packetAddString(p, cl->name);
							//add other params
							cl->sock->send(&p);
//							cl->messages_add(new client_message(p.data(), p.size()));
							///set npc data and add npc to world
							cl->npc->owner_id=cl->id;
							master::world.npcs_m.lock();
								master::world.new_npcs.push_back(cl->npc);
							master::world.npcs_m.unlock();
							printf("token OK\n");
							p.init();
							p.setType(MESSAGE_CLIENT_UPDATE);
							p.add((char)1);//index
							p.add(cl->npc->id);
							cl->sock->send(&p);
							break;
						}
					}
					printf("token Error\n");
				}
				/////
	//			c->id=rand();//for tests
	//			c->server_id=serversGetIdAuto();//for tests
				//////
				printf("Drop client\n");
				fclose(f);
				return cl;
			}while(0);
		}
		return 0;
	}

	static void *message_MESSAGE_SET_DIRECTION(client*cl, packet* p){
		clientCheckAuth(cl);//client must have id already
		if (cl->npc){
			typeof(point::x) x=0;
			typeof(point::y) y=0;
			short dir=0;
			for(int i=0, end=p->chanks.size();i<end;i++){
				int index=p->chanks[i++].value.c;
				switch (index){
					case 0://x
						x=p->chanks[i].value.c/100.0;
						dir++;
						break;
					case 1://y
						y=p->chanks[i].value.c/100.0;
						dir++;
						break;
					case 2://angle
						cl->npc->set_attr(cl->npc->angle, p->chanks[i].value.c);
						break;
					case 3://attack
						cl->npc->attack(p->chanks[i].value.c);
//						printf("%d attack\n", p->chanks[i].value.c);
					break;
				}
			}
			if (dir==2){
				cl->npc->m.lock();
					cl->npc->set_dir(x, y);
				cl->npc->m.unlock();
//				printf("set dir (%d %d)\n", x,y);
			}
		}
		return 0;
	}

	voidMessageProcessor(25)

	void clientMessageProcessorInit(){
		messageprocessorClientAdd(MESSAGE_AUTH, (void*)&message_MESSAGE_AUTH);
		messageprocessorClientAdd(MESSAGE_SET_DIRECTION, (void*)&message_MESSAGE_SET_DIRECTION);

		clientMessageProcessor(25);
	}
}