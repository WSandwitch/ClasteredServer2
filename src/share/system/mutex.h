#ifndef CLASTERED_SERVER_MUTEX_HEADER
#define CLASTERED_SERVER_MUTEX_HEADER

extern "C"{
#include <pthread.h>
}

namespace share {

	class mutex {
		private: 
			pthread_mutex_t m;
		public:
			mutex();
			mutex(const share::mutex &_);
			~mutex();
			void lock();
			void unlock();
	};
}

#define withLock(m,s) ({\
		typeof(s) o;\
		m.lock();\
		o=s;\
		m.unlock();\
		o;\
	})


#endif
