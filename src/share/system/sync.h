#ifndef CLASTERED_SERVER_SYNC_HEADER
#define CLASTERED_SERVER_SYNC_HEADER

extern "C"{
#include <sys/time.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
}

#define getTimeMillis() ({share::sync $=share::sync();$.getTime()/1000;})

namespace share {
	class sync{
		public:
			sync();
			int timePassed();
			void syncTPS(int TPS, bool l=0);
			long long getTime();
		private:
			struct timeval t;
	};
}

#endif
