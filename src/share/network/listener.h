#ifndef CLASTERED_SERVER_LISTENER_HEADER
#define CLASTERED_SERVER_LISTENER_HEADER

extern "C"{
#include <pthread.h>
}
#include "socket.h"

#define PRIVATE_POLICY_HTTP_HEADER (char*)"HTTP/1.1 200 OK\r\nContent-Type: text/xml; charset=utf-8\r\nContent-Length: 88\r\nConnection: close\r\n\r\n"
#define PRIVATE_POLICY (char*)"<cross-domain-policy><allow-access-from domain=\"*\" to-ports=\"*\" /></cross-domain-policy>"


namespace share {

	class listener {
		public:
			int listenerfd;
			bool broken;
		
			listener(int);
			~listener();
			socket* accept();
	};
}


#endif
