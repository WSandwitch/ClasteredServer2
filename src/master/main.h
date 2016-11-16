#ifndef MAIN_HEADER
#define MAIN_HEADER

#include "../share/system/log.h"
#include "storage.h"

namespace master {
	struct config{
		log_config log;
		storage_config storage;
		short run;
		short tps;
		struct{
			short total;
			short tps;
		}	serverworkers, 
			socketworkers,
			listenworkers;
		struct{
			short start_port;
			short total;
		}slaves;
	} config;
}
#endif