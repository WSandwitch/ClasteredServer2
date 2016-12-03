#include <cstdio>
#include <cstdlib>
#include <list>

#include <string.h>

#include "../share/network/socket.h"
#include "../share/network/listener.h"

using namespace share;
int main(int argc, char* argv[]){
	
	if (argc<3){
		printf("usage 'server port' or 'host port'\n");
		return 0;
	}
	short port=atoi(argv[2]);
	std::list<socket*> sockets;
	
	if (strcmp(argv[1], "server")==0){
		listener l(port);
		socket *s;
		while((s=l.accept())!=0){
			printf("connections %d\n", (int)sockets.size());
			sockets.push_back(s);
			for (auto sock: sockets){
				if(sock->send(&port, 1)<=0){
					perror("send");
					return 1;
				}
			}
		}
	}else{
		socket *s;
		while((s=socket::connect(argv[1], port))!=0){
			printf("connections %d\n", (int)sockets.size());
			s->blocking(1);
			sockets.push_back(s);
			for (auto sock: sockets){
				char c;
				if(sock->recv(&c, 1)<=0){
					perror("recv");
					return 1;
				}
			}
		}
	}
	
	return 0;
}