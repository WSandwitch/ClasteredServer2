#ifndef SOCKETWORKERS_HEADER
#define SOCKETWORKERS_HEADER

#include "../client.h"
#include "workerbase.h"
#include "../../share/network/socket.h"

using namespace share;

namespace master {

	class socketworkers;
	
	class socketworkers : public workerbase<client*, socketworkers>{
		using workerbase::start;
		using workerbase::stop;
		using workerbase::pause;
		using workerbase::unpause;
				
		public:		
			void* proceed(client* s); //must clear data before nonzero return
			void loop();
			void init();
			void* close();
		
			socketworkers(){};
			socketworkers(int id, int tps, std::string name):workerbase<client*, socketworkers>(id, tps, name){};
			static int create(int num, int TPS);
			static void addWork(int num, client* work);
			static int addWorkAuto(client* work);
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
		
			static std::map<int, socketworkers*> all;
	};
		
}


void socketworkersStartAll();
void socketworkersStopAll();
void socketworkersPauseAll();
void socketworkersUnpauseAll();

void socketworkersStart(int n);
void socketworkersStop(int n);
void socketworkersPause(int n);
void socketworkersUnpause(int n);

void socketworkersAddWork(int n, void* work);
int socketworkersAddWorkAuto(void* work); //add work to the most free worker

int socketworkersCreate(int num, int TPS);


#endif