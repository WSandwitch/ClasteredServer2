#include <cstdio>
#include <cstdlib>
#include <vector>
#include <iostream>
extern "C"{
#include <time.h>
#include <signal.h>
#include <unistd.h>
#include <pthread.h>

#ifndef __CYGWIN__
#include <execinfo.h>
#endif
}
#include "processors.h"
#include "../share/network/socket.h"
#include "../share/network/listener.h"
#include "../share/system/sync.h"
#include "../share/network/bytes_order.h"
#include "../share/system/folder.h"
#include "world.h"
#include "../share/npc.h"
#include "../share/object.h"

using namespace slave;
using namespace share;

share::world slave::world;

#define world slave::world

pthread_t startThread();//in thread.cpp

static void default_sigaction(int signal, siginfo_t *si, void *arg){
	printf("Stopping\n");
	world.main_loop=0;
}

#ifndef __CYGWIN__
static void segfault_sigaction(int sig){
	printf("Cought segfault, exiting\n");
	void *array[20];
	size_t size;
	
	// get void*'s for all entries on the stack
	size = backtrace(array, 20);

	// print out all the frames to stderr
	fprintf(stderr, "Error: signal %d:\n", sig);
	backtrace_symbols_fd(array, size, STDERR_FILENO);
	world.main_loop=(world.main_loop+1)&1;
	exit(1);
}
#endif

int slave_main(int argc, char* argv[]){
	srand(share::time(0));
	world.tps=24;
	share::sync syncer;
	struct sigaction sa;
	//pthread_t pid;
	int port=12345;
	if (wrongByteOrder()){
		printf("bytes order Error, exiting\n");
		return 1;
	}
#ifdef _GLIBCXX_PARALLEL
	omp_set_dynamic(0);
	omp_set_num_threads(1);
//	omp_set_schedule(omp_sched_dynamic, 4);
	printf("parallel mode %d\n", 1);
#endif		
	sigemptyset(&sa.sa_mask);
	sa.sa_sigaction = default_sigaction;
	sa.sa_flags   = SA_SIGINFO;
	//sigaction(SIGSEGV, &sa, NULL);	
	sigaction(SIGINT, &sa, NULL);	
	sigaction(SIGTERM, &sa, NULL);		
#ifndef __CYGWIN__
	signal(SIGSEGV, segfault_sigaction);
#endif	
	if (argc>1)
		sscanf(argv[1], "%d", &port);
#ifndef DEBUG
	//add log init
#endif

	object::all[0]=new object();
	object::all[1]=new object();//TODO: remove

	world.maps[0]=new map("../maps/map.tmx");
	folder::forEachFile((char*)"../maps/*.tmx", [](char *s){ 
		auto m=new map(s); 
		world.maps[m->id]=m;
	});

	
	//init map
	{
		//initialize listener
		share::listener l(port);
		printf("Waiting for connection on %d\n", port);
		world.sock=l.accept();
		world.sock->blocking(1);
		//pid=
		startThread();
	}
	//wait for ready 
	while(!withLock(world.m, world.main_loop)){
		usleep(10000);
	}
	while(withLock(world.m, world.main_loop)){
		syncer.timePassed();
		//now move
		world.m.lock();
		while(world.pause){
			world.m.unlock();
				usleep(100);
			world.m.lock();
		}
		world.m.unlock();
		
		world.m.lock();
		//lock all
			for(auto it = world.npcs.begin(), end = world.npcs.end();it != end; ++it){
				npc* n=it->second;
				n->m.lock();
			}
		//move
			for(auto it = world.npcs.begin(), end = world.npcs.end();it != end; ++it){
				npc* n=it->second;
//				printf("%d %d, %g %g\n", world.id, n->slave_id, n->position.x, n->position.y);
				if (world.id==n->slave_id){
					n->move();
				}
				n->update_cells();
			}
		//attack
			for(auto it = world.npcs.begin(), end = world.npcs.end();it != end; ++it){
				npc* n=it->second;
				if (world.id==n->slave_id){
					n->attack();
				}
			}
		//send data
			for(auto it = world.npcs.begin(), end = world.npcs.end();it != end; ++it){
				npc* n=it->second;
//				if (n->updated(1,0))
//					printf("npc %d (%g %g)\n", n->id, n->position.x, n->position.y);
				if (world.id==n->slave_id && n->updated(1,0)){
					world.sock->send(n->pack(1,0));
				}
			}
		//clear flags
			for(auto it = world.npcs.begin(), end = world.npcs.end();it != end; ++it){
				npc* n=it->second;
				n->clear();
				n->m.unlock();
			}
		//add new
			world.npcs_m.lock();
				for(auto n: world.new_npcs){
					world.npcs[n->id]=n;
				}
				world.new_npcs.clear();
				world.old_npcs.clear();
			world.npcs_m.unlock();			
		world.m.unlock();
		syncer.syncTPS(world.tps);
	}
	sleep(1);
	//cleanup
	world.sock->close();
	//pthread_join(pid,0);
	printf("Slave exiting\n");
	sleep(1);
	return 1;
}


void* slave_func(void* a){
	slave_main(2, (char**)a);
	return 0;
}

int start_slave(int port){
	static char ps[30];
	sprintf(ps, "%d", port);
	static const char* argv[]={"", ps};	
	pthread_t pid=0;
	if(pthread_create(&pid, 0, slave_func, (void*)argv)!=0)
		exit(1);
	return (int)pid;
}

int start_slave_fork(int port){
#ifndef __CYGWIN__
	static char ps[30];
	sprintf(ps, "%d", port);
	static const char* argv[]={"", ps};	
	int pid=fork();
	if (pid==0){
		slave_func((void*)argv);
		exit(0);
	}
	return pid;
#else
	printf("Could not create forked slave on CYGWIN\n");
	return 0;
#endif
}