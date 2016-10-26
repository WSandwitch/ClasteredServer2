
extern "C"{
#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <string.h>
#include <netinet/in.h>
#include <unistd.h>
#include <netdb.h>	
}

#include "listener.h"

/*
╔══════════════════════════════════════════════════════════════╗
║ functions for work with server sockets 			                       ║
║ created by Dennis Yarikov						                       ║
║ aug 2016									                       ║
╚══════════════════════════════════════════════════════════════╝
*/

namespace share {
	
	listener::listener(int port): broken(0){
		struct sockaddr_in addr;
//		printf("listener start on %d\n", port);
		if((listenerfd = ::socket(AF_INET, SOCK_STREAM, 0))<0){
			perror("socket");
		}
		
		addr.sin_family = AF_INET;
		addr.sin_port = htons(port);
		addr.sin_addr.s_addr = htonl(INADDR_ANY);
		if(::bind(listenerfd, (struct sockaddr *)&addr, sizeof(addr)) < 0){
			perror("bind");
			close(listenerfd);
			exit(1);
		}
		
		if(::listen(listenerfd, 1)<0){
			perror("listen");
			close(listenerfd);
		}
//		printf("listener on %d started\n", port);
	}
	
	listener::~listener(){
		close(listenerfd);
	}
	
	socket* listener::accept(){
		int sockfd;
		if ((sockfd = ::accept(listenerfd, 0, 0))<0){
			perror("accept");
		}else{
			return new socket(sockfd);
		}
		return 0;
	}
}
