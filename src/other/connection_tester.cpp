#include <cstdio>
#include <cstdlib>
#include <list>

#include <string.h>

#include "../share/network/socket.h"
#include "../share/network/listener.h"

using namespace share;
int main(int argc, char* argv[]){
	listener *l=0;
	socket *s=0;
	int max=0;
	if (argc<3){
		printf("usage 'server port' or 'host port'\n");
		return 0;
	}
	short port=atoi(argv[2]);
	std::list<socket*> sockets;
	
	if (strcmp(argv[1], "server")==0){
		l=new listener(port);
		while((s=l.accept())!=0){
			int curr=sockets.size();
			if (curr>max)
				max=curr;
			printf("connections %d max %d\n", curr, max);
			sockets.push_back(s);
			for (auto i= sockets.begin(),end=sockets.end();i!=end;){
				auto sock=*i;
				if(sock->send(&port, 1)<=0){
					perror("send");
					i=sockets.erase(i);
				}else
					++i;
			}
		}
	}else{
		while((s=socket::connect(argv[1], port))!=0){
			printf("connections %d\n", (int)sockets.size());
			s->blocking(1);
			sockets.push_back(s);
			for (auto i= sockets.begin(),end=sockets.end();i!=end;){
				auto sock=*i;
				if(sock->recv(&port, 1)<=0){
					perror("send");
					i=sockets.erase(i);
				}else
					++i;
			}
		}
	}
	if (l)
		delete l;
	return 0;
}