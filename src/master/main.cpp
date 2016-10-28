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

#define CONFIG_FILE "config.cfg"

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

#define startWorkers(type)\
	type##workers::create(config.type##workers.total,config.type##workers.tps)

int main(int argc,char* argv[]){
	int TPS=10;  //ticks per sec
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
	
	srand(time(0));
	
	memset(&config,0,sizeof(config));
	config.serverworkers.tps=1;
	config.socketworkers.tps=1;
	config.log.debug=1;
		
	readConfig();
	storageInit(&config.storage);
	log_config::config=config.log;
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
	timestamps.start=time(0);
	do{
		timestamp=time(0);
		tv.timePassed(); //start timer
		//////test
		
		//////
		if (timestamp-timestamps.servers_check>5){
			server::check();
			timestamps.servers_check=timestamp;
		}
		client::check();
		chatsCheck();
		tv.syncTPS(TPS);
//		if (timestamp-timestamps.start>25){//debug feature
//			main_loop=0;
//		}
	}while(main_loop);
	//clearing
	sleep(2);
	//deadlock here??
	socketworkers::stopAll();
//	printf("Ask to stop client workers\n");
	serverworkers::stopAll();
//	printf("Ask to stop server workers\n");
	listenworkers::stopAll();
//	printf("Ask to stop listen workers\n");
	sleep(1);
	listeners::clear();
	printf("Listeners cleared\n");
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
