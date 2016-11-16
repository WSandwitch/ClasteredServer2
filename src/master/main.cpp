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
#include "../slave/main.h"

#define CONFIG_FILE "config.cfg"
#ifndef VIEW_AREA_X
	#define VIEW_AREA_X 200
#endif
#ifndef VIEW_AREA_Y
	#define VIEW_AREA_Y 200
#endif


namespace master{
	share::world world;
	master::special::grid *grid;
}

using namespace share;
using namespace master; 

static int main_loop;

static int readConfig(){
	FILE* f;
	if ((f=fopen(CONFIG_FILE,"rt"))==0){
		printf("cant open %s, using defaults\n",CONFIG_FILE);
		sprintf(config.storage.file, "%s", "storage.txt");//set default
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
			listener* l=new listener(port);
			if (l){
				listeners::add(l);
//				printf("Listener %d added\n",l->sockfd);
			}
		}else
		if (strcmp(buf, "slaves")==0){
			fscanf(f, "%hd", &config.slaves.total);
		}else
		if (strcmp(buf, "tps")==0){
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
			fscanf(f, "%s", config.storage.file);
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
	
	signal(SIGSEGV, segfault_sigaction);
	
	srand(share::time(0));
	
	memset(&config,0,sizeof(config));
	config.serverworkers.tps=1;
	config.socketworkers.tps=1;
	config.listenworkers.tps=3;
	config.tps=52;
	config.log.debug=1;
	config.slaves.total=0;
	config.slaves.start_port=0;
		
	readConfig();
	log_config::config=config.log;
	
#ifndef __CYGWIN__
	short port=config.slaves.start_port;
	std::string sname="localhost";
	for(int i=0;i<config.slaves.total;i++){
		start_slave_fork(port+i);
	}
	sleep(5);
	for(int i=0;i<config.slaves.total;i++){
		server *s=server::create(sname, port+i);
		if (s)
			server::add(s);
	}
#endif

	storageInit(&config.storage);
	grid=new master::special::grid(master::world.map.map_size, master::world.map.offset);
	
	clientMessageProcessorInit();
	serverMessageProcessorInit();
	
	startWorkers(listen);
	startWorkers(socket);
	startWorkers(server);
	
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
	do{
		timestamp=share::time(0);
		tv.timePassed(); //start timer
		//////
		master::world.m.lock();
			master::world.npcs_m.lock();
				for(auto n: master::world.new_npcs){
					master::world.npcs[n->id]=n;
				}
				master::world.new_npcs.clear();
			master::world.npcs_m.unlock();			
			for(auto ni: master::world.npcs){
				npc *n=ni.second;
				if(n){
					n->m.lock();
				}
			}
			for(auto ni: master::world.npcs){
				npc *n=ni.second;
				if(n){
					int slave_id=master::grid->get_owner(n->position.x, n->position.y);
					auto share_ids=master::grid->get_shares(n->position.x, n->position.y);
//					printf("%d %d\n", slave_id, n->slave_id);
					if (slave_id!=n->slave_id)
						slave_id=n->set_attr(n->slave_id, slave_id);
					//move in map
					n->update_cells();
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
									printf("(slave)send new npc\n");
									break;
								case 3: //already had npc
									if (n->updated()){
										if (slave_id!=n->slave_id){ //if attrs updated
											n->pack(1);
											s->sock->send(&n->packs(1));
										}else{ //send only needed attrs
											n->pack(1,0,1);
											s->sock->send(&n->packs(1,0,1));
										}
									}
									n->slaves.insert(slave.first);
									break;
							}
						}	
					}
				}
			}
			for(auto ci: client::all){
				client *c=ci.second;
				if (c){
					auto cells=master::world.map.cells(
						c->npc->position.x-VIEW_AREA_X/2, //l
						c->npc->position.x-VIEW_AREA_Y/2, //t
						c->npc->position.x+VIEW_AREA_X/2, //r
						c->npc->position.x+VIEW_AREA_Y/2 //b
					);
					std::unordered_map<int, short> npcs;
					for(auto n: c->npcs){
							npcs[n]=2;
					}
					c->npcs.clear();
					std::unordered_set<npc*> _npcs;
					for(auto i:cells){
						auto cell=master::world.map.cells(i);
						if (cell){
							for(auto ni: cell->npcs){
								npc* n=ni.second;
								if (n){
									_npcs.insert(n);
								}
							}
						}
					}
					for(auto n: _npcs){
						npcs[n->id]++;
					}
					npc *n;
					for(auto i: npcs){
						switch(i.second){
							case 2: //need to remove
								{
									packet p;
									p.setType(MESSAGE_NPC_REMOVE);
									p.add(i.first);
									c->sock->send(&p);
								}
								break;
							case 1: //new npc
								if ((n=master::world.npcs[i.first])!=0){
									n->pack(0,1); //all attrs
									c->sock->send(&n->packs(0,1));
									c->npcs.insert(i.first);
									printf("(client)send new npc\n");
								}
								break;
							case 3: //already had npc
								if ((n=master::world.npcs[i.first])!=0){
									if (n->updated()){
										n->pack(0); 
										c->sock->send(&n->packs(0));
									}
									c->npcs.insert(i.first);
								}
								break;
						}
					}
				}
			}		
			for(auto ni: master::world.npcs){
				npc *n=ni.second;
				if(n){
					n->clear();
					n->m.unlock();
				}
			}
			master::world.npcs_m.lock();
				if (master::world.old_npcs.size()>0){
					packet p;
					p.setType(MESSAGE_NPC_REMOVE);
					for(int id: master::world.old_npcs)
						p.add(id);
					for(auto s: server::all)
						s.second->sock->send(&p);
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
		tv.syncTPS(config.tps);
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
