#include <cstdio>
#include <cstdlib>
#include <vector>
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
#include "world.h"
#include "../share/npc.h"

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

#ifdef MASTER
//start slave as thread of master
#define main slave_main
int slave_main(int argc, char* argv[]);

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
	return pid;
}

int start_slave_fork(int port){
	static char ps[30];
	sprintf(ps, "%d", port);
	static const char* argv[]={"", ps};	
	int pid=fork();
	if (pid==0){
		slave_func((void*)argv);
		exit(0);
	}
	return pid;
}

#endif

int main(int argc, char* argv[]){
	int TPS=24;
	share::sync syncer;
	struct sigaction sa;
	//pthread_t pid;
	int port=12345;
	
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
	
	srand(share::time(0));
	//init map
	{
		//initialize listener
		share::listener l(port);
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
			for(auto it = world.npcs.begin(), end = world.npcs.end();it != end; ++it){
				npc* n=it->second;
				if (n){
					n->m.lock();
				}
			}
			for(auto it = world.npcs.begin(), end = world.npcs.end();it != end; ++it){
				npc* n=it->second;
				if (n){
//					n->m.lock();
//					printf("%d %d, %d\n", world.id, n->slave_id, world.id==n->slave_id);
					if (world.id==n->slave_id){
						n->move();
					}
					n->update_cells();
//					n->m.unlock();
				}
			}
//		world.m.unlock();
		//attack
//		world.m.lock();
			for(auto it = world.npcs.begin(), end = world.npcs.end();it != end; ++it){
				npc* n=it->second;
				if (n){
//					n->m.lock();
					if (world.id==n->slave_id){
						n->attack();
					}
//					n->m.unlock();
				}
			}
//		world.m.unlock();
		//send data
//		world.m.lock();
			for(auto it = world.npcs.begin(), end = world.npcs.end();it != end; ++it){
				npc* n=it->second;
				if (n && n->updated()){
					n->pack(1,0);
					world.sock->send(&n->packs(1,0));
				}
			}
//		world.m.unlock();
		//clear flags
//		world.m.lock();
			for(auto it = world.npcs.begin(), end = world.npcs.end();it != end; ++it){
				npc* n=it->second;
				if (n){
					n->clear();
					n->m.unlock();
				}
			}
			world.npcs_m.lock();
				for(auto n: world.new_npcs){
					world.npcs[n->id]=n;
				}
				world.new_npcs.clear();
				world.old_npcs.clear();
			world.npcs_m.unlock();			
		world.m.unlock();
		syncer.syncTPS(TPS);
	}
	sleep(1);
	//cleanup
	//pthread_join(pid,0);
	sleep(1);
	return 1;
}
