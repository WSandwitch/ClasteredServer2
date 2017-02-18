#include <string> 
#include <map> 
#include <set> 
#include <unordered_map> 
#include <unordered_set> 

#include <stdio.h> 
#include <stdlib.h> 
#include <string.h>
#include <time.h>
#include <signal.h>
#include <unistd.h>

#ifndef __CYGWIN__
#include <execinfo.h>
#endif

#include "grid.h"
#include "main.h"
#include "chat.h"
#include "client.h"
#include "server.h"
#include "listeners.h"
#include "storage.h"
#include "messages/client.h"
#include "messages/server.h"
#include "messageprocessor.h"
#include "workers/socketworkers.h"
#include "workers/serverworkers.h"
#include "workers/listenworkers.h"
#include "../share/network/bytes_order.h"
#include "../share/network/listener.h"
#include "../share/network/packet.h"
#include "../share/system/sync.h"
#include "../share/system/log.h"
#include "../share/world.h"
#include "../share/messages.h"
#include "../share/object.h"
#include "../slave/main.h"

#define CONFIG_FILE "../config/config.cfg"
#define CONFIG_FOLDER "../config/"

namespace master{
	share::world world;
	master::special::grid *grid;
	config_t config;
	short view_area[2]={300,300};
}

namespace share{
	
}

using namespace share;
using namespace master; 

static int main_loop;
static std::vector<short> ports;

static int readConfig(){
	FILE* f;
	if ((f=fopen(CONFIG_FILE,"rt"))==0){
		printf("cant open %s, using defaults\n",CONFIG_FILE);
		sprintf(config.storage.file, "%s%s",CONFIG_FOLDER, "storage.txt");//set default
		config.log.debug=1;
		return 1;
	}
	char buf[700];
	while(feof(f)==0){
		fscanf(f, "%s", buf);
		if (buf[0]=='#'){
			size_t $str=400;
			char *str=(char*)malloc($str);
			if (str){
				getline(&str,&$str,f);
				free(str);
			}
		}else if (strcmp(buf, "port")==0){
			short port;
			fscanf(f, "%hd", &port);
			ports.push_back(port);
		}else
		if (strcmp(buf, "slaves")==0){
			fscanf(f, "%hd", &config.slaves.total);
		}else
		if (strcmp(buf, "slaves_port")==0){
			fscanf(f, "%hd", &config.slaves.start_port);
		}else
		if (strcmp(buf, "tps")==0){
			fscanf(f, "%hd", &config.tps);
		}else
		if (strcmp(buf, "sw_total")==0){
			fscanf(f, "%hd", &config.serverworkers.total);
		}else
		if (strcmp(buf, "sw_tps")==0){
			fscanf(f, "%hd", &config.serverworkers.tps);
		}else
		if (strcmp(buf, "cw_total")==0){
			fscanf(f, "%hd", &config.socketworkers.total);
		}else
		if (strcmp(buf, "cw_tps")==0){
			fscanf(f, "%hd", &config.socketworkers.tps);
		}else
		if (strcmp(buf, "lw_total")==0){
			fscanf(f, "%hd", &config.listenworkers.total);
		}else
		if (strcmp(buf, "storage_config")==0){
			char $[100];
			fscanf(f,"%s", $);
			sprintf(config.storage.file, "%s%s", CONFIG_FOLDER, $);
		}else
		if (strcmp(buf, "log_file")==0){
			fscanf(f, "%s", config.log.file);
		}else
		if (strcmp(buf, "log_debug")==0){
			fscanf(f, "%hd", &config.log.debug);
		}
	}
	fclose(f);
	return 0;
}

static void default_sigaction(int signal, siginfo_t *si, void *arg){
	printf("Stopping\n");
	main_loop=0;
}

static void segfault_sigaction(int sig){
	printf("Cought segfault, exiting\n");
#ifndef __CYGWIN__
	void *array[20];
	size_t size;

	// get void*'s for all entries on the stack
	size = backtrace(array, 20);

	// print out all the frames to stderr
	fprintf(stderr, "Error: signal %d:\n", sig);
	backtrace_symbols_fd(array, size, STDERR_FILENO);
#endif
	main_loop=0;
	exit(1);
}


