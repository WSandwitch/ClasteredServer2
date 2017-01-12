#ifndef MAIN_HEADER
#define MAIN_HEADER

#include "../share/system/log.h"
#include "storage.h"
#include "crypto/rsa.h"

namespace master {
	struct config_t{
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
		master::rsa *rsa;
	};
	
	extern config_t config;
}
#endif