#include <cstdio>
extern "C"{
#include <pthread.h>
}
#include "processors.h"
#include "../share/messages.h"
#include "../share/system/mutex.h"
#include "../share/network/packet.h"
#include "world.h"

using namespace share;
using namespace slave;

#define world slave::world

static void* threadFunc(void *arg){
	packet p;
	
	world.sock->recv(&p);
	world.id=p.chanks[0].value.i;
	printf("server id %d\n", world.id);
	//get information about world
	
	p.init();
	
	p.setType(MESSAGE_SERVER_READY);
	p.add(world.id);
	world.sock->send(&p);//send ready
	
	withLock(world.m, world.main_loop=1);

	while(withLock(world.m, world.main_loop)){
		processor f;
		if (world.sock->recv(&p)<=0)
			break;
		printf("packet %d\n", p.type());
		//some work
		if((f=processors::messages[p.type()])!=0)
			f(&p);
		else
			printf("unknown message\n");
	}
	withLock(world.m, world.main_loop=0);
	return 0;
}

pthread_t startThread(){
	pthread_t pid;
	if(pthread_create(&pid,0,threadFunc,0)!=0)
		return 0;
	return pid;
}
