#ifndef CLASTERED_SERVER_SOCKET_HEADER
#define CLASTERED_SERVER_SOCKET_HEADER

#include "packet.h"
#include "../system/mutex.h"

extern "C"{
}

namespace share {

	class socket {
		private: 
			int sockfd;
			int nonblock;
			struct{
				mutex write;
				mutex read;
			} mutex;
		public:
			socket(int);
			~socket();
			void flush();
			int send(void*,int);
			int send(packet*);
			int recv(void*, int);
			int recv(char*);
			int recv(short*);
			int recv(int*);
			int recv(float*);
			int recv(double*);
			int recv(packet*);
			bool recv_check();
			void lockRead();
			void unlockRead();
			void lockWrite();
			void unlockWrite();
			void close();
			void blocking(bool v);
		
			static socket* connect(char*, int);
	};
}


#endif
