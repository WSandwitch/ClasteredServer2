#include <cstdio>
extern "C"{
#include <pthread.h>
}
#include "processors/message.h"
#include "../share/system/mutex.h"
#include "../share/network/packet.h"
#include "world.h"

using namespace share;
using namespace clasteredServerSlave;

static void* threadFunc(void *arg){
	packet p;
	int bots=4;
	
	world::sock->recv(&p);
	world::id=p.chanks[0].value.i;
	world::grid->setId(world::id);
	world::grid->add(world::id, 0);
	printf("server id %d\n", world::id);
	//get information about world
	
	p.init();
	p.setType(6);//get new id
	for(int i =0;i<10;i++)
		world::sock->send(&p);//send ready
	p.setType(3);//get info about servers
	world::sock->send(&p);
	
	while(!withLock(world::m, world::main_loop)){
		processor f;
		if (world::sock->recv(&p)<=0)
			break;
//		printf("packet %d\n", p.type());
		//some work
		if((f=processors::messages[p.type()])!=0)
			f(&p);
		else
			printf("unknown message\n");
		if (p.type()==4)//got info about servers
			break;
	}
	
	p.init();
	p.setType(5);
	p.add(world::id);
	//dest already 0,0
	world::sock->send(&p);//send ready
	
	withLock(world::m, world::main_loop=1);

	while(withLock(world::m, world::main_loop)){
		processor f;
		if (world::sock->recv(&p)<=0)
			break;
		printf("packet %d\n", p.type());
		//some work
		if((f=processors::messages[p.type()])!=0)
			f(&p);
		else
			printf("unknown message\n");
		if (bots>0 && world::ids.size()>0){
			npc::addBot(world::map_size[0]/2,world::map_size[1]/2);
			bots--;
		}
	}
	world::main_loop=0;
	return 0;
}

pthread_t startThread(){
	pthread_t pid;
	if(pthread_create(&pid,0,threadFunc,0)!=0)
		return 0;
	return pid;
}
