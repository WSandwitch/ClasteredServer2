#include <cstdlib>

#include <string.h>

#include "client.h"
#include "server.h"
#include "../client.h"
#include "../server.h"
#include "../storage.h"
#include "../messageprocessor.h"
#include "../../share/network/packet.h"
#include "../../share/system/log.h"
#include "../../share/crypt/base64.h"
#include "../../share/crypt/md5.h"

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
	static void *message1(client*cl, packet* _p){
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
								long $2;
							} tokenbase={rand(), time(0)};//uniq token
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
							packet p(1);
							p.setType(MSG_C_AUTH_TOKEN);
		//					packetAddNumber(p,s);
							p.add((char*)token, s);
//							std::string ts(token);
//							p.add(ts); 
							cl->messages_add(new client_message((char*)p.data(), p.size()));
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
							packet p(1);
							p.setType(MSG_C_USER_INFO);
							p.add(cl->id);
							//packetAddString(p, cl->name);
							//add other params
							cl->messages_add(new client_message(p.data(), p.size()));
							printf("token OK\n");
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

	static void *message2(client*c, packet* p){
		clientCheckAuth(c);//client must have id already
		//some work
		return 0;
	}

	voidMessageProcessor(3)
	voidMessageProcessor(4)
	voidMessageProcessor(5)
	voidMessageProcessor(6)
	voidMessageProcessor(7)
	voidMessageProcessor(8)
	voidMessageProcessor(9)
	voidMessageProcessor(10)
	voidMessageProcessor(11)
	voidMessageProcessor(12)
	voidMessageProcessor(13)
	voidMessageProcessor(14)
	voidMessageProcessor(15)
	voidMessageProcessor(16)
	voidMessageProcessor(17)
	voidMessageProcessor(18)
	voidMessageProcessor(19)
	voidMessageProcessor(20)
	voidMessageProcessor(21)
	voidMessageProcessor(22)
	voidMessageProcessor(23)
	voidMessageProcessor(24)
	voidMessageProcessor(25)

	void clientMessageProcessorInit(){
		clientMessageProcessor(1);
		clientMessageProcessor(2);
		clientMessageProcessor(3);
		clientMessageProcessor(4);
		clientMessageProcessor(5);
		clientMessageProcessor(6);
		clientMessageProcessor(7);
		clientMessageProcessor(8);
		clientMessageProcessor(9);
		clientMessageProcessor(10);
		clientMessageProcessor(11);
		clientMessageProcessor(12);
		clientMessageProcessor(13);
		clientMessageProcessor(14);
		clientMessageProcessor(15);
		clientMessageProcessor(16);
		clientMessageProcessor(17);
		clientMessageProcessor(18);
		clientMessageProcessor(19);
		clientMessageProcessor(20);
		clientMessageProcessor(21);
		clientMessageProcessor(22);
		clientMessageProcessor(23);
		clientMessageProcessor(24);
		clientMessageProcessor(25);
	}
}