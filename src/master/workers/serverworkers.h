#ifndef SERVERWORKERS_HEADER
#define SERVERWORKERS_HEADER

#include <map>
#include <string>

#include "workerbase.h"
#include "../server.h"
#include "../../share/network/packet.h"

using namespace share;

namespace master {

	class serverworkers : workerbase<server*>{
		public:		
			void* proceed(server* s); //must clear data before nonzero return
			void loop();
			void init();
			void* close();
		
			serverworkers(){};
			serverworkers(int id, int tps, std::string &name):workerbase<server*>(id, tps, name){};
			void start();
			void stop();
			void pause();
			void unpause();
				
			static int create(int num, int TPS);
			static void addWork(int num, server* work);
			static int addWorkAuto(server* work);
			static void start(int n);
			static void stop(int n);
			static void pause(int n);
			static void unpause(int n);
			static void startAll();
			static void stopAll();
			static void pauseAll();
			static void unpauseAll();
		private:
			static int checks;
		
			static std::map<int, serverworkers> all;
	};
}

#endif