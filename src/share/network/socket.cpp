
#include "socket.h"
#include "bytes_order.h"
#include "../system/log.h"
extern "C"{
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/poll.h>
#include <string.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <unistd.h> 
#include <errno.h>
#include <netdb.h>
}



/*
╔══════════════════════════════════════════════════════════════╗
║ functions for work with sockets 			                       ║
║ created by Dennis Yarikov						                       ║
║ aug 2016									                       ║
╚══════════════════════════════════════════════════════════════╝
*/

namespace share {
	
	socket::socket(int sock):sockfd(sock){
	}

	socket::~socket(){
		::close(sockfd);
	}

	int socket::send(void* buf, int size){
		int need=size;
		int get;
		get=::send(sockfd,buf,need,MSG_NOSIGNAL);
//		printf("sended %d\n", get);
		if (get<=0)
			return get;
		if (get==need)
			return get;
//		printf("send not all\n");
		while(need>0){
			need-=get;
			if((get=::send(sockfd,(char*)buf+(size-need),need,MSG_NOSIGNAL))<=0)
				return get;
		}
		return size;
	}

	void socket::flush(){
		int flag=1;
		setsockopt(sockfd, IPPROTO_TCP, TCP_NODELAY, (char *) &flag, sizeof(int));
		flag=0; 
		setsockopt(sockfd, IPPROTO_TCP, TCP_NODELAY, (char *) &flag, sizeof(int));
	}
	
	int socket::send(packet* p){
		if (!p->client)
			size+=sizeof(p->dest.type)+sizeof(p->dest.id);
		size=byteSwap(size);
		int flag=1;
		int result=1;
		char* data=(char*)malloc(p->size()+sizeof(p->dest.type)+sizeof(p->dest.id)+sizeof(size));
		if (data==0){
			perror("malloc");
			//check result set to 0
		}else{
			int shift=0;
			memcpy(data, &size, sizeof(size));
			shift+=sizeof(size);
			memcpy(data+shift, p->data(), p->size());
			shift+=p->size();
			if (!p->client){
				memcpy(data+shift, (void*)&p->dest.type, sizeof(p->dest.type));
				shift+=sizeof(p->dest.type);
				memcpy(data+shift, (void*)&p->dest.id, sizeof(p->dest.id));
				shift+=sizeof(p->dest.id);
			}
			lockWrite();
				setsockopt(sockfd, IPPROTO_TCP, TCP_NODELAY, (char *) &flag, sizeof(int));//maybe try TCP_CORK
//					send((void*)&size, sizeof(size));
//					send(p->data(), p->size());
//					send((void*)&p->dest.type, sizeof(p->dest.type));
//					send((void*)&p->dest.id, sizeof(p->dest.id));
					result=send(data, shift);
/*					printf("send ");
					for(int i=0;i<shift;i++){
						printf("%d,", data[i]);
					} 
					printf("\n");
*/					
					flag=0; 
				setsockopt(sockfd, IPPROTO_TCP, TCP_NODELAY, (char *) &flag, sizeof(int));
			unlockWrite();
			free(data);
		}
		return result;
	}

	int socket::recv(void* buf, int size){
		int need=size;
		int got;
		got=::recv(sockfd,buf,need,0);
		if (got==0)
			return 0;
		if (got<0)
			if (errno!=EAGAIN)
				return -1;
		if (got==need)
			return got;
//		printf("got not all\n");
		do{
			if (got>0)
				need-=got;
	//		printf("try to get\n");
			if((got=::recv(sockfd,(char*)buf+(size-need),need,0))<=0)
				if (errno!=EAGAIN)
					return -1;
//			printf("got %d\n", got);
		}while(need>0);
		return size;
	}

	int socket::recv(char* v){
		return recv(v, sizeof(*v));
	}

	int socket::recv(short* v){
		int o=recv(v, sizeof(*v));
		*v=byteSwap(*v);
		return o;
	}

	int socket::recv(int* v){
		int o=recv(v, sizeof(*v));
		*v=byteSwap(*v);
		return o;
	}

	int socket::recv(float* v){
		int o=recv(v, sizeof(*v));
		*v=byteSwap(*v);
		return o;
	}

	int socket::recv(double* v){
		int o=recv(v, sizeof(*v));
		*v=byteSwap(*v);
		return o;
	}

	int socket::recv(packet* p){
		short size;
		if (recv(&size)<=0)
			return 0;
		printf("packet size %d\n", size);
		if (!p->client){
			size-=sizeof(char)+sizeof(int);
		}
		char* buf=(char*)malloc(size);
		if (!buf){
			return 0;
		}else{
			memset(buf, 0, size);
//			printf("try to recv\n");
			if (recv(buf, size)<=0)
				return 0;
/////			
//		printf("recv \n");
//			for(int i=0;i<size;i++){
//				printf("%d,\n", buf[i]);
//			} 
//			printf("\n");
/////
			p->init(buf,size);
			if (!p->client){//TODO:remove
				if (recv(&p->dest.type, sizeof(p->dest.type))<=0)
					return 0;
				if (recv(&p->dest.id, sizeof(p->dest.id))<=0)
					return 0;
			}
			free(buf);
		}
		return size;
	}

	void socket::lockRead(){
		mutex.read.lock();
	}

	void socket::unlockRead(){
		mutex.read.unlock();
	}

	void socket::lockWrite(){
		mutex.write.lock();
	}

	void socket::unlockWrite(){
		mutex.write.unlock();
	}

	void socket::close(){
		::close(sockfd);
	}

	socket* socket::connect(char* host, int port){
		int sockfd;
		struct sockaddr_in servaddr;
		struct hostent *server;
		server = gethostbyname(host);
		if (server == 0) {
			perror("gethostbyname");
			return 0;
		}
		
		if((sockfd=::socket(AF_INET,SOCK_STREAM,0))<0){
			perror("socket");
			return 0;
		}
		memset(&servaddr,0,sizeof(servaddr));
		servaddr.sin_family = AF_INET;
		memcpy((char *)&servaddr.sin_addr.s_addr,(char *)server->h_addr, server->h_length);
	//	servaddr.sin_addr.s_addr=inet_addr("172.16.1.40");//argv[1]);
		servaddr.sin_port=htons(port);

		if(::connect(sockfd, (struct sockaddr *)&servaddr, sizeof(servaddr))<0){
			perror("connect");
			::close(sockfd);
			return 0;
		}
		printf("done\n");
		return new socket(sockfd);
	}
	
	bool socket::recv_check(){//TODO: check why it doesn't work
		pollfd poll_set;
		poll_set.fd = sockfd;
		poll_set.events = POLLIN;
		poll_set.revents = 0;
		int res;
		if ((res=::poll(&poll_set, 1, 1))!=0){
			if (res<0){
				perror("poll");
			}
			return 1;
		}
		return 0;
		
/*		char $;
		if (withLock(mutex.read, ::recv(sockfd, &$, sizeof($), MSG_PEEK|MSG_DONTWAIT))<0){
			if (errno!=EAGAIN){
				return 1;
			}else{
				return 0;
			}
		}
		return 1;
*/
	}
	
}

/*
int main(){
	
	return 0;
}
*/