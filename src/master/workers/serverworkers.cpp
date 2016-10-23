#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "serverworkers.h"
#include "../../share/system/log.h"
#include "../storage.h"
#include "../server.h"

/*
╔══════════════════════════════════════════════════════════════╗
║ 	workers works with slave servers 			                       ║
║ created by Dennis Yarikov						                       ║
║ jun 2016									                       ║
╚══════════════════════════════════════════════════════════════╝
*/

#define MAX_WORKERS 400

namespace master {
	
	int serverworkers::checks=10;
	std::map<int, serverworkers*> serverworkers::all;
	
	void serverworkers::init(){
		//add some actions for every work elemens
		printf("%s created\n",name.data());
	}

	void serverworkers::loop(){
		//add some actions for every iteration
	}

	void* serverworkers::proceed(server* s){
		int i;
		packet p;
		for(i=0;i<checks;i++){
			if (s->sock->recv_check()!=0){
				if (s->sock->recv(&p)>0){
					s->proceed(&p);//proceed packet
				}else{
					printf("Server %d connection lost\n", s->id);
					storageSlaveSetBroken((char*)s->host.data(), s->port);//??
					all.erase(s->id);
					return s;
				}
			}else
				break;
		}
		if (i>=checks) //when we done wd->checks iterations, we need to recheck without sleep
			recheck=1;
		return 0;
	}

	void* serverworkers::close(){
		//worker* w=_w;
		return 0;
	}

	#define serverworkersActionAll(action)\
		void serverworkers::action ## All(){\
			for(auto w:all)\
				w.second->action();\
		}

	serverworkersActionAll(start)
	serverworkersActionAll(stop)
	serverworkersActionAll(pause)
	serverworkersActionAll(unpause)

	#define serverworkersAction(action)\
		void serverworkers::action(int n){\
			if (n<(int)all.size() && n>=0)\
				all[n]->action();\
		}

	serverworkersAction(start)
	serverworkersAction(stop)
	serverworkersAction(pause)
	serverworkersAction(unpause)

	void serverworkers::addWork(int n, server* work){
		if (n>=0 && n<(int)all.size())
			all[n]->add_work(work);
	}

	int serverworkers::addWorkAuto(server* work){
		int n=0;
		unsigned $works=all[n]->works.size();
		for(int i=0, end=all.size();i<end;i++){
			if (all[i]->works.size()<$works){
				$works=all[i]->works.size();
				n=i;
			}
		}
		all[n]->add_work(work);
		return n;
	}

	int serverworkers::create(int num, int TPS){
		char str[100];
		for(int i=0;i<num;i++){
			sprintf(str,"Server worker %d", i);
			all[i]=new serverworkers(i, TPS, std::string(str));
		}
		return 0;
	}
}