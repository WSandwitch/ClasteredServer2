#include <cstdlib>

#include <string.h>

#include "../main.h"
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
		short s;
		printf("client auth\n");
		if (_p->chanks.size()>=2){	
//			size=fread(&c,1,sizeof(c),f);//
//			printf("%d\n",c);
//			size=fread(&c,1,sizeof(c),f);
//			printf("%d\n",c);
//			size=fread(&c,1,sizeof(c),f);
//			size=fread(&c,1,sizeof(c),f);
//			printf("%d\n",c);
			do{
				if (_p->chanks[0].value.c==1){
					user_info u;
//					size=fread(&c,1,sizeof(c),f);
					if (_p->chanks[1].type==6){
//						size=fread(&s,1,sizeof(s),f);//size
//						for(size=s;size>0;){//must read full string
//							size-=fread(buf+(s-size),1,size,f);//name, s elements of 1 byte
//						}
//						buf[s]=0;
						auto &login=_p->chanks[1].str;
						printf("login got %s\n", login.data());
						//find client by login
						if(storageUserByLogin((char*)login.c_str(), &u)==0){//if we found user
							client* _cl=0;
							cl->set_info(&u);
							cl->conn_type=CLIENT_CONN_SOCKET;
//							fclose(f);
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
							packet p;
							p.setType(MSG_C_AUTH_TOKEN);
		//					packetAddNumber(p,s);
							
							p.add(config.rsa->get_n());
							p.add(config.rsa->get_e());
//							std::string ts(token);
//							p.add(ts); 
							cl->sock->send(&p);
//							cl->messages_add(new client_message((char*)p.data(), p.size()));
							break;
						}
					}
					printf("Not correct message\n");
				}else if(_p->chanks[0].value.c==2){
//					size=fread(&c,sizeof(c),1,f);
	//				printf("%d\n",c);
					if (_p->chanks[1].type==6){
//						size=fread(&s,sizeof(s),1,f);//size
//						size=fread(buf,1,s,f);//hash
//						buf[s]=0;
						try{
							std::string pass("");
							auto &&str=_p->chanks[1].str;
							char *pbuf=new char[str.size()*2];
							memset(pbuf, 0, sizeof(char)*str.size()*2);
							s=share::base64::decode((unsigned char*)str.c_str(), (unsigned char*)pbuf, str.size());
							char *pout=new char[s+1];
							memset(pout, 0, sizeof(char)*(s+1));
							s=config.rsa->decrypt(s-1, pbuf, pout);
							pass+=pout;
//							printf("passwd len %d %s %s\n", s, pout, pass.data());
							delete[] pout;
							delete[] pbuf;
							if (pass==std::string(cl->passwd)){//add normal token check
								//auth ok
	//							fclose(f);
								packet p;
								p.setType(MSG_C_USER_INFO);
								p.add(cl->id);
								//packetAddString(p, cl->name);
								//add other params
								cl->sock->send(&p);
	//							cl->messages_add(new client_message(p.data(), p.size()));
								///set npc data and add npc to world
							
								npc *n=new npc(&master::world, master::world.getId());
								cl->npc_id=n->id;
								n->owner_id=cl->id;
								master::world.npcs_m.lock();
									master::world.new_npcs.push_back(n);
								master::world.npcs_m.unlock();
								printf("token OK\n");
								p.init();
								p.setType(MESSAGE_CLIENT_UPDATE);
								p.add((char)1);//index
								p.add(n->id);
								cl->sock->send(&p);
								break;
							}
						}catch(...){}
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
		master::world.m.lock();
			try{
				npc *n=master::world.npcs.at(cl->npc_id);
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
							n->set_attr(n->angle, p->chanks[i].value.c);
							break;
						case 3://attack
							n->attack(p->chanks[i].value.c);
	//						printf("%d attack\n", p->chanks[i].value.c);
						break;
					}
				}
				if (dir==2){
					n->m.lock();
						n->set_dir(x, y, 0); 
//						printf("set dir (%g %g)\n", n->direction.x,n->direction.y);
					n->m.unlock();
				}
			}catch(...){}
		master::world.m.unlock();
		return 0;
	}
	
	static void *message_MESSAGE_SET_ATTRS(client *cl, packet* p){
		clientCheckAuth(cl);//client must have id already
		master::world.m.lock();
			try{
				for(int i=0, end=p->chanks.size();i<end;i++){
					int index=p->chanks[i++].value.c;
					switch (index){
						case 1://width
							cl->view_area[0]=p->chanks[i].value.s;
//							printf("set width %d\n", cl->view_area[0]);
							break;
						case 2://height
							cl->view_area[1]=p->chanks[i].value.s;
//							printf("set height %d\n", cl->view_area[1]);
							break;
						case 3://width
							cl->view_position[0]=p->chanks[i].value.s;
//							printf("set pos x %d\n", cl->view_position[0]);
							break;
						case 4://height
							cl->view_position[1]=p->chanks[i].value.s;
//							printf("set pos y %d\n", cl->view_position[1]);
							break;
					}
				}
			}catch(...){}
		master::world.m.unlock();
		return 0;
	}

	static void *message_MESSAGE_GET_NPC_INFO(client *cl, packet* p){
		clientCheckAuth(cl);//client must have id already
		master::world.m.lock();
			for(int i=0, end=p->chanks.size();i<end;i++){
				try{
					npc *n=master::world.npcs.at(p->chanks[i++].value.i);
					withLock(n->m, cl->sock->send(n->pack(0,1)));
				}catch(...){}
			}
		master::world.m.unlock();
		return 0;
	}

	voidMessageProcessor(25)

	void clientMessageProcessorInit(){
		messageprocessorClientAdd(MESSAGE_AUTH, (void*)&message_MESSAGE_AUTH);
		messageprocessorClientAdd(MESSAGE_SET_DIRECTION, (void*)&message_MESSAGE_SET_DIRECTION);
		messageprocessorClientAdd(MESSAGE_SET_ATTRS, (void*)&message_MESSAGE_SET_ATTRS);
		messageprocessorClientAdd(MESSAGE_GET_NPC_INFO, (void*)&message_MESSAGE_GET_NPC_INFO);

		clientMessageProcessor(25);
	}
}