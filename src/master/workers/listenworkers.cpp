#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/socket.h>

#include "listenworkers.h"
#include "socketworkers.h"
#include "../../share/system/log.h"
#include "../client.h"
#include "../server.h"
#include "../../share/network/listener.h"

/*
╔══════════════════════════════════════════════════════════════╗
║ 	workers waiting for clients			                       ║
║ created by Dennis Yarikov						                       ║
║ jun 2016									                       ║
╚══════════════════════════════════════════════════════════════╝
*/



#define max(a,b) ((a)<(b)?(b):(a))

using namespace share;

namespace master {

	std::map<int, listenworkers*> listenworkers::all;
	int listenworkers::checks=10;

	void listenworkers::init(){
		//add some actions for every work element
		printf("%s created\n",name.data());
		memset(&set,0,sizeof(set));
		FD_ZERO(&set);
		maxfd=0;
	}

	void listenworkers::loop(){
		int sockfd=0;
		struct timeval t={0, 80000};
		//packetInit(&wd->packet);
		//printf("1\t%d\n", w->mutex->val);
		//add some actions for every iteration
		mutex.lock();
			if(select(maxfd+1, &set, 0, 0, &t)>0){
				for (auto l:works){
					if (FD_ISSET(l->listenerfd, &set)){
						if ((sockfd = ::accept(l->listenerfd, 0, 0))<0){
							perror("accept");
							l->broken=1;
						}else{
							break;
						}
					}
				}
			}
		mutex.unlock();
		if (sockfd){
			printf("%s: client connected\n", name.data());
			share::socket *s=new share::socket(sockfd);
			share::packet p(1); 
			do {
				short size;
				char c,buf[100];
				s->recv(buf, 3);
				buf[3]=0;
				//size=*((short*)buf);
				c=buf[2];
				if (c==0){//socket
					//mestype 0 this is hello mes, in other place it is blank mes
					printf("%s: try as pure socket\n", name.data());
					s->recv(&c);//elements
					if (c==1){
						s->recv(&c);//element type
						if (c==6){
							s->recv(&size);
							s->recv(buf, size);
							buf[size]=0;
							//check buf as client key
							//send answer
							c=1;
							p.setType(c);
							p.add(c);
							s->send(&p);//[1,1,1,1]
							printf("%s: got %s, client go to worker\n", name.data(), buf);
							socketworkers::addWorkAuto(new client(s));//after that client must get id
							break;
						}
					}
				}else if (strstr(buf,"<po")!=0 ){
					//Flash policy 
					s->send(PRIVATE_POLICY,sizeof(PRIVATE_POLICY));
					delete s;
					break;//already clear socket
				}else if (strstr(buf,"GET")!=0){//TODO: add web socket
					//Javaapplet policy
					s->send(PRIVATE_POLICY_HTTP_HEADER,sizeof(PRIVATE_POLICY_HTTP_HEADER)-1);
					s->send(PRIVATE_POLICY,sizeof(PRIVATE_POLICY)-1);
					delete s;
					break;//already clear socket
				}else if (strstr(buf,"POS")!=0){ //Http-Rest, used only post requests
						//TODO: add chose different worker
				}
				printf("%s: client failed\n", name.data());
				delete s;
			}while(0);
		}
		FD_ZERO(&set);
		maxfd=0;
	}

	void* listenworkers::proceed(listener *l){
		if (!l->broken){
			FD_SET(l->listenerfd, &set);
			maxfd = max(l->listenerfd, maxfd);
		}
		return 0;
	}

	void* listenworkers::close(){
		//worker* w=_w;
		return 0;
	}

	#define listenworkersActionAll(action)\
		void listenworkers::action ## All(){\
			for(auto w:all)\
				w.second->action();\
		}

	listenworkersActionAll(start)
	listenworkersActionAll(stop)
	listenworkersActionAll(pause)
	listenworkersActionAll(unpause)

	#define listenworkersAction(action)\
		void listenworkers::action(int n){\
			if (n<(int)all.size() && n>=0)\
				all[n]->action();\
		}

	listenworkersAction(start)
	listenworkersAction(stop)
	listenworkersAction(pause)
	listenworkersAction(unpause)

	void listenworkers::addWorkAll(listener* work){
		for(int i=0, end=all.size();i<end;i++)
			all[i]->add_work(work);
	}

	void listenworkers::addWork(int n, listener* work){
		if (n>0 && n<(int)all.size())
			all[n]->add_work(work);
	}

	int listenworkers::addWorkAuto(listener* work){
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

	int listenworkers::create(int num, int TPS){
		char s[100];
		for(int i=0;i<num;i++){
			sprintf(s,"Listener worker %d", i);
			std::string name=s;
			all[i]=new listenworkers(i, TPS, name);
		}
		return 0;
	}

}