#ifndef WORKERBASE_HEADER
#define WORKERBASE_HEADER

#include <list>
#include <string>
#include <exception>

#include "../../share/system/mutex.h"
#include "../../share/system/time.h"
#include "../../share/system/sync.h"
#include "../../share/system/log.h"

/*
╔══════════════════════════════════════════════════════════════╗
║ thread work with players, get and proceed comands	     		                  ║
║ created by Dennis Yarikov						                   			    				    ║
║ sep 2014									           										            ║
║ updated from c at oct 2016		           										            ║
╚══════════════════════════════════════════════════════════════╝
*/

namespace master {
	void* workerbaseThread(void * arg);
	
	template <class T>
	class workerbase {
		public:
			//static vars
			int id;
			std::string name;
			int TPS;
			bool recheck;
			pthread_t pid;
			//dynamic vars
			timestamp_t timestamp;
			short run;
			short paused;
			//inner vars
			std::list<T> works;
			share::mutex mutex;
			//custom data struct
//			void* data;
			//functions
			workerbase(){}; 
			workerbase(int id, int tps, std::string &name): 
				id(id), 
				TPS(tps), 
				recheck(0),
				run(0){
				if(pthread_create(&pid, 0, workerbaseThread, this)!=0)
					throw std::exception();
			};
			virtual void* proceed(T data){return 0;}; //must clear data if needed before nonzero return
			virtual void loop(){};
			virtual void init(){};
			virtual void* close(){return 0;};
			void add_work(T obj){
				mutex.lock();
					works.push_back(obj);
				mutex.unlock();
			};
			void pause(){
				mutex.lock();
					paused=1;
				mutex.unlock();
			};
			void unpause(){
				mutex.lock();
					paused=0;
				mutex.unlock();
			};
			void start(){
				mutex.lock();
					run=1;
				mutex.unlock();
			};
			void stop(){
				mutex.lock();
					run=0;
				mutex.unlock();
			};
			
			static void * workerbaseThread(void * arg){
				workerbase *w=(workerbase*) arg;
				share::sync tv;
				short paused=0;
				void* out=0;
				
				w->init();
				///set thread name
				//pthread_setname_np(w->pid, w->name);
				w->mutex.lock();
					while(!w->run){
						w->mutex.unlock();
						usleep(10000);
						w->mutex.lock();
					}
				w->mutex.unlock();
				printLog("%s started\n",w->name.data());
				
				
				w->mutex.lock();
					while(w->run){
						tv.timePassed();
						w->mutex.unlock();
						w->mutex.lock();
							if (w->paused){
								printLog("%s paused\n",w->name.data());
								paused=1;
							}
						w->mutex.unlock();
						while(paused){
							w->mutex.lock();
								if (!w->paused){
									printLog("%s unpaused\n",w->name.data());
									paused=0;
									break;
								}
							w->mutex.unlock();
							usleep(10000);
							}
						w->mutex.unlock();
						
						w->timestamp=time(0);
						w->loop();
						w->mutex.lock();
							for (auto i=w->works.begin(), end=w->works.end();i!=end;){
								if (w->proceed(*i)){
									i=w->works.erase(i);
								}else{
									++i;
								}
							}
			//					worklistForEachRemove(&w->works,*w->proceed,w);
						w->mutex.unlock();
						if (!w->recheck){
							tv.syncTPS(w->TPS);
						}
						w->recheck=0;
						w->mutex.lock();
					}
				w->mutex.unlock();
				out=w->close();
				
				w->mutex.lock();
					w->works.clear();
				w->mutex.unlock();
				printf("%s closed\n", w->name.data());
			//	pthread_exit(out);
				return out;
			}
	};

}

#endif