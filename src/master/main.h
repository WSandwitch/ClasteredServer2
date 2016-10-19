#ifndef MAIN_HEADER
#define MAIN_HEADER

#include "../share/system/log.h"
#include "storage.h"

struct {
	log_config log;
	storage_config storage;
	short run;
	struct{
		short total;
		short tps;
	}	serverworkers, 
		socketworkers,
		listenworkers;
} config;

#endif