//	FILE *f = fmemopen(&w, sizeof(w), "r+");
#define packAttr(p,n,a)\
	if (n->attrs[n->attr(&n->a)])\
		p.add(n->a);

#define startWorkers(type)\
	type##workers::create(config.type##workers.total,config.type##workers.tps)

int main(int argc,char* argv[]){
	object_initializer initializer(master::world);
	share::sync tv;
	struct sigaction sa;
	struct {
		timestamp_t start;
		timestamp_t servers_check;
	} timestamps={0};
	
	sigemptyset(&sa.sa_mask);
	sa.sa_sigaction = default_sigaction;
	sa.sa_flags   = SA_SIGINFO;
	//sigaction(SIGSEGV, &sa, NULL);	
	sigaction(SIGINT, &sa, NULL);	
	sigaction(SIGTERM, &sa, NULL);	
//#ifndef DEBUG	
	signal(SIGSEGV, segfault_sigaction);
//#endif		
	srand(share::time(0));
	
	memset(&config,0,sizeof(config));
	config.serverworkers.total=1;
	config.socketworkers.total=1;
	config.listenworkers.total=1;
	config.serverworkers.tps=10;
	config.socketworkers.tps=10;
	config.listenworkers.tps=10;
	config.tps=28;
	config.log.debug=1;
	config.slaves.total=0;
	config.slaves.start_port=12300;
		
	readConfig();
	log_config::config=config.log;
	master::world.tps=config.tps;

#ifdef _GLIBCXX_PARALLEL
	omp_set_dynamic(0);
	omp_set_num_threads((int)(omp_get_max_threads()*2.5f));
//	omp_set_schedule(omp_sched_dynamic, 4);
	printf("parallel mode %d\n", omp_get_max_threads());
#endif	

#ifndef __CYGWIN__
	if (config.slaves.total>0){
		short port=config.slaves.start_port;
		for(int i=0;i<config.slaves.total;i++){
			start_slave_fork(port+i);
		}
		sleep(3);
	}
#endif

	for(auto port: ports){
		listener* l=new listener(port);
		if (l){
			listeners::add(l);
//				printf("Listener %d added\n",l->sockfd);
		}
	}

	storageInit(&config.storage);
	grid=new master::special::grid(master::world.map.map_size, master::world.map.offset);
	
	clientMessageProcessorInit();
	serverMessageProcessorInit();
	
	startWorkers(listen);
	startWorkers(socket);
	startWorkers(server);

#ifndef __CYGWIN__
	if (config.slaves.total>0){
		short port=config.slaves.start_port;
		std::string sname("localhost");
		for(int i=0;i<config.slaves.total;i++){
			server *s=server::create(sname, port+i);
			if (s)
				server::add(s);
		}
	}
#endif
	printf("generating rsa key\n");
	config.rsa=new rsa();
	printf("rsa key created\n");
	
//	printf("%s\n",config.rsa->get_e().data());
//	printf("%s\n",config.rsa->get_n().data());
//	return 0;
	
	listenworkers::startAll();
	socketworkers::startAll();
	serverworkers::startAll();
	//test
//	listenersForEach(proceedListener);
	for (auto l:listeners::all){
		listenworkers::addWorkAll(l);
	}
//	listenworkersAddWorkAll(listenersAdd(listenerStart(8000)));
	//do some work
	main_loop=1;
//	printf("Start main loop\n");
	timestamp_t timestamp;
	timestamps.start=share::time(0);
	
	npc *n=new npc(&master::world, master::world.getId());
	n->health=5;
	n->_health=5;
	n->bot.used=1;
	n->move_id=100;
	master::world.new_npcs.push_back(n);
/*	
	for(int i=0;i<500;i++){
		npc *n=new npc(&master::world, master::world.getId());
		n->bot.used=1;
		master::world.new_npcs.push_back(n);
	}
*/	
	
	do{
		timestamp=share::time(0);
		tv.timePassed(); //start timer
		//////
		master::world.m.lock();
			master::world.npcs_m.lock();
				for(auto in=master::world.new_npcs.begin(), end=master::world.new_npcs.end();in!=end;){
					npc *n=*in;
					if (n->spawn_wait>0){
						n->spawn_wait--;
						++in;
//						printf("spawn wait %d 5d\n", n->id, n->spawn_wait);
					}else{
						master::world.npcs[n->id]=n;
						in=master::world.new_npcs.erase(in);
//						printf("spawned %d %d\n", n->id, n->health);
					}						
				}
			master::world.npcs_m.unlock();
			for(auto ni: master::world.npcs){
				npc *n=ni.second;
				if(n){
					n->m.lock();
				}
			}
#ifdef _GLIBCXX_PARALLEL
			int threads=omp_get_max_threads();
			int shift=client::all.size()/threads+client::all.size()%threads?1:0;
			#pragma omp parallel for
			for(int ii=0;ii<threads;ii++){
				auto it=master::world.npcs.begin();
				auto end=master::world.npcs.begin();
				int size=master::world.npcs.size();
				int is=min_of(ii*shift, size);
				int ie=min_of((ii+1)*shift, size);
				std::advance(it, is);
				std::advance(end, ie);
				for(;it!=end;it++){
					auto ni=*it;
#else
			{
				for(auto ni: master::world.npcs){
#endif				
					npc *n=ni.second;
//					printf("%d %d\n", n->id, n->health);
//					printf("%d %d\n", omp_get_thread_num(), n);
					int slave_id=master::grid->get_owner(n->position.x, n->position.y);
					auto share_ids=master::grid->get_shares(n->position.x, n->position.y);
//					printf("%d %d\n", slave_id, n->slave_id);
					if (slave_id!=n->slave_id){
//						printf("slave updated %d -> %d\n", slave_id, n->slave_id);
						slave_id=n->set_attr(n->slave_id, slave_id);
					}
					//move in map
					n->update_cells(); //threadsafe
					//update n->slaves
					std::unordered_map<int, short> slaves;
					for(auto slave: n->slaves)//set had to 2
						slaves[slave]=2;
					n->slaves.clear();
					for(auto slave: share_ids)
						slaves[slave]++; //inc real
					slaves[n->slave_id]++;
					for(auto slave: slaves){
						server *s=server::get(slave.first);
						if (s){
							switch(slave.second){
								case 2: //need to remove
									{
										packet p;
										p.setType(MESSAGE_NPC_REMOVE);
										p.add(n->id);
										s->sock->send(&p);
									}
									break;
								case 1: //new npc
									n->pack(1,1);
									s->sock->send(&n->packs(1,1));
									n->slaves.insert(slave.first);
//									printf("(slave)send new npc\n");
									break;
								case 3: //already had npc
									if (n->updated()){
										n->pack(1,0,1);
										s->sock->send(&n->packs(1,0,1));									
									}
									n->slaves.insert(slave.first);
									break;
							}
						}	
					}
				}	
			}
#ifdef _GLIBCXX_PARALLEL
			shift=client::all.size()/threads+client::all.size()%threads?1:0;
			#pragma omp parallel for
			for(int ii=0;ii<threads;ii++){
				auto it=client::all.begin();
				auto end=client::all.begin();
				int size=client::all.size();
				int is=min_of(ii*shift, size);
				int ie=min_of((ii+1)*shift, size);
				std::advance(it, is);
				std::advance(end, ie);
				for(;it!=end;it++){
					auto ci=*it;
#else
			{
				for(auto ci:client::all){
#endif
					client *c=ci.second;
					try{
						npc* cnpc=master::world.npcs.at(c->npc_id);
						auto cells=master::world.map.cells(
							cnpc->position.x-view_area[0]/2, //l
							cnpc->position.y-view_area[1]/2, //t
							cnpc->position.x+view_area[0]/2, //r
							cnpc->position.y+view_area[1]/2 //b
						);
						std::unordered_map<int, short> npcs;
						for(auto n: c->npcs){
								npcs[n]=2;
						}
//						c->npcs.clear();
						std::unordered_set<npc*> _npcs;
						for(auto i:cells){
							auto cell=master::world.map.cells(i);
							if (cell){
								for(auto ni: cell->npcs){
									_npcs.insert(ni.second);
								}
							}
						}
						for(auto n: _npcs){
							npcs[n->id]++;
						}
						for(auto i: npcs){
							switch(i.second){
								case 2: { //need to remove
//									printf("need to remove %d \n", i.first);
									packet p;
									p.setType(MESSAGE_NPC_REMOVE);
									p.add(i.first);
									c->sock->send(&p);
									withLock(c->mutex, c->npcs.erase(i.first));
									break;
								}
								case 1: {//new npc
									try{
										npc *n=master::world.npcs.at(i.first);
										n->pack(0,1); //all attrs
										c->sock->send(&n->packs(0,1));
										withLock(c->mutex, c->npcs.insert(i.first));
	//									printf("(client)send new npc\n");
									}catch(...){}
									break;
								}
								case 3: {//already had npc
									try{
										npc *n=master::world.npcs.at(i.first);
										if (n->updated()){
											n->pack(0); 
											c->sock->send(&n->packs(0));
										}
										//withLock(c->mutex, c->npcs.insert(i.first));
									}catch(...){}
									break;
								}
							}
						}
					}catch(...){}
				}
			}
			std::list<npc*> l;
			for(auto ni: master::world.npcs){
				npc *n=ni.second;
				if(n->clear())
					l.push_back(n);
				n->m.unlock();
			}
			for(auto n: l){
				master::world.npcs.erase(n->id);
				delete n; //auto added to old_npcs
			}
			master::world.npcs_m.lock();
				if (master::world.old_npcs.size()>0){
					packet p;
					p.setType(MESSAGE_NPC_REMOVE);
					for(int id: master::world.old_npcs)
						p.add(id);
#ifdef _GLIBCXX_PARALLEL
					shift=server::all.size()/threads+server::all.size()%threads?1:0;
					#pragma omp parallel for
					for(int ii=0;ii<threads;ii++){
						auto it=server::all.begin();
						auto end=server::all.begin();
						int size=server::all.size();
						int is=min_of(ii*shift, size);
						int ie=min_of((ii+1)*shift, size);
						std::advance(it, is);
						std::advance(end, ie);
						for(;it!=end;it++){
							auto s=*it;
#else
					{
						for(auto s: server::all){
#endif
							s.second->sock->send(&p);
						}
					}
					master::world.old_npcs.clear();
				}
			master::world.npcs_m.unlock();
		master::world.m.unlock();
		/////
		/////
		if (timestamp-timestamps.servers_check>5){
			server::check();
			timestamps.servers_check=timestamp;
		}
		client::check();
		chatsCheck();
//		if (timestamp-timestamps.start>25){//debug feature
//			main_loop=0;
//		}
		tv.syncTPS(master::world.tps);
	}while(main_loop);
	//clearing
	sleep(2);
	//deadlock here??
	socketworkers::stopAll();
//	printf("Ask to stop client workers\n");
	serverworkers::stopAll();
//	printf("Ask to stop listen workers\n");
	sleep(1);
	listeners::clear();
	printf("Listeners cleared\n");
//	printf("Ask to stop server workers\n");
	listenworkers::stopAll();
	
	delete config.rsa;
	chatsClear();
	printf("Chats cleared\n");
	for (auto i:server::all)
		delete i.second;
	printf("Servers cleared\n");
	for (auto i:client::all)
		delete i.second;
	printf("Clients cleared\n");
	storageClear();
	printf("Storage cleared\n");
	delete master::grid;
	printf("Exiting\n");
	sleep(1);
	return 0;
}
