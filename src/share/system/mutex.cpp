
#include "mutex.h"

/*
╔══════════════════════════════════════════════════════════════╗
║ functions for work with mutexes 			                       ║
║ created by Dennis Yarikov						                       ║
║ aug 2016									                       ║
╚══════════════════════════════════════════════════════════════╝
*/

namespace share {
	
	mutex::mutex(){
		pthread_mutex_init(&m, 0);
	}

	mutex::~mutex(){
		pthread_mutex_destroy(&m);
	}

	void mutex::lock(){
		pthread_mutex_lock(&m);
	}

	void mutex::unlock(){
		pthread_mutex_unlock(&m);
	}
	
}
