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
#include "processors/message.h"
#include "../share/network/socket.h"
#include "../share/network/listener.h"
#include "../share/system/sync.h"
#include "../share/network/bytes_order.h"
#include "world.h"
#include "npc.h"

using namespace clasteredServerSlave;

pthread_t startThread();//in thread.cpp

static void default_sigaction(int signal, siginfo_t *si, void *arg){
	printf("Stopping\n");
	world::main_loop=0;
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
	world::main_loop=(world::main_loop+1)&1;
	world::clear();
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

void start_slave(int port){
	static char ps[30];
	sprintf(ps, "%d", port);
	static const char* argv[]={"", ps};	
	pthread_t pid;
	if(pthread_create(&pid, 0, slave_func, (void*)argv)!=0)
		exit(1);
}

void start_slave_fork(int port){
	static char ps[30];
	sprintf(ps, "%d", port);
	static const char* argv[]={"", ps};	
	if (fork()==0){
		slave_func((void*)argv);
	}
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
	
	processors::init();
	srand(time(0));
	//init map
	world::init();
	{
		//initialize listener
		share::listener l(port);
		world::sock=l.accept();
		//pid=
		startThread();
	}
	//wait for ready 
	while(!withLock(world::m, world::main_loop)){
		usleep(10000);
	}
	while(withLock(world::m, world::main_loop)){
		syncer.timePassed();
		//now move
		world::m.lock();
			for(std::map<int, npc*>::iterator it = world::npcs.begin(), end = world::npcs.end();it != end; ++it){
				npc* n=it->second;
//				printf("n %d\n",n);
				if (n){
					n->m.lock();
//						printf("%d|%d on (%g,%g) from %d\n", n->id, world::id, n->position.x, n->position.y, n->gridOwner());
						if (world::id==n->gridOwner()){
							n->move();
						}
					n->m.unlock();
				}
			}
//		world::m.unlock();
		//attack
//		world::m.lock();
			for(std::map<int, npc*>::iterator it = world::npcs.begin(), end = world::npcs.end();it != end; ++it){
				npc* n=it->second;
//				printf("n %d\n",n);
				if (n){
					n->m.lock();
//						printf("%d|%d on (%g,%g) from %d\n", n->id, world::id, n->position.x, n->position.y, n->gridOwner());
						if (world::id==n->gridOwner()){
							n->attack();
						}
					n->m.unlock();
				}
			}
//		world::m.unlock();
		//send data to players
//		world::m.lock();
			for(std::map<int, player*>::iterator it = world::players.begin(), end = world::players.end();it != end; ++it){
				player *p=it->second;
				if (p && withLock(p->m, p->connected)){
					p->sendUpdates();
				}
			}		
//		world::m.unlock();
		//check areas
//		world::m.lock();
			for(std::map<int, npc*>::iterator it = world::npcs.begin(), end = world::npcs.end();it != end; ++it){
				npc *n=it->second;
				if (n){
					int oid=n->gridOwner();
/*					printf("%d on (%g %g) %d :",n->id, n->position.x, n->position.y,oid);
					std::vector<int> shares=world::grid->getShares(n->position.x, n->position.y);
					for(unsigned i=0;i<shares.size();i++){
						printf("%d ", shares[i]);
					}
					printf(":\n");
*/	//				printf("%d on %d==%d\n", n->id, world::id, oid);
					if (world::id==oid){
						//i am owner
						n->m.lock();
							if (n->updated()){
								std::vector<int>& shares=n->gridShares();
								n->pack(0,1);
								for(unsigned i=0, end=shares.size();i<end;i++){
									n->p.dest.id=shares[i];
									world::sock->send(&n->p);
								}
							}
						n->m.unlock();
					}else{
						//i am not owner		
						player *p;
	//					printf("i'm not owner\n");
						if (n->owner_id==0 || (p=world::players[n->owner_id])!=0){
							n->m.lock();
								n->pack(1,1);
								n->p.dest.id=oid;
								world::sock->send(&n->p);
							n->m.unlock();
						}
						if (p && withLock(p->m, p->connected)){
							p->move();
						}
					}
				}
			}	
//		world::m.unlock();
		//clear flags
//		world::m.lock();
			for(std::map<int, npc*>::iterator it = world::npcs.begin(), end = world::npcs.end();it != end; ++it){
				npc* n=it->second;
				if (n){
					if (withLock(n->m, n->clear())){
						world::npcs[n->id]=0;
						world::ids.push(n->id);//return id
						delete n;
					}
				}
			}
			world::new_npcs_m.lock();
				for(auto n: world::new_npcs){
					world::npcs[n->id]=n;
				}
				world::new_npcs.clear();
			world::new_npcs_m.unlock();			
		world::m.unlock();
		syncer.syncTPS(TPS);
	}
	sleep(1);
	//cleanup
	//pthread_join(pid,0);
	world::clear();
	sleep(1);
	return 1;
}
