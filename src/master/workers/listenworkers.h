#ifndef LISTENWORKERS_HEADER
#define LISTENWORKERS_HEADER
#include <sys/time.h>
#include <map>

#include "workerbase.h"
#include "../../share/network/packet.h"
#include "../../share/network/listener.h"

using namespace share;

namespace master {

	class listenworkers : workerbase<listener*>{
		using workerbase::start;
		using workerbase::stop;
		using workerbase::pause;
		using workerbase::unpause;
				
		public:		
			void* proceed(listener* s); //must clear data before nonzero return
			void loop();
			void init();
			void* close();
		
			listenworkers(){};
			listenworkers(int id, int tps, std::string &name):workerbase<listener*>(id, tps, name){};
			static int create(int num, int TPS);
			static void addWork(int num, listener* work);
			static void addWorkAll(listener* work);
			static int addWorkAuto(listener* work);
			static void start(int n);
			static void stop(int n);
			static void pause(int n);
			static void unpause(int n);
			static void startAll();
			static void stopAll();
			static void pauseAll();
			static void unpauseAll();
		private:
			int maxfd;
			fd_set set;

			static int checks;
			
			static std::map<int, listenworkers> all;
	};


	void listenworkersStartAll();
	void listenworkersStopAll();
	void listenworkersPauseAll();
	void listenworkersUnpauseAll();

	void listenworkersStart(int n);
	void listenworkersStop(int n);
	void listenworkersPause(int n);
	void listenworkersUnpause(int n);

	//add work to current worker
	void listenworkersAddWork(int n, void* work);
	//add work to the less busy worker
	int listenworkersAddWorkAuto(void* work); 
	void listenworkersAddWorkAll(void* work); 

	//create num of workers, that works not more than TPS tiks per second, if 0 - without delay
	int listenworkersCreate(int num, int TPS);

	void listenworkersClose();
		
}

#endif