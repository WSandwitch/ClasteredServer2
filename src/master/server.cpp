#include <string.h>

#include "messages/server.h"
#include "server.h"
#include "client.h"
#include "world.h"
#include "messageprocessor.h"
#include "workers/serverworkers.h"
#include "../share/network/packet.h"
#include "../share/system/log.h"
#include "../share/crypt/crc32.h"
#include "../share/messages.h"

/*
╔══════════════════════════════════════════════════════════════╗
║ 	implementation of slave servers 			                       ║
║ created by Dennis Yarikov						                       ║
║ jun 2016									                       ║
╚══════════════════════════════════════════════════════════════╝
*/

using namespace share;

namespace master { 
	
	typedef void*(*server_processor)(server*, packet*);

	std::map<int, server*> server::all;
	share::mutex server::m;

	
	server::server(socket* sock, std::string host, int port):
		checked(1), 	
		ready(0), 
		remote(1), 
		sock(sock), 
		host(host), 
		port(port)
	{
		id=idByAddress(host,port);
		printf("server %d created\n", id);
	}
	
	server* server::create(std::string host, int port){
		socket *sock;
		if ((sock=socket::connect((char*)host.data(), port))==0){
			perror("socketConnect");
			return 0;
		}
		storageSlaveSetUnbroken((char*)host.data(), port);//maybe need not here
		//TODO: add auth 
		return new server(sock, host, port);
	}

	server::~server(){
		delete sock;
	}

	int server::add(server* s){
		if (s->id!=0){
			m.lock();
				all[s->id]=s;
				packet p;
				p.setType((char)MESSAGE_SERVER_INFO);
				p.add(s->id);
				///send packet
				s->sock->send(&p);
//				bintreeForEach(&servers, serversSendPacket, p);
			m.unlock();
			serverworkers::addWorkAuto(s);			
		}
		return s->id;
	}

	server *server::get(int id){
		server *s=0;
	//	printf("get server %d\n", id);
		m.lock();
			auto i=all.find(id);
			if (i!=all.end())
				s=i->second;
		m.unlock();
		return s;
	}

	void server::remove(server* s){
		int id=s->id;
		packet p;
		m.lock();
			all.erase(id);
			delete s;
		m.unlock();
		printf("removed server %d\n", id);
		//add grid update
		master::grid->remove(s->id);
	}

	static int checkSlaves(slave_info *si, void *arg){
		int id=server::idByAddress(si->host, si->port);
		server *s=0;
		try{
			s=server::all.at(id);
		}catch(...){
			s=0;
		}
	//	printf("check server %d, got %d\n", id, s);
		if (s==0){
			std::string host(si->host);
			
			if ((s=server::create(host, si->port))!=0){
				server::add(s);
				//fist message to serer is server_connected 
			}
		}
		if (s){
			s->checked=1;
			//add message server created
		}
		return 0;
	}
	void server::check(){
		std::list<server*> l;
		m.lock();
			for (auto i:all){
				if (i.second->remote){
					i.second->checked=0;
				}
			}
		m.unlock();
		storageSlaves(checkSlaves, 0);
		m.lock();
			for (auto i:all){
				if (i.second->checked==0){
					l.push_back(i.second);
				}
			}
		m.unlock();
		for (auto s:l){
			s->sock->close();
		}
	}

	void server::proceed(packet *p){
		server_processor processor;
	//	printf("got server message %d\n", *((char*)buf));
		if ((processor=(server_processor)messageprocessorServer(p->type()))!=0){
			processor(this, p);
		}
	}

	int server::idByAddress(std::string address, int port){ //return 6 bytes integer
		std::string str=address;
		address+=':';
		address+=port;
		return crc32((const void*)str.data(), (size_t)str.size());
	}

	void server::sendAll(packet* p){
		m.lock();
			for (auto i:all){
				i.second->sock->send(p);
			}
		m.unlock();
	}

	void server::set_ready(){
		mutex.lock();
			ready=1;
		mutex.unlock();
	}
}
